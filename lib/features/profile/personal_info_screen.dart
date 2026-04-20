import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import 'profile_provider.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameCtrl = TextEditingController(text: profile?.fullName);
    _phoneCtrl = TextEditingController(text: profile?.phone ?? "");
    _emailCtrl = TextEditingController(text: profile?.email);
  }

  Future<void> _saveChanges() async {
    setState(() => _loading = true);
    try {
      await ref.read(profileProvider.notifier).updateProfile(_nameCtrl.text, _phoneCtrl.text);
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Profile updated successfully!"),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    } catch(e) {
       if (mounted) {
         final theme = Theme.of(context);
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: theme.colorScheme.error),
         );
       }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface, elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Personal Info", style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update your personal details here.", style: GoogleFonts.inter(
              fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
              decoration: _inputDeco(context, "Full Name", LucideIcons.user),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              readOnly: true,
              style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant),
              decoration: _inputDeco(context, "Email Address", LucideIcons.mail).copyWith(
                 fillColor: theme.colorScheme.surfaceContainer,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
              decoration: _inputDeco(context, "Phone Number", LucideIcons.phone),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0),
                child: _loading 
                  ? CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2)
                  : Text("Save Changes", style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(BuildContext context, String hint, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: theme.colorScheme.outline),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3), width: 2)),
    );
  }
}
