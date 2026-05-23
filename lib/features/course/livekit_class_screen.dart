import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/live_session.dart';

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
  
  // Chat state
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _room = Room();
    _connectToLiveKit();
  }

  String get _roomName {
    return widget.session.sessionUrl.replaceAll('livekit://', '').replaceAll('agora://', '');
  }

  Future<void> _connectToLiveKit() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final username = user?.userMetadata?['full_name'] ?? user?.email ?? 'Student';
      
      // Since emulator maps 10.0.2.2 to localhost, we use it to hit the Next.js API
      // If deployed, this should point to the production API (e.g. https://nlitedu.com/api/livekit)
      final tokenUrl = Uri.parse('https://www.nlitedu.com/api/livekit?room=$_roomName&username=$username');
      final response = await http.get(tokenUrl);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        _listener = _room.createListener();
        
        // Connect to LiveKit Cloud Server
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
        
        _listener!.on<RoomEvent>((event) {
          if (mounted) setState(() {});
        });
        _listener!.on<DataReceivedEvent>((event) {
          if (event.topic == 'lk-chat-topic') {
            try {
              final payload = utf8.decode(event.data);
              final msgData = jsonDecode(payload);
              
              if (mounted) {
                setState(() {
                  _messages.add({
                    'sender_name': event.participant?.identity ?? 'Instructor',
                    'message': msgData['message'] ?? '',
                  });
                });
                _scrollToBottom();
              }
            } catch (e) {
              print('Error decoding chat message: $e');
            }
          }
        });
      } else {
        print('Failed to fetch token: ${response.body}');
      }
    } catch (e) {
      print('Error connecting to LiveKit: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;
    
    final text = _chatController.text.trim();
    _chatController.clear();
    
    final user = Supabase.instance.client.auth.currentUser;
    final senderName = user?.userMetadata?['full_name'] ?? user?.email ?? 'Student';
    
    // Add locally immediately
    setState(() {
      _messages.add({
        'sender_name': senderName,
        'message': text,
      });
    });
    _scrollToBottom();
    
    // Send to LiveKit room
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
    _listener?.dispose();
    _room.disconnect();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronDown, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.courseTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isConnected ? Colors.red : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isConnected ? 'LIVE' : 'CONNECTING...',
                      style: TextStyle(
                        color: _isConnected ? Colors.red : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea(VideoTrack? cameraTrack, VideoTrack? screenShareTrack, bool isInstructorPresent, bool isLandscape) {
    return Container(
      margin: isLandscape ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.black, // true black for video background
        borderRadius: isLandscape ? BorderRadius.zero : BorderRadius.circular(16),
        border: isLandscape ? null : Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: !_isConnected
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text('Connecting to server...', style: TextStyle(color: Colors.white54)),
                ]
              ),
            )
          : (cameraTrack == null && screenShareTrack == null)
              ? Center(
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
                )
              : Stack(
                  children: [
                    // Main Video (Screen Share has priority, otherwise Camera)
                    Positioned.fill(
                      child: VideoTrackRenderer(
                        screenShareTrack ?? cameraTrack!,
                      ),
                    ),
                    // PiP Camera (if Screen Share is main and Camera is also on)
                    if (screenShareTrack != null && cameraTrack != null)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        width: isLandscape ? 120 : 100,
                        height: isLandscape ? 160 : 140,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: VideoTrackRenderer(cameraTrack!),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildChatArea(bool isLandscape) {
    return Container(
      margin: isLandscape ? const EdgeInsets.only(left: 1) : const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[950],
        borderRadius: isLandscape ? BorderRadius.zero : BorderRadius.circular(16),
        border: isLandscape ? const Border(left: BorderSide(color: Colors.white12)) : Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(LucideIcons.messageCircle, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  'Live Chat',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isInstructor = msg['sender_name'] == 'Instructor' || msg['sender_name'].toString().toLowerCase().contains('instructor');
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isInstructor ? Colors.blue.withOpacity(0.2) : Colors.white12,
                        child: Text(
                          msg['sender_name'].toString().substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isInstructor ? Colors.blue : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  msg['sender_name'],
                                  style: TextStyle(
                                    color: isInstructor ? Colors.blue : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isInstructor) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'HOST',
                                      style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['message'],
                              style: const TextStyle(color: Colors.white, fontSize: 14),
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
          const Divider(height: 1, color: Colors.white12),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            // Fallback for unknown sources
            cameraTrack ??= publication.track as VideoTrack;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              // LANDSCAPE LAYOUT (Zoom style: Video full left, Chat right)
              return Row(
                children: [
                  Expanded(
                    flex: 7, // 70% width for video
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _buildVideoArea(cameraTrack, screenShareTrack, isInstructorPresent, true),
                        ),
                        // Overlay header on top of the video to save space
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.chevronDown, color: Colors.white),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.session.courseTitle,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 12),
                                if (_isConnected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3, // 30% width for chat
                    child: _buildChatArea(true),
                  ),
                ],
              );
            } else {
              // PORTRAIT LAYOUT
              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    flex: 4,
                    child: _buildVideoArea(cameraTrack, screenShareTrack, isInstructorPresent, false),
                  ),
                  Expanded(
                    flex: 5,
                    child: _buildChatArea(false),
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
