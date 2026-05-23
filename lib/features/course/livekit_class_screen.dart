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
  RealtimeChannel? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _room = Room();
    _connectToLiveKit();
    _setupSupabaseChat();
  }

  Future<void> _connectToLiveKit() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final username = user?.userMetadata?['full_name'] ?? user?.email ?? 'Student';
      
      // Since emulator maps 10.0.2.2 to localhost, we use it to hit the Next.js API
      // If deployed, this should point to the production API (e.g. https://nlitedu.com/api/livekit)
      final tokenUrl = Uri.parse('http://10.0.2.2:3000/api/livekit?room=${widget.session.id}&username=$username');
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
      } else {
        print('Failed to fetch token: ${response.body}');
      }
    } catch (e) {
      print('Error connecting to LiveKit: $e');
    }
  }

  void _setupSupabaseChat() async {
    final channelName = widget.session.id; // Using session ID as channel name
    
    // Fetch existing messages
    final data = await Supabase.instance.client
        .from('live_chat_messages')
        .select('*')
        .eq('channel_name', channelName)
        .order('created_at', ascending: true);
        
    if (mounted) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data);
      });
      _scrollToBottom();
    }

    _chatSubscription = Supabase.instance.client
        .channel('public:live_chat_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'live_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_name',
            value: channelName,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                _messages.add(payload.newRecord);
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;
    
    final text = _chatController.text.trim();
    _chatController.clear();
    
    final user = Supabase.instance.client.auth.currentUser;
    final senderName = user?.userMetadata?['full_name'] ?? user?.email ?? 'Student';
    
    await Supabase.instance.client.from('live_chat_messages').insert({
      'channel_name': widget.session.id,
      'sender_name': senderName,
      'message': text,
    });
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
    _chatSubscription?.unsubscribe();
    _listener?.dispose();
    _room.disconnect();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Find instructor's video track
    VideoTrack? instructorVideoTrack;
    for (var participant in _room.remoteParticipants.values) {
      for (var publication in participant.videoTrackPublications) {
        if (publication.track != null) {
          instructorVideoTrack = publication.track as VideoTrack;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
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
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isConnected ? 'LIVE' : 'CONNECTING...',
                              style: const TextStyle(
                                color: Colors.red,
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
            ),
            
            // Video Area
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isConnected
                    ? (instructorVideoTrack != null 
                        ? VideoTrackRenderer(instructorVideoTrack) 
                        : const Center(
                            child: Text(
                              'Waiting for instructor to start video...',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ))
                    : const Center(child: CircularProgressIndicator(color: Colors.blue)),
              ),
            ),
            
            // Chat Area
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
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
                          final isInstructor = msg['sender_name'] == 'Instructor (Admin)';
                          
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
                                hintText: 'Chat publicly as Student...',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
