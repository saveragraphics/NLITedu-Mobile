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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameCtrl = TextEditingController(text: profile?.fullName);
  }

  Future<void> _saveChanges() async {
    setState(() => _loading = true);
    try {
      await ref.read(profileProvider.notifier).updateName(_nameCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Profile updated successfully!"),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    } catch(e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
         );
       }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface, elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Personal Info", style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update your personal details here.", style: GoogleFonts.inter(
              fontSize: 14, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.inter(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: "Full Name",
                prefixIcon: const Icon(LucideIcons.user, size: 18, color: AppTheme.outline),
                filled: true,
                fillColor: AppTheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3), width: 2)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0),
                child: _loading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("Save Changes", style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
