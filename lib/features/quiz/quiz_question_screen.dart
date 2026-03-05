import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/quiz_question.dart';
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';
import '../../widgets/quiz_option_button.dart';
import 'quiz_result_screen.dart';

class QuizQuestionScreen extends StatefulWidget {
  final String? setId;

  const QuizQuestionScreen({super.key, this.setId});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  int _currentIndex = 0;
  int _selectedOption = -1;
  int _score = 0;
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      List<QuizQuestion> questions;
      if (widget.setId != null) {
        questions = await QuizService.getQuestionsBySet(widget.setId!);
      } else {
        questions = await QuizService.getQuestions();
      }
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
        _stopwatch.start();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectOption(int index) {
    if (_selectedOption != -1) return;
    setState(() {
      _selectedOption = index;
      final correct = _questions[_currentIndex].correctAnswer;
      final labels = ['A', 'B', 'C', 'D'];
      if (labels[index] == correct) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = -1;
      });
    } else {
      _stopwatch.stop();
      final userId = AuthService.currentUser?.id;
      if (userId != null) {
        QuizService.saveResult(
          userId: userId,
          score: _score,
          totalQuestions: _questions.length,
          timeTakenSeconds: _stopwatch.elapsed.inSeconds,
          setId: widget.setId,
        );
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              QuizResultScreen(score: _score, total: _questions.length),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trắc nghiệm')),
        body: const Center(child: Text('Không có câu hỏi')),
      );
    }

    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 20),
          ),
        ),
        title: Column(
          children: [
            const Text('Kinh tế Chính trị'),
            Text(
              'Chương 3: Giá trị thặng dư',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Color(0xFFB45309),
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress & Timer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIẾN ĐỘ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                            letterSpacing: 1,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            children: [
                              TextSpan(text: 'Câu ${_currentIndex + 1} '),
                              TextSpan(
                                text: '/ ${_questions.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '01:30',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Question
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: q.options.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final labels = ['A', 'B', 'C', 'D'];
                return QuizOptionButton(
                  label: labels[i],
                  text: q.options[i],
                  isSelected: _selectedOption == i,
                  isCorrect: labels[i] == q.correctAnswer,
                  showResult: _selectedOption != -1,
                  onTap: () => _selectOption(i),
                );
              },
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIndex > 0
                        ? () => setState(() {
                            _currentIndex--;
                            _selectedOption = -1;
                          })
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Quay lại'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedOption != -1 ? _nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex < _questions.length - 1
                              ? 'Câu tiếp theo'
                              : 'Xem kết quả',
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
