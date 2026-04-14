import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

/// Stitch 01 Login — Mobile/Tablet optimized, full-screen, no floating
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  bool _isSignUp = false;
  final _nameCtrl = TextEditingController();

  Future<void> _submitAuth() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty || (_isSignUp && _nameCtrl.text.trim().isEmpty)) {
      _showError("Please fill in all required fields");
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          data: {'full_name': _nameCtrl.text.trim(), 'avatar_url': ''},
        );
        _showSuccess("Account created successfully! You can now log in.");
        setState(() {
          _isSignUp = false;
          _passCtrl.clear();
        });
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (mounted) context.go('/catalog');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.nlitedu://login-callback',
    );
  }

  Future<void> _signInWithApple() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.nlitedu://login-callback',
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final horizontalPad = isTablet ? 64.0 : 24.0;

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFAF8FF), Color(0xFFFDE7F9), Color(0xFFE8DDFF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: screenH * 0.04),
                          // App logo + brand
                          Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset('assets/app_logo.png',
                                width: 48, height: 48, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            Text("NLITedu", style: GoogleFonts.plusJakartaSans(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface, letterSpacing: -1)),
                          ]),

                          SizedBox(height: screenH * 0.05),
                          // Editorial heading - responsive
                          Text(_isSignUp ? "Join Us" : "Welcome", style: GoogleFonts.plusJakartaSans(
                            fontSize: isTablet ? 64 : 44,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                            height: 0.95, letterSpacing: -2,
                          )),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.secondary],
                            ).createShader(bounds),
                            child: Text(_isSignUp ? "Today" : "Back", style: GoogleFonts.plusJakartaSans(
                              fontSize: isTablet ? 64 : 44,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 0.95, letterSpacing: -2,
                            )),
                          ),
                          const SizedBox(height: 12),
                          Text(_isSignUp ? "Begin your digital learning journey." : "Step back into your digital classroom.\nCurated knowledge awaits.",
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500,
                              color: AppTheme.onSurfaceVariant, height: 1.5)),

                          SizedBox(height: screenH * 0.04),
                          // Full Name field for sign up
                          if (_isSignUp) ...[
                            _label("Full Name"),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              style: GoogleFonts.inter(color: AppTheme.onSurface),
                              decoration: _inputDeco("John Doe", LucideIcons.user),
                            ),
                            const SizedBox(height: 20),
                          ],
                          // Email field
                          _label("Email Address"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(color: AppTheme.onSurface),
                            decoration: _inputDeco("curator@nexgen.edu", LucideIcons.mail),
                          ),
                          const SizedBox(height: 20),
                          // Password field
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            _label("Password"),
                            if (!_isSignUp)
                              GestureDetector(
                                onTap: () {},
                                child: Text("Forgot Password?", style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppTheme.primary, fontStyle: FontStyle.italic)),
                              ),
                          ]),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            style: GoogleFonts.inter(color: AppTheme.onSurface),
                            decoration: _inputDeco("••••••••", LucideIcons.lock).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 20, color: AppTheme.outline),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Sign In / Sign Up button
                          SizedBox(
                            width: double.infinity, height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submitAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 6,
                                shadowColor: AppTheme.primary.withOpacity(0.3),
                              ),
                              child: _loading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text(_isSignUp ? "Create Account" : "Start Learning", style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Icon(_isSignUp ? LucideIcons.userPlus : LucideIcons.arrowRight, color: Colors.white, size: 20),
                                  ]),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Toggle text
                          Center(child: GestureDetector(
                            onTap: () => setState(() => _isSignUp = !_isSignUp),
                            child: RichText(text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurfaceVariant),
                              children: [
                                TextSpan(text: _isSignUp ? "Already have an account? " : "New here? "),
                                TextSpan(text: _isSignUp ? "Log In" : "Create an Account",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700,
                                    color: AppTheme.primary, decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.secondaryContainer, decorationThickness: 2)),
                              ],
                            )),
                          )),
                          const SizedBox(height: 28),
                          // Divider
                          Row(children: [
                            Expanded(child: Divider(color: AppTheme.outlineVariant.withOpacity(0.4))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(_isSignUp ? "OR SIGN UP WITH" : "OR CONTINUE WITH", style: GoogleFonts.inter(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: AppTheme.outline, letterSpacing: 1.5))),
                            Expanded(child: Divider(color: AppTheme.outlineVariant.withOpacity(0.4))),
                          ]),
                          const SizedBox(height: 20),
                          // Social buttons — full width
                          Row(children: [
                            Expanded(child: _socialBtn(
                              onTap: _signInWithGoogle,
                              icon: _googleIcon(),
                              label: "Google",
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _socialBtn(
                              onTap: _signInWithApple,
                              icon: const Icon(LucideIcons.apple, size: 20, color: AppTheme.onSurface),
                              label: "Apple",
                            )),
                          ]),
                          const Spacer(),
                          // Footer
                          Center(child: Padding(
                            padding: const EdgeInsets.only(bottom: 16, top: 24),
                            child: Text("© 2024 NLITedu • Intellectual Growth Reimagined",
                              style: GoogleFonts.inter(fontSize: 10, color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                                letterSpacing: 0.5)),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text, style: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
  );

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: AppTheme.outline, fontSize: 14),
    prefixIcon: Icon(icon, size: 18, color: AppTheme.outline),
    filled: true,
    fillColor: AppTheme.surfaceContainerLowest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  );

  Widget _socialBtn({required VoidCallback onTap, required Widget icon, required String label}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon,
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
        ]),
      ),
    );
  }

  /// Proper Google "G" icon with brand colors
  Widget _googleIcon() => SizedBox(
    width: 20, height: 20,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w * 0.45;

    // Blue arc (top-right)
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      -0.5, 1.4, true, Paint()..color = const Color(0xFF4285F4));
    // Green arc (bottom-right)
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      0.9, 1.1, true, Paint()..color = const Color(0xFF34A853));
    // Yellow arc (bottom-left)
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      2.0, 1.1, true, Paint()..color = const Color(0xFFFBBC05));
    // Red arc (top-left)
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      3.1, 1.1, true, Paint()..color = const Color(0xFFEA4335));
    // White center
    canvas.drawCircle(center, radius * 0.55, Paint()..color = Colors.white);
    // Blue bar
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.32, w * 0.48, h * 0.36),
      Paint()..color = const Color(0xFF4285F4));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
