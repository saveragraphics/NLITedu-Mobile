import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

/// Stitch 01 Security Settings — password change, 2FA, sessions
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactor = false;
  bool _biometric = false;
  final _passCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPassCtrl.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Password updated successfully!"),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
        _passCtrl.clear();
        _newPassCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface, elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop()),
        title: Text("Security", style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Account info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryFixed,
                  borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.shieldCheck, size: 22, color: AppTheme.primary)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Account Email", style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(user?.email ?? "Not available", style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
              ])),
            ]),
          ),
          const SizedBox(height: 28),

          // Change Password
          Text("Change Password", style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            style: GoogleFonts.inter(color: AppTheme.onSurface),
            decoration: _inputDeco("Current Password", LucideIcons.lock)),
          const SizedBox(height: 12),
          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            style: GoogleFonts.inter(color: AppTheme.onSurface),
            decoration: _inputDeco("New Password", LucideIcons.keyRound)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0),
              child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Update Password", style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),

          // Security Options
          Text("Security Options", style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          const SizedBox(height: 12),
          _toggleCard(LucideIcons.smartphone, "Two-Factor Authentication",
            "Extra layer of security via SMS or authenticator app",
            _twoFactor, (v) => setState(() => _twoFactor = v)),
          const SizedBox(height: 8),
          _toggleCard(LucideIcons.fingerprint, "Biometric Login",
            "Use fingerprint or face ID to sign in",
            _biometric, (v) => setState(() => _biometric = v)),
          const SizedBox(height: 32),

          // Active Sessions
          Text("Active Sessions", style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          const SizedBox(height: 12),
          _sessionCard("This Device", "Active now", true),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text("Sign Out All Other Sessions", style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

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
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  );

  Widget _toggleCard(IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 20, color: AppTheme.onSurfaceVariant)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(
            fontSize: 12, color: AppTheme.onSurfaceVariant)),
        ])),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppTheme.primary),
      ]),
    );
  }

  Widget _sessionCard(String device, String status, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryFixed : AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14)),
          child: Icon(LucideIcons.monitor, size: 20,
            color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(device, style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          const SizedBox(height: 2),
          Row(children: [
            Container(width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: isActive ? const Color(0xFF22C55E) : AppTheme.outline)),
            const SizedBox(width: 6),
            Text(status, style: GoogleFonts.inter(
              fontSize: 12, color: isActive ? const Color(0xFF22C55E) : AppTheme.onSurfaceVariant)),
          ]),
        ])),
      ]),
    );
  }
}
