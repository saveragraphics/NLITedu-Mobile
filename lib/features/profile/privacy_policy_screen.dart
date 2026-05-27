import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';

/// Stitch 01 Privacy Policy — from Design_Specs/privacy_policy/code.html
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Legal Policies", style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(100)),
                  child: Text("NLIT", style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimary, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                Text("Privacy Policy", style: GoogleFonts.plusJakartaSans(
                  fontSize: 32, fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimary)),
                const SizedBox(height: 6),
                Text("Last updated: May 22, 2026", style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onPrimary.withOpacity(0.8))),
              ]),
            ),
            const SizedBox(height: 32),

            // Introduction
            _sectionTitle(context, "Introduction"),
            const SizedBox(height: 12),
            _bodyText(context, "At Nexgen Learning Institute Of Technology (NLIT), we believe education is a fundamental human right, and so is privacy. This Privacy Policy describes how we collect, use, and protect your personal information when you use our educational platform."),
            const SizedBox(height: 8),
            _bodyText(context, "We are committed to transparency and clarity. This document is designed to be readable, skipping the dense legal jargon wherever possible while maintaining the rigorous protections your data deserves."),
            const SizedBox(height: 32),

            // Data Collection — Bento cards
            _sectionTitle(context, "Data Collection"),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _dataCard(context, LucideIcons.user, theme.colorScheme.primary.withOpacity(0.1), theme.colorScheme.primary,
                "Identity Information",
                "Full name, email address, and profile biography used to personalize your learning journey.")),
              const SizedBox(width: 12),
              Expanded(child: _dataCard(context, LucideIcons.barChart2, theme.colorScheme.secondary.withOpacity(0.1), theme.colorScheme.secondary,
                "Usage Metrics",
                "Time spent on lessons, quiz scores, and interaction patterns to optimize the platform.")),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Device & Browser Data", style: GoogleFonts.plusJakartaSans(
                  fontSize: 17, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                _bodyText(context, "IP addresses, browser types, and operating system information are automatically logged to ensure technical stability and prevent unauthorized access."),
              ]),
            ),
            const SizedBox(height: 32),

            // Use of Information
            _sectionTitle(context, "Use of Information"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
              ),
              child: Column(children: [
                _numberedItem(context, "01", "Curating Your Path",
                  "We use your progress data to recommend specific modules that match your learning pace and interests."),
                const SizedBox(height: 20),
                _numberedItem(context, "02", "Platform Integrity",
                  "Automated systems analyze interaction patterns to detect fraudulent behavior or potential security threats."),
                const SizedBox(height: 20),
                _numberedItem(context, "03", "Direct Updates",
                  "Email communications regarding course updates, legal changes, or technical maintenance."),
              ]),
            ),
            const SizedBox(height: 32),

            // User Rights
            _sectionTitle(context, "User Rights"),
            const SizedBox(height: 8),
            _bodyText(context, "You maintain full sovereignty over your data. Under international guidelines, you possess the following rights:"),
            const SizedBox(height: 16),
            _rightItem(context, "The Right to Access"),
            const SizedBox(height: 8),
            _rightItem(context, "The Right to Erasure (Forget Me)"),
            const SizedBox(height: 8),
            _rightItem(context, "The Right to Rectification"),
            const SizedBox(height: 32),

            // Contact
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(28)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Questions or Concerns?", style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimary)),
                const SizedBox(height: 12),
                Text("Our dedicated privacy officer is available to handle any inquiries regarding your data security.",
                  style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onPrimary.withOpacity(0.8))),
                const SizedBox(height: 20),
                _contactChip(context, LucideIcons.mail, "info@nlitedu.com"),
                const SizedBox(height: 10),
                _contactChip(context, LucideIcons.mapPin, "India HQ"),
              ]),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text("© 2026 Nexgen Learning Institute Of Technology (NLIT). All rights reserved.",
                    style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      children: [
                        const TextSpan(text: "APP DESIGNED BY "),
                        TextSpan(
                          text: "SAVERAGRAPHICS", 
                          style: TextStyle(color: Colors.amber.shade700.withOpacity(0.8)),
                        ),
                        const TextSpan(text: "\nA "),
                        TextSpan(
                          text: "sindhuragroup ", 
                          style: GoogleFonts.ptSerif(
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                        const TextSpan(text: "COMPANY"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(text, style: GoogleFonts.plusJakartaSans(
      fontSize: 24, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface));
  }

  Widget _bodyText(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(text, style: GoogleFonts.inter(
      fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.6));
  }

  Widget _dataCard(BuildContext context, IconData icon, Color bgColor, Color iconColor, String title, String desc) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 22, color: iconColor)),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(desc, style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
      ]),
    );
  }

  Widget _numberedItem(BuildContext context, String num, String title, String desc) {
    final theme = Theme.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(num, style: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text(desc, style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
      ])),
    ]);
  }

  Widget _rightItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        Icon(LucideIcons.chevronRight, size: 18, color: theme.colorScheme.outline),
      ]),
    );
  }

  Widget _contactChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, size: 18, color: theme.colorScheme.onPrimary),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onPrimary)),
      ]),
    );
  }
}
