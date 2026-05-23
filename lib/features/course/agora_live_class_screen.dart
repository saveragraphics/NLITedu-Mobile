import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_protector/screen_protector.dart';

import '../../models/live_session.dart';
import '../../providers/live_provider.dart';
import '../../providers/learning_service.dart';

const String appId = "b9a89d915dbf42f18e467c5481d37d8c";

class AgoraLiveClassScreen extends ConsumerStatefulWidget {
  final LiveSession session;

  const AgoraLiveClassScreen({super.key, required this.session});

  @override
  ConsumerState<AgoraLiveClassScreen> createState() => _AgoraLiveClassScreenState();
}

class _AgoraLiveClassScreenState extends ConsumerState<AgoraLiveClassScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = true;
  bool _isVideoMuted = false;
  String? _attendanceLogId;

  late final String channelName;

  @override
  void initState() {
    super.initState();
    
    // Extract channel name from agora:// URL
    final url = widget.session.sessionUrl;
    if (url.startsWith('agora://')) {
      channelName = url.replaceFirst('agora://', '');
    } else {
      channelName = widget.session.id; // Fallback
    }

    _startAttendanceLogging();
    _enableSecureMode();
    initAgora();
  }

  Future<void> _enableSecureMode() async {
    await ScreenProtector.preventScreenshotOn();
  }

  Future<void> _disableSecureMode() async {
    await ScreenProtector.preventScreenshotOff();
  }

  Future<void> _startAttendanceLogging() async {
    ref.read(liveServiceProvider).logAttendance(widget.session);
    try {
      final logId = await ref.read(learningServiceProvider).startSessionSession(widget.session.id);
      setState(() => _attendanceLogId = logId);
    } catch (e) {
      debugPrint("Error starting duration log: $e");
    }
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user \${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('[onTokenPrivilegeWillExpire] connection: \${connection.toJson()}, token: $token');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    // Since we're using "Testing Mode", the token is optional/null
    await _engine.joinChannel(
      token: '',
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    
    if (_attendanceLogId != null) {
      ref.read(learningServiceProvider).endSessionSession(_attendanceLogId!);
    }
    _disableSecureMode();
    super.dispose();
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(
            uid: _remoteUid,
            renderMode: RenderModeType.renderModeFit,
          ),
          connection: RtcConnection(channelId: channelName),
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Waiting for Instructor...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
      );
    }
  }

  Widget _localVideo() {
    if (_localUserJoined && !_isVideoMuted) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return Container(color: Colors.black54);
    }
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _onToggleVideo() {
    setState(() {
      _isVideoMuted = !_isVideoMuted;
    });
    _engine.muteLocalVideoStream(_isVideoMuted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  void _onCallEnd() {
    Navigator.pop(context);
  }

  void _openChat() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ChatSheet(channelName: channelName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video (Instructor)
            Center(
              child: _remoteVideo(),
            ),
            
            // Header
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _onCallEnd,
                    icon: const Icon(LucideIcons.chevronDown, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "LIVE: \${widget.session.courseTitle}",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Attendance logged",
                          style: GoogleFonts.inter(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.radio, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          "LIVE",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Local Video (Student)
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30, width: 2),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _localVideo(),
                ),
              ),
            ),

            // Toolbar
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToolButton(
                    icon: _isMuted ? LucideIcons.micOff : LucideIcons.mic,
                    color: _isMuted ? Colors.white30 : Colors.white,
                    onPressed: _onToggleMute,
                  ),
                  const SizedBox(width: 16),
                  _buildToolButton(
                    icon: _isVideoMuted ? LucideIcons.videoOff : LucideIcons.video,
                    color: _isVideoMuted ? Colors.white30 : Colors.white,
                    onPressed: _onToggleVideo,
                  ),
                  const SizedBox(width: 16),
                  _buildToolButton(
                    icon: LucideIcons.switchCamera,
                    color: Colors.white,
                    onPressed: _onSwitchCamera,
                  ),
                  const SizedBox(width: 16),
                  _buildToolButton(
                    icon: LucideIcons.messageCircle,
                    color: Colors.white,
                    onPressed: _openChat,
                  ),
                  const SizedBox(width: 16),
                  _buildToolButton(
                    icon: LucideIcons.phoneOff,
                    color: Colors.redAccent,
                    onPressed: _onCallEnd,
                    isEndCall: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isEndCall = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEndCall ? Colors.redAccent : Colors.white.withOpacity(0.2),
        ),
        child: Icon(
          icon,
          color: isEndCall ? Colors.white : color,
          size: 22,
        ),
      ),
    );
  }
}

class _ChatSheet extends StatefulWidget {
  final String channelName;
  const _ChatSheet({required this.channelName});

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final text = _messageController.text.trim();
    _messageController.clear();
    
    // ignore: undefined_identifier
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? 'Student';
    
    try {
      await supabase.from('live_chat_messages').insert({
        'channel_name': widget.channelName,
        'sender_name': name,
        'message': text,
      });
    } catch (e) {
      debugPrint("Failed to send message: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: undefined_identifier
    final supabase = Supabase.instance.client;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(LucideIcons.messageCircle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Live Chat",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          
          // Messages Stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('live_chat_messages')
                  .stream(primaryKey: ['id'])
                  .eq('channel_name', widget.channelName)
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white30));
                }
                
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading chat", style: TextStyle(color: Colors.white54)));
                }
                
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return const Center(child: Text("No messages yet. Say hi!", style: TextStyle(color: Colors.white54)));
                }

                // Auto-scroll to bottom using post-frame callback
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_name'] == (supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Student');
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF6C63FF).withOpacity(0.2) : Colors.white10,
                          border: Border.all(color: isMe ? const Color(0xFF6C63FF).withOpacity(0.5) : Colors.transparent),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                            bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                msg['sender_name'] ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              msg['message'] ?? '',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

