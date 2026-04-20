import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Terms and Conditions Screen matching Play Store baseline requirements
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

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
                  child: Text("NLITEDU", style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimary, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                Text("Terms of Service", style: GoogleFonts.plusJakartaSans(
                  fontSize: 32, fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimary)),
                const SizedBox(height: 6),
                Text("Last updated: October 24, 2024", style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onPrimary.withOpacity(0.8))),
              ]),
            ),
            const SizedBox(height: 32),

            // Introduction
            _sectionTitle(context, "1. Acceptance of Terms"),
            const SizedBox(height: 12),
            _bodyText(context, "By accessing or using the NLITedu platform (the \"Service\"), you agree to be bound by these Terms of Service. If you disagree with any part of the terms, you may not access the Service."),
            const SizedBox(height: 8),
            _bodyText(context, "These Terms apply to all visitors, users, and others who access or use the Service. We reserve the right, at our sole discretion, to modify or replace these Terms at any time."),
            const SizedBox(height: 32),

            // Content
            _sectionTitle(context, "2. User Accounts"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Account Responsibilities", style: GoogleFonts.plusJakartaSans(
                  fontSize: 17, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                _bodyText(context, "When you create an account with us, you must provide information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of your account on our Service."),
                const SizedBox(height: 12),
                _bodyText(context, "You are responsible for safeguarding the password that you use to access the Service and for any activities or actions under your password."),
              ]),
            ),
            const SizedBox(height: 32),

            // Rules
            _sectionTitle(context, "3. Platform Rules"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
              ),
              child: Column(children: [
                _numberedItem(context, "01", "Intellectual Property",
                  "The Service and its original content, features and functionality are and will remain the exclusive property of NLITedu and its licensors."),
                const SizedBox(height: 20),
                _numberedItem(context, "02", "Prohibited Uses",
                  "You agree not to use the Service in any way that violates any applicable national or international law or regulation, or to engage in any conduct that restricts or inhibits anyone's use."),
                const SizedBox(height: 20),
                _numberedItem(context, "03", "Termination",
                  "We may terminate or suspend access to our Service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms."),
              ]),
            ),
            const SizedBox(height: 32),

            // Contact
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(28)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Need Clarification?", style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimary)),
                const SizedBox(height: 12),
                Text("If you have any questions about these Terms, please contact our legal support team.",
                  style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onPrimary.withOpacity(0.8))),
                const SizedBox(height: 20),
                _contactChip(context, LucideIcons.mail, "info@nlitedu.com"),
                const SizedBox(height: 10),
                _contactChip(context, LucideIcons.globe, "www.nlitedu.com/legal"),
              ]),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text("© 2026 NLITedu. All rights reserved.",
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
