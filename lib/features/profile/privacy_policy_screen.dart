import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';

/// Stitch 01 Privacy Policy — from Design_Specs/privacy_policy/code.html
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Legal Policies", style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.primaryContainer]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(100)),
                  child: Text("NLITEDU", style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                Text("Privacy Policy", style: GoogleFonts.plusJakartaSans(
                  fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                Text("Last updated: October 24, 2024", style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primaryFixedDim)),
              ]),
            ),
            const SizedBox(height: 32),

            // Introduction
            _sectionTitle("Introduction"),
            const SizedBox(height: 12),
            _bodyText("At NLITedu, we believe education is a fundamental human right, and so is privacy. This Privacy Policy describes how we collect, use, and protect your personal information when you use our educational platform."),
            const SizedBox(height: 8),
            _bodyText("We are committed to transparency and clarity. This document is designed to be readable, skipping the dense legal jargon wherever possible while maintaining the rigorous protections your data deserves."),
            const SizedBox(height: 32),

            // Data Collection — Bento cards
            _sectionTitle("Data Collection"),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _dataCard(LucideIcons.user, AppTheme.primaryFixed, AppTheme.primary,
                "Identity Information",
                "Full name, email address, and profile biography used to personalize your learning journey.")),
              const SizedBox(width: 12),
              Expanded(child: _dataCard(LucideIcons.barChart2, AppTheme.secondaryFixed, AppTheme.secondary,
                "Usage Metrics",
                "Time spent on lessons, quiz scores, and interaction patterns to optimize the platform.")),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Device & Browser Data", style: GoogleFonts.plusJakartaSans(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                const SizedBox(height: 8),
                _bodyText("IP addresses, browser types, and operating system information are automatically logged to ensure technical stability and prevent unauthorized access."),
              ]),
            ),
            const SizedBox(height: 32),

            // Use of Information
            _sectionTitle("Use of Information"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border(left: BorderSide(color: AppTheme.primary, width: 4)),
              ),
              child: Column(children: [
                _numberedItem("01", "Curating Your Path",
                  "We use your progress data to recommend specific modules that match your learning pace and interests."),
                const SizedBox(height: 20),
                _numberedItem("02", "Platform Integrity",
                  "Automated systems analyze interaction patterns to detect fraudulent behavior or potential security threats."),
                const SizedBox(height: 20),
                _numberedItem("03", "Direct Updates",
                  "Email communications regarding course updates, legal changes, or technical maintenance."),
              ]),
            ),
            const SizedBox(height: 32),

            // User Rights
            _sectionTitle("User Rights"),
            const SizedBox(height: 8),
            _bodyText("You maintain full sovereignty over your data. Under international guidelines, you possess the following rights:"),
            const SizedBox(height: 16),
            _rightItem("The Right to Access"),
            const SizedBox(height: 8),
            _rightItem("The Right to Erasure (Forget Me)"),
            const SizedBox(height: 8),
            _rightItem("The Right to Rectification"),
            const SizedBox(height: 32),

            // Contact
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(28)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Questions or Concerns?", style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 12),
                Text("Our dedicated privacy officer is available to handle any inquiries regarding your data security.",
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.primaryFixedDim)),
                const SizedBox(height: 20),
                _contactChip(LucideIcons.mail, "privacy@nlitedu.com"),
                const SizedBox(height: 10),
                _contactChip(LucideIcons.mapPin, "India HQ"),
              ]),
            ),
            const SizedBox(height: 32),
            Center(child: Text("© 2024 NLITedu. All rights reserved.",
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant))),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: GoogleFonts.plusJakartaSans(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.onSurface));

  Widget _bodyText(String text) => Text(text, style: GoogleFonts.inter(
    fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.6));

  Widget _dataCard(IconData icon, Color bgColor, Color iconColor, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 22, color: iconColor)),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(desc, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.5)),
      ]),
    );
  }

  Widget _numberedItem(String num, String title, String desc) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(num, style: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(desc, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.onSurfaceVariant)),
      ])),
    ]);
  }

  Widget _rightItem(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const Icon(LucideIcons.chevronRight, size: 18, color: AppTheme.outline),
      ]),
    );
  }

  Widget _contactChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
      ]),
    );
  }
}
