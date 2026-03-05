import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/lesson.dart';
import '../../services/auth_service.dart';
import '../../services/lesson_service.dart';
import 'lesson_detail_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => LearnScreenState();
}

class LearnScreenState extends State<LearnScreen> {
  List<Lesson> _lessons = [];
  Set<String> _completedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void reload() => _loadData();

  Future<void> _loadData() async {
    try {
      final lessons = await LessonService.getLessons();
      final userId = AuthService.currentUser?.id;
      Set<String> completed = {};
      if (userId != null) {
        final ids = await LessonService.getCompletedLessonIds(userId);
        completed = ids.toSet();
      }
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _completedIds = completed;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'question':
        return Icons.help_outline;
      case 'schedule':
        return Icons.schedule;
      case 'trending_up':
        return Icons.trending_up;
      case 'rocket':
        return Icons.rocket_launch;
      case 'bank':
        return Icons.account_balance;
      case 'payments':
        return Icons.payments;
      default:
        return Icons.book;
    }
  }

  Color _getIconColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.orange,
      AppColors.accentBlue,
      AppColors.purple,
      AppColors.accentGreen,
      AppColors.accentGold,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final completedCount = _completedIds.length;
    final totalCount = _lessons.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu, color: AppColors.primary),
          ),
        ),
        title: const Text('Học Kiến Thức'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const IconButton(
                onPressed: null,
                icon: Icon(Icons.search, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiến độ học tập',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn đã hoàn thành $completedCount/$totalCount bài học',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Các Bài Học Chính',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...List.generate(_lessons.length, (i) {
            final lesson = _lessons[i];
            final isCompleted = _completedIds.contains(lesson.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LessonCard(
                lesson: lesson,
                icon: _getIcon(lesson.iconName),
                color: _getIconColor(i),
                isCompleted: isCompleted,
                onTap: () async {
                  final completed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => LessonDetailScreen(
                        lesson: lesson,
                        isCompleted: isCompleted,
                      ),
                    ),
                  );
                  if (completed == true) _loadData();
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _LessonCard({
    required this.lesson,
    required this.icon,
    required this.color,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withAlpha(128)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isCompleted ? Icons.check_circle : Icons.chevron_right,
              color: isCompleted ? AppColors.accentGreen : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
