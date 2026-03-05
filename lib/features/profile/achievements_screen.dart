import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/achievement.dart';
import '../../services/achievement_service.dart';
import '../../services/auth_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = AuthService.currentUser?.id;
      List<Achievement> achievements;
      if (userId != null) {
        achievements = await AchievementService.getAchievementsWithProgress(
          userId,
        );
      } else {
        achievements = await AchievementService.getAllAchievements();
      }
      if (mounted)
        setState(() {
          _achievements = achievements;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final nearComplete = _achievements
        .where((a) => a.progress >= 0.5 && !a.isUnlocked)
        .length;
    final pctComplete = _achievements.isNotEmpty
        ? (_achievements.map((a) => a.progress).reduce((a, b) => a + b) /
                  _achievements.length *
                  100)
              .round()
        : 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Thành tích'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats summary
                Row(
                  children: [
                    _SummaryCard(value: '$unlockedCount', label: 'Huy hiệu'),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      value: '#${_achievements.length}',
                      label: 'Tổng',
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(value: '$pctComplete%', label: 'Hoàn thành'),
                  ],
                ),
                const SizedBox(height: 24),

                // Section title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Huy hiệu của bạn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Sắp đạt ($nearComplete)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Achievements grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,
                  children: _achievements.map((a) {
                    final color = _getColor(a.icon);
                    return _AchievementCard(
                      icon: _getIconData(a.icon),
                      iconColor: color,
                      gradientStart: color,
                      title: a.title,
                      description: a.description,
                      progress: a.progress,
                      progressLabel: '${(a.progress * 100).round()}%',
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  IconData _getIconData(IconType type) {
    switch (type) {
      case IconType.trophy:
        return Icons.military_tech;
      case IconType.star:
        return Icons.stars;
      case IconType.brain:
        return Icons.school;
      case IconType.lock:
        return Icons.lock;
    }
  }

  Color _getColor(IconType type) {
    switch (type) {
      case IconType.trophy:
        return AppColors.primary;
      case IconType.star:
        return const Color(0xFFD97706);
      case IconType.brain:
        return AppColors.accentGreen;
      case IconType.lock:
        return const Color(0xFFEF4444);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(25)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color gradientStart;
  final String title;
  final String description;
  final double progress;
  final String progressLabel;

  const _AchievementCard({
    required this.icon,
    required this.iconColor,
    required this.gradientStart,
    required this.title,
    required this.description,
    required this.progress,
    required this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(13)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  gradientStart.withAlpha(51),
                  gradientStart.withAlpha(13),
                ],
              ),
            ),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIẾN ĐỘ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
              Text(
                progressLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: gradientStart.withAlpha(25),
              valueColor: AlwaysStoppedAnimation(gradientStart),
            ),
          ),
        ],
      ),
    );
  }
}
