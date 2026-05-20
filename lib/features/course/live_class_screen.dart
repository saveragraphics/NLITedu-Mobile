import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isExternal = false;
  String? _attendanceLogId;

  @override
  void initState() {
    super.initState();
    
    // 1. Log Attendance & Start Duration Timer
    _startAttendanceLogging();

    // 2. Initialize WebView with permissions
    _initWebView();

    // 3. Prevent Screenshots and Screen Recording
    _enableSecureMode();
  }

  Future<void> _enableSecureMode() async {
    await ScreenProtector.preventScreenshotOn();
  }

  Future<void> _disableSecureMode() async {
    await ScreenProtector.preventScreenshotOff();
  }

  Future<void> _initWebView() async {
    final url = widget.session.sessionUrl;

    // Check if the URL should be launched externally (Google Meet, Zoom, etc.)
    if (_shouldLaunchExternally(url)) {
      setState(() {
        _isExternal = true;
        _isLoading = false;
      });
      // Initialize controller to prevent LateInitializationError
      _controller = WebViewController();
      _launchExternalUrl(url);
      return;
    }

    // Request Camera, Microphone, and Location permissions for WebRTC/Geolocation
    await [Permission.camera, Permission.microphone, Permission.location].request();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (WebViewPermissionRequest request) {
        // Automatically grant web page permission request (camera, microphone)
        request.grant();
      },
    );

    _controller
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
          onNavigationRequest: (NavigationRequest request) {
            final requestUrl = request.url;
            if (_shouldLaunchExternally(requestUrl)) {
              _launchExternalUrl(requestUrl);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // If on Android, configure geolocation permissions prompt callback
    if (_controller.platform is AndroidWebViewController) {
      await (_controller.platform as AndroidWebViewController)
          .setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return const GeolocationPermissionsResponse(
            allow: true,
            retain: true,
          );
        },
      );
    }

    _controller.loadRequest(Uri.parse(url));
  }

  bool _shouldLaunchExternally(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Check for custom schemes (anything other than http and https)
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme.isNotEmpty && uri.scheme != 'http' && uri.scheme != 'https') {
      return true;
    }

    // Check for known non-WebView-renderable platforms/stores/chats
    if (lowerUrl.contains('play.google.com/store') ||
        lowerUrl.contains('chat.whatsapp.com') ||
        lowerUrl.contains('wa.me') ||
        lowerUrl.contains('t.me')) {
      return true;
    }
    
    return false;
  }

  String? _convertIntentToHttps(String url) {
    if (!url.startsWith('intent://')) return null;
    
    try {
      final cleanUrl = url.replaceFirst('intent://', 'https://');
      final hashIndex = cleanUrl.indexOf('#');
      if (hashIndex != -1) {
        return cleanUrl.substring(0, hashIndex);
      }
      return cleanUrl;
    } catch (e) {
      debugPrint("Error converting intent URL: $e");
      return null;
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      String targetUrl = url;
      if (url.startsWith('intent://')) {
        final converted = _convertIntentToHttps(url);
        if (converted != null) {
          targetUrl = converted;
        }
      }
      
      final uri = Uri.parse(targetUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      debugPrint("Error launching URL externally: $e");
      try {
        final uri = Uri.parse(url);
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  Widget _buildExternalMeetingUI() {
    final session = widget.session;
    final isGoogleMeet = session.sessionUrl.toLowerCase().contains('meet.google.com');
    final isZoom = session.sessionUrl.toLowerCase().contains('zoom.us');
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LiveClassPulsingIcon(
                icon: isGoogleMeet 
                    ? LucideIcons.video 
                    : (isZoom ? LucideIcons.video : LucideIcons.externalLink),
                color: const Color(0xFFEAB308),
              ),
              const SizedBox(height: 32),
              Text(
                "External Meeting Platform",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEAB308),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                session.courseTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "To ensure the best audio and video quality, this live class is opened directly in your device's conference application.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.shieldCheck, 
                          size: 16, 
                          color: Colors.greenAccent[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Attendance logging active",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.greenAccent[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => _launchExternalUrl(session.sessionUrl),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEAB308).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isGoogleMeet 
                              ? "Open Google Meet" 
                              : (isZoom ? "Open Zoom" : "Join Live Class"),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          LucideIcons.arrowUpRight, 
                          size: 18, 
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Return to App",
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startAttendanceLogging() async {
    // Basic attendance log (existing)
    ref.read(liveServiceProvider).logAttendance(widget.session);
    
    // Advanced duration log for "Weekly Goal"
    try {
      final logId = await ref.read(learningServiceProvider).startSessionSession(widget.session.id);
      setState(() => _attendanceLogId = logId);
    } catch (e) {
      debugPrint("Error starting duration log: $e");
    }
  }

  @override
  void dispose() {
    // 3. End Duration Timer on exit
    if (_attendanceLogId != null) {
      ref.read(learningServiceProvider).endSessionSession(_attendanceLogId!);
    }
    // 4. Disable Secure Mode on exit
    _disableSecureMode();
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
          if (!_isExternal)
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 20),
              onPressed: () => _controller.reload(),
            ),
        ],
      ),
      body: _isExternal 
          ? _buildExternalMeetingUI() 
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}

class _LiveClassPulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _LiveClassPulsingIcon({required this.icon, required this.color});

  @override
  State<_LiveClassPulsingIcon> createState() => _LiveClassPulsingIconState();
}

class _LiveClassPulsingIconState extends State<_LiveClassPulsingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110 * _scaleAnimation.value,
              height: 110 * _scaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(_opacityAnimation.value * 0.3),
              ),
            ),
            Container(
              width: 90 * _scaleAnimation.value,
              height: 90 * _scaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(_opacityAnimation.value),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 32,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }
}
