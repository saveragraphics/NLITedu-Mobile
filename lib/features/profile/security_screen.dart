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
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Password updated successfully!"),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
        _passCtrl.clear();
        _newPassCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: theme.colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface, elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop()),
        title: Text("Security", style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Account info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
                child: Icon(LucideIcons.shieldCheck, size: 22, color: theme.colorScheme.primary)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Account Email", style: GoogleFonts.inter(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(user?.email ?? "Not available", style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
              ])),
            ]),
          ),
          const SizedBox(height: 28),

          // Change Password
          Text("Change Password", style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
            decoration: _inputDeco(context, "Current Password", LucideIcons.lock)),
          const SizedBox(height: 12),
          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
            decoration: _inputDeco(context, "New Password", LucideIcons.keyRound)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0),
              child: _loading
                ? CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2)
                : Text("Update Password", style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimary)),
            ),
          ),
          const SizedBox(height: 32),

          // Security Options
          Text("Security Options", style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          _toggleCard(context, LucideIcons.smartphone, "Two-Factor Authentication",
            "Extra layer of security via SMS or authenticator app",
            _twoFactor, (v) => setState(() => _twoFactor = v)),
          const SizedBox(height: 8),
          _toggleCard(context, LucideIcons.fingerprint, "Biometric Login",
            "Use fingerprint or face ID to sign in",
            _biometric, (v) => setState(() => _biometric = v)),
          const SizedBox(height: 32),

          // Active Sessions
          Text("Active Sessions", style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          _sessionCard(context, "This Device", "Active now", true),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.3)),
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

  InputDecoration _inputDeco(BuildContext context, String hint, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: theme.colorScheme.outline, fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: theme.colorScheme.outline),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _toggleCard(BuildContext context, IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(
            fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        ])),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: theme.colorScheme.primary),
      ]),
    );
  }

  Widget _sessionCard(BuildContext context, String device, String status, bool isActive) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14)),
          child: Icon(LucideIcons.monitor, size: 20,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(device, style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 2),
          Row(children: [
            Container(width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: isActive ? const Color(0xFF22C55E) : theme.colorScheme.outline)),
            const SizedBox(width: 6),
            Text(status, style: GoogleFonts.inter(
              fontSize: 12, color: isActive ? const Color(0xFF22C55E) : theme.colorScheme.onSurfaceVariant)),
          ]),
        ])),
      ]),
    );
  }
}
