import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/quiz_question.dart';
import '../../services/quiz_service.dart';
import '../../widgets/quiz_option_button.dart';

class PvpBattleScreen extends StatefulWidget {
  const PvpBattleScreen({super.key});

  @override
  State<PvpBattleScreen> createState() => _PvpBattleScreenState();
}

class _PvpBattleScreenState extends State<PvpBattleScreen> {
  int _selectedOption = -1;
  int _playerScore = 0;
  final int _opponentScore = 0;
  int _currentIndex = 0;
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await QuizService.getQuestions(limit: 10);
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectAnswer(int index) {
    if (_selectedOption != -1 || _questions.isEmpty) return;
    final q = _questions[_currentIndex];
    final labels = ['A', 'B', 'C', 'D'];
    setState(() {
      _selectedOption = index;
      if (labels[index] == q.correctAnswer) {
        _playerScore += 100;
      }
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = -1;
        });
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        title: Column(
          children: [
            const Text('Thách đấu PvP'),
            Text(
              'VÒNG ${_currentIndex + 1}/${_questions.length}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        actions: [
          Icon(Icons.emoji_events, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Scoreboard & VS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary.withAlpha(13), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                // Player
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary.withAlpha(51),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BẠN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                      Text(
                        '$_playerScore',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // VS
                Column(
                  children: [
                    Transform(
                      transform: Matrix4.skewX(-0.15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 48,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: AppColors.primary.withAlpha(51),
                    ),
                  ],
                ),
                // Opponent
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFFFE4E6),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: const Color(0xFFE11D48),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ĐỐI THỦ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                      Text(
                        '$_opponentScore',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thời gian suy nghĩ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '14s',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.7,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Question
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_questions.isEmpty)
            const Expanded(child: Center(child: Text('Không có câu hỏi')))
          else ...[
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: AppColors.primary, width: 4),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4),
                  ],
                ),
                child: Text(
                  _questions[_currentIndex].question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            // Answer options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  QuizOptionButton(
                    label: 'A',
                    text: _questions[_currentIndex].optionA,
                    isSelected: _selectedOption == 0,
                    isCorrect: _questions[_currentIndex].correctAnswer == 'A',
                    showResult: _selectedOption != -1,
                    onTap: () => _selectAnswer(0),
                  ),
                  const SizedBox(height: 12),
                  QuizOptionButton(
                    label: 'B',
                    text: _questions[_currentIndex].optionB,
                    isSelected: _selectedOption == 1,
                    isCorrect: _questions[_currentIndex].correctAnswer == 'B',
                    showResult: _selectedOption != -1,
                    onTap: () => _selectAnswer(1),
                  ),
                  const SizedBox(height: 12),
                  QuizOptionButton(
                    label: 'C',
                    text: _questions[_currentIndex].optionC,
                    isSelected: _selectedOption == 2,
                    isCorrect: _questions[_currentIndex].correctAnswer == 'C',
                    showResult: _selectedOption != -1,
                    onTap: () => _selectAnswer(2),
                  ),
                  const SizedBox(height: 12),
                  QuizOptionButton(
                    label: 'D',
                    text: _questions[_currentIndex].optionD,
                    isSelected: _selectedOption == 3,
                    isCorrect: _questions[_currentIndex].correctAnswer == 'D',
                    showResult: _selectedOption != -1,
                    onTap: () => _selectAnswer(3),
                  ),
                ],
              ),
            ),

            // Opponent status
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFFE4E6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Đối thủ đang suy nghĩ...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ], // end else spread
        ],
      ),
    );
  }
}
