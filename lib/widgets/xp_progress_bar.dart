import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final int maxXp;
  final double height;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.maxXp,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxXp > 0 ? currentXp / maxXp : 0.0;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentGold, Color(0xFFF59E0B)],
            ),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
