import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuizOptionButton extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback? onTap;

  const QuizOptionButton({
    super.key,
    required this.label,
    required this.text,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color bgColor = Colors.white;
    Color labelBgColor = const Color(0xFFF1F5F9);
    Color labelTextColor = AppColors.textSecondary;
    Color textColor = AppColors.textSecondary;

    if (isSelected && !showResult) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withAlpha(13);
      labelBgColor = AppColors.primary;
      labelTextColor = Colors.white;
      textColor = AppColors.primary;
    } else if (showResult && isCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withAlpha(13);
      labelBgColor = AppColors.success;
      labelTextColor = Colors.white;
      textColor = AppColors.success;
    } else if (showResult && isSelected && !isCorrect) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withAlpha(13);
      labelBgColor = AppColors.error;
      labelTextColor = Colors.white;
      textColor = AppColors.error;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: labelBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: labelTextColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (showResult && isSelected)
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppColors.success : AppColors.error,
              ),
          ],
        ),
      ),
    );
  }
}
