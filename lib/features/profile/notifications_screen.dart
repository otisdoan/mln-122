import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../quiz/pvp_battle_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId != null) {
        final data = await NotificationService.getNotifications(userId);
        if (mounted)
          setState(() {
            _notifications = data;
            _isLoading = false;
          });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final userId = AuthService.currentUser?.id;
    if (userId != null) {
      await NotificationService.markAllAsRead(userId);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Thông báo'),
        actions: [
          IconButton(onPressed: _markAllRead, icon: const Icon(Icons.done_all)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(child: Text('Không có thông báo'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final n = _notifications[i];
                final isRead = n['is_read'] == true;
                final isPvpInvite = n['type'] == 'pvp_invite';
                return Opacity(
                  opacity: isRead ? 0.6 : 1.0,
                  child: _NotificationItem(
                    icon: isPvpInvite
                        ? Icons.sports_esports
                        : Icons.notifications,
                    iconBg: isRead
                        ? Colors.grey.shade100
                        : isPvpInvite
                        ? Colors.deepPurple.withAlpha(25)
                        : AppColors.primary.withAlpha(25),
                    iconColor: isRead
                        ? Colors.grey.shade500
                        : isPvpInvite
                        ? Colors.deepPurple
                        : AppColors.primary,
                    title: n['title'] ?? '',
                    time: _formatTime(n['created_at']),
                    trailing: (isPvpInvite && !isRead)
                        ? ElevatedButton(
                            onPressed: () async {
                              await NotificationService.markAsRead(n['id']);
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PvpBattleScreen(roomId: n['message']),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Chấp nhận',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
                    onTap: () async {
                      if (!isRead) {
                        await NotificationService.markAsRead(n['id']);
                        _loadData();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String time;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _NotificationItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.time,
    this.onTap,
    this.trailing,
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
          border: Border.all(color: AppColors.primary.withAlpha(13)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
