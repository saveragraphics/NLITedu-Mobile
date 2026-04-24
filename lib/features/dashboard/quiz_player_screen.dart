import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/quiz_models.dart';
import '../../providers/learning_service.dart';
import 'dart:convert';

class QuizPlayerScreen extends ConsumerStatefulWidget {
  final Quiz quiz;
  const QuizPlayerScreen({super.key, required this.quiz});

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  final Map<String, int> _selectedAnswers = {}; // question_id -> selected_index
  bool _isSubmitting = false;

  void _submitQuiz(List<QuizQuestion> questions) async {
    if (_selectedAnswers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int score = 0;
      int totalPoints = 0;

      for (var q in questions) {
        totalPoints += q.points;
        if (_selectedAnswers[q.id] == q.correctIndex) {
          score += q.points;
        }
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('quiz_attempts').insert({
          'user_email': user.email,
          'quiz_id': widget.quiz.id,
          'score': score,
          'total_points': totalPoints,
          'answers': _selectedAnswers,
        });
      }

      if (!mounted) return;
      context.pop();
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Test Complete!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.checkCircle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('You scored $score out of $totalPoints.', style: GoogleFonts.inter(fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            )
          ],
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting test: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.quiz.id));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.quiz.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('No questions found for this test.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: questions.length + 2, // Header + Questions + Submit
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildFormHeader(theme);
              }
              
              if (index == questions.length + 1) {
                return _buildSubmitButton(questions);
              }

              final q = questions[index - 1];
              return _buildQuestionCard(theme, q, index);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading test: $e')),
      ),
    );
  }

  Widget _buildFormHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: AppTheme.primary, width: 8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.quiz.title, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(widget.quiz.description, style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${widget.quiz.durationMinutes} Minutes', style: const TextStyle(color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuestionCard(ThemeData theme, QuizQuestion q, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$number. ', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              Expanded(child: Text(q.questionText, style: GoogleFonts.inter(fontSize: 16))),
              Text('${q.points} pts', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(q.options.length, (optIndex) {
            return RadioListTile<int>(
              title: Text(q.options[optIndex], style: GoogleFonts.inter(fontSize: 14)),
              value: optIndex,
              groupValue: _selectedAnswers[q.id],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedAnswers[q.id] = val);
                }
              },
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(List<QuizQuestion> questions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submitQuiz(questions),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Submit Answers", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ),
    );
  }
}
