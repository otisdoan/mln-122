import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;

  const QuizResultScreen({super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final percentage = (score / total * 100).round();
    final xpGained = score * 5;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Kết quả trắc nghiệm'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Celebration section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chúc mừng!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn đã hoàn thành bài thi xuất sắc',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Score cards
          Row(
            children: [
              Expanded(
                child: _ResultCard(
                  label: 'Điểm số',
                  value: '$score/$total',
                  sub: '$percentage%',
                  subIcon: Icons.trending_up,
                  subColor: AppColors.accentGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ResultCard(
                  label: 'Kinh nghiệm',
                  value: '+$xpGained XP',
                  sub: 'LEVEL UP',
                  subIcon: Icons.add_circle,
                  subColor: AppColors.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Làm lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.home),
                  label: const Text('Trang chủ'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Question details
          const Text(
            'Chi tiết câu hỏi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...List.generate(total, (i) {
            final isCorrect = i < score;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.accentGreen.withAlpha(13)
                      : AppColors.error.withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.accentGreen.withAlpha(51)
                        : AppColors.error.withAlpha(51),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.accentGreen
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Câu ${(i + 1).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isCorrect
                                  ? const Color(0xFF14532D)
                                  : const Color(0xFF7F1D1D),
                            ),
                          ),
                          Text(
                            isCorrect
                                ? 'Đáp án của bạn hoàn toàn chính xác.'
                                : 'Sai. Hãy xem lại bài học.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isCorrect
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData subIcon;
  final Color subColor;

  const _ResultCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.subIcon,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(subIcon, size: 14, color: subColor),
              const SizedBox(width: 4),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
