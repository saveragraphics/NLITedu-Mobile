import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I access live interactive classes?',
      'answer': 'Live classes are displayed directly on your Learning Hub screen. Simply tap on any active live session tile to join the class. Real-time attendance logging is automatically active during the session.',
      'category': 'Classes',
    },
    {
      'question': 'What are the available internship modes?',
      'answer': 'We offer two main internship modes:\n• Online: Entirely remote work, including online sessions, digital submissions, and remote collaboration.\n• Online + Offline: A hybrid model that combines online learning with in-person laboratory sessions and hands-on training.',
      'category': 'Internship',
    },
    {
      'question': 'What should I do if the app shows offline or disconnects?',
      'answer': 'The app includes an auto-recovery mechanism. When you resume the app, it automatically refreshes your security credentials in the background. If you face persistent issues, please check your internet connection or restart the app.',
      'category': 'Technical',
    },
    {
      'question': 'How do I claim my internship certificate?',
      'answer': 'Once you have completed all modules, submitted the required assignments, and passed the final evaluation, your certificate will automatically unlock in the Achievements section of your profile.',
      'category': 'Certificates',
    },
    {
      'question': 'How can I change my profile information?',
      'answer': 'Navigate to your Profile screen, tap on "Personal Info" under Settings, and edit your name, email, or bio. Tap save to update your credentials instantly.',
      'category': 'Account',
    },
    {
      'question': 'Are the course plans one-time or subscription-based?',
      'answer': 'Depending on your selection, we offer both one-time payments for specific courses/internships and subscription plans for unlimited access to the entire catalogue. Visit the "View Plans" card on your profile for details.',
      'category': 'Payments',
    },
  ];

  List<String> get _categories => ['All', 'Technical', 'Internship', 'Classes', 'Certificates', 'Account', 'Payments'];

  List<Map<String, String>> get _filteredFaqs {
    return _faqs.where((faq) {
      final matchesQuery = faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> _launchUrlHelper(String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("Could not launch $urlString: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        title: Text(
          "Help & Support",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "SUPPORT CENTER",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "How can we help?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Search our database or connect directly with our experts",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onPrimary.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search topics, issues, or questions...",
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.outline),
                  prefixIcon: Icon(LucideIcons.search, size: 20, color: theme.colorScheme.outline),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x, size: 18, color: theme.colorScheme.outline),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Categories Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // Frequently Asked Questions Title
              Text(
                "Frequently Asked Questions",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // FAQ Accordion List
              if (_filteredFaqs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(LucideIcons.helpCircle, size: 48, color: theme.colorScheme.outline.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        "No matching FAQ topics found",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Try searching for something else or contact us below.",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._filteredFaqs.map((faq) => _FaqAccordionTile(faq: faq)),

              const SizedBox(height: 36),

              // Direct Contact Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Still need help?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Our support channels are open 24/7 to resolve your technical and educational queries.",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Options
                    _ContactLinkButton(
                      icon: LucideIcons.messageSquare,
                      title: "Chat on WhatsApp",
                      subtitle: "Fastest response within minutes",
                      onTap: () => _launchUrlHelper("https://wa.me/919304033816"),
                      color: const Color(0xFF25D366),
                    ),
                    const SizedBox(height: 12),
                    _ContactLinkButton(
                      icon: LucideIcons.phone,
                      title: "Call Support Helpline",
                      subtitle: "Direct voice call with our experts",
                      onTap: () => _launchUrlHelper("tel:+919304033816"),
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    _ContactLinkButton(
                      icon: LucideIcons.mail,
                      title: "Email Support Team",
                      subtitle: "Get resolution on tickets in 24 hours",
                      onTap: () => _launchUrlHelper("mailto:info@nlitedu.com"),
                      color: Colors.amber.shade700,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      "© 2026 NLIT. All rights reserved.",
                      style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqAccordionTile extends StatefulWidget {
  final Map<String, String> faq;

  const _FaqAccordionTile({required this.faq});

  @override
  State<_FaqAccordionTile> createState() => _FaqAccordionTileState();
}

class _FaqAccordionTileState extends State<_FaqAccordionTile> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpanded
              ? theme.colorScheme.primary.withOpacity(0.5)
              : theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: _isExpanded ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              widget.faq['question']!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            trailing: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: _isExpanded ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
            ),
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.3), height: 1),
                    const SizedBox(height: 12),
                    Text(
                      widget.faq['answer']!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactLinkButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _ContactLinkButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
