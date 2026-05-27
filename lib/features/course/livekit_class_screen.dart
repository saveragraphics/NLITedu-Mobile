import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../models/live_session.dart';
import '../../providers/live_provider.dart';
import '../../core/utils/supabase_utils.dart';

class LivekitClassScreen extends StatefulWidget {
  final LiveSession session;

  const LivekitClassScreen({super.key, required this.session});

  @override
  State<LivekitClassScreen> createState() => _LivekitClassScreenState();
}

class _LivekitClassScreenState extends State<LivekitClassScreen> {
  late final Room _room;
  EventsListener<RoomEvent>? _listener;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isSessionLive = false;
  bool _classHasStartedOnce = false;
  String? _connectionError;
  StreamSubscription<List<Map<String, dynamic>>>? _sessionSubscription;
  bool _isSessionEndedHandled = false;

  // Chat state
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isChatVisible = true;

  // Draggable PiP state
  Offset _pipOffset = const Offset(16, 16); // bottom-right relative offset

  // UI overlay visibility (auto-hide controls like YouTube)
  bool _showOverlay = true;

  // Interaction states
  bool _isHandRaised = false;
  Map<String, dynamic>? _activePoll;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _room = Room();
    _isSessionLive = widget.session.isLive;
    if (_isSessionLive) {
      _classHasStartedOnce = true;
    }
    _setupSecurity();
    _subscribeToSessionStatus();
    if (_isSessionLive) {
      _connectToLiveKit();
    }
  }

  void _subscribeToSessionStatus() {
    _sessionSubscription = retryStreamWithAuth<List<Map<String, dynamic>>>(() => Supabase.instance.client
        .from('live_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', widget.session.id))
        .listen((data) {
          if (data.isEmpty) {
            if (_classHasStartedOnce) {
              _handleSessionEnded();
            }
          } else {
            final session = LiveSession.fromJson(data.first);
            final wasLive = _isSessionLive;
            if (mounted) {
              setState(() {
                _isSessionLive = session.isLive;
              });
            }
            
            if (session.isLive) {
              _classHasStartedOnce = true;
              if (!_isConnected && !_isConnecting) {
                _connectToLiveKit();
              }
            } else {
              if (_classHasStartedOnce) {
                _handleSessionEnded();
              }
            }
          }
        }, onError: (err) {
          print('Error in session subscription stream: $err');
        });
  }

  void _handleSessionEnded() {
    if (!mounted || _isSessionEndedHandled) return;
    _isSessionEndedHandled = true;

    _room.disconnect();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.info, color: Colors.blueAccent, size: 22),
            SizedBox(width: 10),
            Text('Class Ended', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'The live session has been ended by the instructor.',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Dismiss dialog
              if (mounted) {
                Navigator.of(context).pop(); // Go back to course dashboard
              }
            },
            child: const Text('OK', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Security: prevent screenshots & screen recording ────────────
  Future<void> _setupSecurity() async {
    await ScreenProtector.preventScreenshotOn();
  }

  Future<void> _cleanupSecurity() async {
    await ScreenProtector.preventScreenshotOff();
  }

  // ─── Exit confirmation dialog ────────────────────────────────────
  Future<bool> _confirmExit() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.logOut, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text('Leave Live Class?', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'You are currently in a live class. Are you sure you want to leave?',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.15)),
            child: const Text('Leave', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  String get _roomName {
    return widget.session.sessionUrl.replaceAll('livekit://', '').replaceAll('agora://', '');
  }

  Future<void> _connectToLiveKit() async {
    if (_isConnected || _isConnecting) return;
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final username = user?.userMetadata?['full_name'] ?? user?.email ?? 'Student';

      final tokenUrl = Uri.parse('https://www.nlitedu.com/api/livekit?room=$_roomName&username=$username');
      final response = await http.get(tokenUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        _listener = _room.createListener();

        await _room.connect(
          'wss://nlit-edu-816y4hlq.livekit.cloud',
          token,
          roomOptions: const RoomOptions(
            adaptiveStream: true,
            dynacast: true,
          ),
        );

        setState(() {
          _isConnected = true;
        });

        // Record student attendance upon successful connection
        try {
          await LiveService().logAttendance(widget.session);
        } catch (e) {
          print('Error logging attendance: $e');
        }

        _listener!.on<RoomEvent>((event) {
          if (mounted) setState(() {});
        });
        _listener!.on<DataReceivedEvent>((event) {
          try {
            final payload = utf8.decode(event.data);
            final msgData = jsonDecode(payload);

            if (event.topic == 'lk-chat-topic') {
              if (mounted) {
                setState(() {
                  _messages.add({
                    'sender_name': event.participant?.identity ?? 'Instructor',
                    'message': msgData['message'] ?? '',
                  });
                });
                _scrollToBottom();
              }
            } else {
              // Custom interactive payloads (topic is null or empty)
              if (msgData['action'] == 'START_POLL') {
                if (mounted) setState(() { _activePoll = msgData['poll']; });
              } else if (msgData['action'] == 'END_POLL') {
                if (mounted) setState(() { _activePoll = null; });
              } else if (msgData['action'] == 'MUTE_MIC') {
                if (msgData['target'] == _room.localParticipant?.identity) {
                  _room.localParticipant?.setMicrophoneEnabled(false);
                }
              } else if (msgData['action'] == 'LOWER_HAND') {
                if (mounted) setState(() { _isHandRaised = false; });
              }
            }
          } catch (e) {
            print('Error decoding data channel message: $e');
          }
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _connectionError = 'This live session is not currently active. Please wait for the instructor.';
        });
      } else {
        setState(() {
          _connectionError = 'Failed to fetch token: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionError = 'Failed to connect to LiveKit: $e';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final text = _chatController.text.trim();
    _chatController.clear();

    final user = Supabase.instance.client.auth.currentUser;
    final senderName = user?.userMetadata?['full_name'] ?? user?.email ?? 'Student';

    setState(() {
      _messages.add({
        'sender_name': senderName,
        'message': text,
      });
    });
    _scrollToBottom();

    try {
      final payload = jsonEncode({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'message': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      await _room.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
        topic: 'lk-chat-topic',
      );
    } catch (e) {
      print('Error sending LiveKit data: $e');
    }
  }

  Future<void> _toggleHandRaise() async {
    setState(() {
      _isHandRaised = !_isHandRaised;
    });
    
    if (_isConnected && _room.localParticipant != null) {
      final action = _isHandRaised ? 'RAISE_HAND' : 'LOWER_HAND';
      final payload = utf8.encode(jsonEncode({'action': action}));
      await _room.localParticipant?.publishData(payload, reliable: true);
    }
  }

  Future<void> _submitPollVote(int optionIndex) async {
    if (_isConnected && _room.localParticipant != null) {
      final payload = utf8.encode(jsonEncode({'action': 'POLL_VOTE', 'optionId': optionIndex.toString()}));
      await _room.localParticipant?.publishData(payload, reliable: true);
      setState(() {
        _activePoll = null; // Hide poll after voting
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _cleanupSecurity();
    _sessionSubscription?.cancel();
    _listener?.dispose();
    _room.disconnect();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Draggable PiP (instructor camera) ───────────────────────────
  Widget _buildDraggablePiP(VideoTrack cameraTrack, Size screenSize, bool isLandscape) {
    final pipW = isLandscape ? 130.0 : 110.0;
    final pipH = isLandscape ? 170.0 : 150.0;

    return Positioned(
      left: _pipOffset.dx,
      top: _pipOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newDx = _pipOffset.dx + details.delta.dx;
            double newDy = _pipOffset.dy + details.delta.dy;
            // Clamp so PiP stays within bounds
            newDx = newDx.clamp(0, screenSize.width - pipW);
            newDy = newDy.clamp(0, screenSize.height - pipH);
            _pipOffset = Offset(newDx, newDy);
          });
        },
        child: Container(
          width: pipW,
          height: pipH,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: VideoTrackRenderer(cameraTrack),
        ),
      ),
    );
  }

  // ─── Poll Overlay ────────────────────────────────────────────────
  Widget _buildPollOverlay() {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.barChart2, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activePoll!['question'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate((_activePoll!['options'] as List).length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _submitPollVote(index),
                  child: Text(_activePoll!['options'][index]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Floating header overlay (gradient fade) ─────────────────────
  Widget _buildFloatingHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showOverlay ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronDown, color: Colors.white, size: 22),
                  onPressed: () async {
                    if (await _confirmExit()) {
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.session.courseTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Floating bottom toolbar ─────────────────────────────────────
  Widget _buildFloatingToolbar(bool isLandscape) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showOverlay ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Chat toggle
                _toolbarButton(
                  icon: _isChatVisible ? LucideIcons.messageSquare : LucideIcons.messageSquareDashed,
                  label: _isChatVisible ? 'Hide Chat' : 'Show Chat',
                  isActive: _isChatVisible,
                  onTap: () {
                    setState(() {
                      _isChatVisible = !_isChatVisible;
                    });
                  },
                ),
                const SizedBox(width: 24),
                // Hand Raise toggle
                _toolbarButton(
                  icon: LucideIcons.hand,
                  label: _isHandRaised ? 'Lower Hand' : 'Raise Hand',
                  isActive: _isHandRaised,
                  onTap: _toggleHandRaise,
                ),
                const SizedBox(width: 24),
                // Participant count
                _toolbarButton(
                  icon: LucideIcons.users,
                  label: '${_room.remoteParticipants.length + 1}',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue.withOpacity(0.25) : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isActive ? Colors.blue : Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  // ─── Chat panel (slides in/out) ──────────────────────────────────
  Widget _buildChatPanel() {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.messageCircle, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Live Chat',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                // Close chat button
                GestureDetector(
                  onTap: () => setState(() => _isChatVisible = false),
                  child: const Icon(LucideIcons.x, color: Colors.white38, size: 18),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isInstructor = msg['sender_name'] == 'Instructor' ||
                    msg['sender_name'].toString().toLowerCase().contains('instructor');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: isInstructor ? Colors.blue.withOpacity(0.2) : Colors.white12,
                        child: Text(
                          msg['sender_name'].toString().substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isInstructor ? Colors.blue : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    msg['sender_name'],
                                    style: TextStyle(
                                      color: isInstructor ? Colors.blue : Colors.white54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isInstructor) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'HOST',
                                      style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              msg['message'],
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.send, color: Colors.blue, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Find instructor's video and screen share tracks
    VideoTrack? cameraTrack;
    VideoTrack? screenShareTrack;
    bool isInstructorPresent = _room.remoteParticipants.isNotEmpty;

    for (var participant in _room.remoteParticipants.values) {
      for (var publication in participant.videoTrackPublications) {
        if (publication.track != null) {
          if (publication.source == TrackSource.screenShareVideo) {
            screenShareTrack = publication.track as VideoTrack;
          } else if (publication.source == TrackSource.camera) {
            cameraTrack = publication.track as VideoTrack;
          } else {
            cameraTrack ??= publication.track as VideoTrack;
          }
        }
      }
    }

    // The core video widget — no borders, no margins, pure black, full-bleed
    Widget videoContent;
    if (!_isSessionLive) {
      videoContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.clock,
                color: Colors.blueAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Waiting for Instructor...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The broadcast has not started yet.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else if (_connectionError != null) {
      videoContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertTriangle,
              color: Colors.redAccent,
              size: 40,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _connectionError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connectToLiveKit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (!_isConnected) {
      videoContent = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Connecting to server...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    } else if (cameraTrack == null && screenShareTrack == null) {
      videoContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isInstructorPresent ? LucideIcons.mic : LucideIcons.videoOff,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isInstructorPresent
                  ? 'Instructor\'s camera is off.\nListening to audio...'
                  : 'Waiting for instructor to go live...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    } else {
      final activeTrack = screenShareTrack ?? cameraTrack!;
      videoContent = VideoTrackRenderer(
        activeTrack,
        key: ValueKey(activeTrack.sid),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _confirmExit();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          final screenSize = MediaQuery.of(context).size;

          // Initialize PiP position on first build (bottom-right corner)
          if (_pipOffset == const Offset(16, 16)) {
            _pipOffset = Offset(screenSize.width - 126, screenSize.height - 200);
          }

          if (isLandscape) {
            // ── LANDSCAPE ──────────────────────────────────────────
            return Row(
              children: [
                // Video section (expands to fill when chat is hidden)
                Expanded(
                  flex: (_isChatVisible && _isConnected) ? 7 : 10,
                  child: GestureDetector(
                    onTap: () => setState(() => _showOverlay = !_showOverlay),
                    child: Stack(
                      children: [
                        // Full-bleed video — NO containers, NO borders, NO margins
                        Positioned.fill(child: videoContent),

                        // Draggable PiP
                        if (screenShareTrack != null && cameraTrack != null && _isConnected)
                          _buildDraggablePiP(cameraTrack, screenSize, true),

                        // Header overlay
                        _buildFloatingHeader(),
                        
                        // Poll Overlay
                        if (_activePoll != null && _isConnected) _buildPollOverlay(),

                        // Bottom toolbar (only when chat hidden to show toggle)
                        if (!_isChatVisible && _isConnected) _buildFloatingToolbar(true),
                      ],
                    ),
                  ),
                ),

                // Chat panel (animated slide)
                if (_isChatVisible && _isConnected)
                  Expanded(
                    flex: 3,
                    child: _buildChatPanel(),
                  ),
              ],
            );
          } else {
            // ── PORTRAIT ───────────────────────────────────────────
            return Column(
              children: [
                // Video section (expands fully when chat is hidden)
                Expanded(
                  flex: (_isChatVisible && _isConnected) ? 5 : 10,
                  child: GestureDetector(
                    onTap: () => setState(() => _showOverlay = !_showOverlay),
                    child: Stack(
                      children: [
                        // Full-bleed video — clean, no boxing
                        Positioned.fill(
                          child: Container(
                            color: Colors.black,
                            child: videoContent,
                          ),
                        ),

                        // Draggable PiP
                        if (screenShareTrack != null && cameraTrack != null && _isConnected)
                          _buildDraggablePiP(cameraTrack, screenSize, false),

                        // Floating header
                        _buildFloatingHeader(),
                        
                        // Poll Overlay
                        if (_activePoll != null && _isConnected) _buildPollOverlay(),

                        // Bottom toolbar
                        if (_isConnected) _buildFloatingToolbar(false),
                      ],
                    ),
                  ),
                ),

                // Chat panel
                if (_isChatVisible && _isConnected)
                  Expanded(
                    flex: 5,
                    child: _buildChatPanel(),
                  ),
              ],
            );
          }
        },
      ),
    ),
    );
  }
}
