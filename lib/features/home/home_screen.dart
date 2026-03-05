import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/stat_card.dart';
import '../profile/profile_screen.dart';
import '../profile/notifications_screen.dart';
import '../home/main_navigation.dart';
import '../quiz/pvp_battle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void reload() => _loadData();

  Future<void> _loadData() async {
    try {
      final user = await AuthService.getCurrentUserProfile();
      Map<String, dynamic> stats = {};
      int unread = 0;
      if (user != null) {
        stats = await UserService.getUserStats(user.id);
        unread = await NotificationService.getUnreadCount(user.id);
      }
      if (mounted) {
        setState(() {
          _user = user;
          _stats = stats;
          _unreadCount = unread;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    final xp = user?.xp ?? 0;
    final level = user?.level ?? 1;
    final maxXp = level * 1000;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(user)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildXpSection(xp, maxXp),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.local_fire_department_rounded,
                      value: '${_stats['quizCount'] ?? 0}',
                      label: 'BÀI THI',
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.workspace_premium_rounded,
                      value: '#${_stats['bestRank'] ?? '-'}',
                      label: 'HẠNG TUẦN',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Daily challenge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDailyChallenge(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQuickActions(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              _loadData();
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withAlpha(25),
              backgroundImage: (user?.avatar != null && user!.avatar.isNotEmpty)
                  ? NetworkImage(user.avatar)
                  : null,
              child: (user?.avatar == null || user!.avatar.isEmpty)
                  ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? 'Người dùng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cấp độ ${user?.level ?? 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user?.levelTitle ?? 'Người mới',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                  _loadData();
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXpSection(int xp, int maxXp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến độ XP',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentGold,
                      ),
                      children: [
                        TextSpan(text: '$xp '),
                        TextSpan(
                          text: '/ $maxXp XP',
                          style: TextStyle(
                            fontSize: 14,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HẠNG VÀNG KIM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentGold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          XpProgressBar(currentXp: xp, maxXp: maxXp),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.track_changes, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Thử thách hôm nay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(76),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -16,
                bottom: -16,
                child: Icon(
                  Icons.trending_up,
                  size: 96,
                  color: Colors.white.withAlpha(25),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chu trình Tư bản',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hoàn thành bài học về Công thức chung của Tư bản để nhận +50 XP bonus.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tiếp tục ngay',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hành động nhanh',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.menu_book_rounded,
          title: 'Bắt đầu học',
          subtitle: 'Khám phá lý thuyết Giá trị thặng dư',
          color: AppColors.accentBlue,
          onTap: () => MainNavigation.switchTab(context, 1),
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.assignment_turned_in_rounded,
          title: 'Làm trắc nghiệm',
          subtitle: 'Kiểm tra kiến thức đã học',
          color: AppColors.accentGreen,
          onTap: () => MainNavigation.switchTab(context, 2),
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.analytics_rounded,
          title: 'Chơi mô phỏng',
          subtitle: 'Thử thách vận hành doanh nghiệp ảo',
          color: AppColors.accentGold,
          onTap: () => MainNavigation.switchTab(context, 3),
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.sports_esports_rounded,
          title: 'Thách đấu PvP',
          subtitle: 'Thi đấu trắc nghiệm với bạn bè',
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PvpBattleScreen()),
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
