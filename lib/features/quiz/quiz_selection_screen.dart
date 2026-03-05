import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/quiz_service.dart';
import 'quiz_question_screen.dart';

class QuizSelectionScreen extends StatefulWidget {
  const QuizSelectionScreen({super.key});

  @override
  State<QuizSelectionScreen> createState() => _QuizSelectionScreenState();
}

class _QuizSelectionScreenState extends State<QuizSelectionScreen> {
  List<Map<String, dynamic>> _quizSets = [];
  bool _isLoading = true;
  String _selectedDifficulty = 'basic';

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() => _isLoading = true);
    try {
      final sets = await QuizService.getQuizSets(
        difficulty: _selectedDifficulty,
      );
      if (mounted)
        setState(() {
          _quizSets = sets;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Chọn bài trắc nghiệm'),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _TabItem(
                  label: 'Cơ bản',
                  isActive: _selectedDifficulty == 'basic',
                  onTap: () {
                    _selectedDifficulty = 'basic';
                    _loadSets();
                  },
                ),
                _TabItem(
                  label: 'Trung bình',
                  isActive: _selectedDifficulty == 'medium',
                  onTap: () {
                    _selectedDifficulty = 'medium';
                    _loadSets();
                  },
                ),
                _TabItem(
                  label: 'Nâng cao',
                  isActive: _selectedDifficulty == 'advanced',
                  onTap: () {
                    _selectedDifficulty = 'advanced';
                    _loadSets();
                  },
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _quizSets.isEmpty
                ? const Center(child: Text('Chưa có bộ câu hỏi'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Danh sách bộ câu hỏi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._quizSets.map((set) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _QuizCard(
                            title: set['title'] ?? 'Bộ câu hỏi',
                            questions: set['question_count'] ?? 10,
                            difficulty: set['difficulty'] ?? 'Cơ bản',
                            xp: (set['question_count'] ?? 10) * 5,
                            onStart: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    QuizQuestionScreen(setId: set['id']),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _TabItem({required this.label, required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String title;
  final int questions;
  final String difficulty;
  final int xp;
  final bool isContinue;
  final VoidCallback onStart;

  const _QuizCard({
    required this.title,
    required this.questions,
    required this.difficulty,
    required this.xp,
    this.isContinue = false,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: AppColors.primary.withAlpha(13)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          '$questions câu hỏi',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.accentGold),
                        const SizedBox(width: 4),
                        Text(
                          '($difficulty)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 14,
                          color: AppColors.accentGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+$xp XP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isContinue
                          ? AppColors.border
                          : AppColors.primary,
                      foregroundColor: isContinue
                          ? AppColors.textSecondary
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(isContinue ? 'Tiếp tục' : 'Bắt đầu'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school, size: 40, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
