import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/live_session.dart';
import '../../providers/live_provider.dart';
import '../../providers/learning_service.dart';

class LiveClassScreen extends ConsumerStatefulWidget {
  final LiveSession session;

  const LiveClassScreen({super.key, required this.session});

  @override
  ConsumerState<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends ConsumerState<LiveClassScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _attendanceLogId;

  @override
  void initState() {
    super.initState();
    
    // 1. Log Attendance & Start Duration Timer (Option A)
    _startAttendanceLogging();

    // 2. Initialize WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.session.sessionUrl));
  }

  Future<void> _startAttendanceLogging() async {
    // Basic attendance log (existing)
    ref.read(liveServiceProvider).logAttendance(widget.session);
    
    // Advanced duration log for "Weekly Goal" (Option A)
    try {
      final logId = await ref.read(learningServiceProvider).startSessionSession(widget.session.id);
      setState(() => _attendanceLogId = logId);
    } catch (e) {
      debugPrint("Error starting duration log: $e");
    }
  }

  @override
  void dispose() {
    // 3. End Duration Timer & Calculate Weekly Goal Hours on exit
    if (_attendanceLogId != null) {
      ref.read(learningServiceProvider).endSessionSession(_attendanceLogId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LIVE: ${widget.session.courseTitle}", 
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
            Text("Attendance logged • Progress tracking active", 
              style: GoogleFonts.inter(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
