import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String _sortBy = 'xp';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void reload() => _loadData();

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final entries = await LeaderboardService.getLeaderboard(sortBy: _sortBy);
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('BẢNG XẾP HẠNG'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline)),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _TabChip(
                    label: 'Theo XP',
                    isActive: _sortBy == 'xp',
                    onTap: () {
                      _sortBy = 'xp';
                      _loadData();
                    },
                  ),
                  _TabChip(
                    label: 'Theo Level',
                    isActive: _sortBy == 'level',
                    onTap: () {
                      _sortBy = 'level';
                      _loadData();
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_entries.isEmpty)
            const Expanded(
              child: Center(child: Text('Chưa có dữ liệu xếp hạng')),
            )
          else ...[
            // Podium
            Container(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, AppColors.backgroundLight],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_entries.length > 1)
                    Expanded(
                      child: _PodiumItem(
                        name: _entries[1].username,
                        score: '${_entries[1].score}',
                        rank: 2,
                        avatarUrl: _entries[1].avatar,
                        avatarSize: 64,
                        podiumHeight: 96,
                        podiumColor: Colors.grey.shade200,
                        borderColor: Colors.grey.shade300,
                        crownColor: Colors.grey.shade400,
                        rankLabel: 'Hạng 2',
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PodiumItem(
                      name: _entries[0].username,
                      score: '${_entries[0].score}',
                      rank: 1,
                      avatarUrl: _entries[0].avatar,
                      avatarSize: 96,
                      podiumHeight: 128,
                      podiumColor: AppColors.primary,
                      borderColor: const Color(0xFFFBBF24),
                      crownColor: const Color(0xFFFBBF24),
                      rankLabel: 'Quán Quân',
                      isChampion: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_entries.length > 2)
                    Expanded(
                      child: _PodiumItem(
                        name: _entries[2].username,
                        score: '${_entries[2].score}',
                        rank: 3,
                        avatarUrl: _entries[2].avatar,
                        avatarSize: 64,
                        podiumHeight: 80,
                        podiumColor: const Color(0xFFFED7AA),
                        borderColor: const Color(0xFFFB923C),
                        crownColor: const Color(0xFFFB923C),
                        rankLabel: 'Hạng 3',
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),

            // Player list
            Expanded(
              child: Container(
                color: AppColors.backgroundLight,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length > 3
                      ? (_entries.length - 3).clamp(0, 7)
                      : 0,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final entry = _entries[i + 3];
                    return _PlayerRow(
                      rank: entry.rank,
                      name: entry.username,
                      avatarUrl: entry.avatar,
                      department: '',
                      score: '${entry.score}',
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _TabChip({required this.label, required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)]
                : null,
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

class _PodiumItem extends StatelessWidget {
  final String name;
  final String score;
  final int rank;
  final String avatarUrl;
  final double avatarSize;
  final double podiumHeight;
  final Color podiumColor;
  final Color borderColor;
  final Color crownColor;
  final String rankLabel;
  final bool isChampion;

  const _PodiumItem({
    required this.name,
    required this.score,
    required this.rank,
    this.avatarUrl = '',
    required this.avatarSize,
    required this.podiumHeight,
    required this.podiumColor,
    required this.borderColor,
    required this.crownColor,
    required this.rankLabel,
    this.isChampion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with crown
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 4),
                color: AppColors.primary.withAlpha(51),
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        width: avatarSize,
                        height: avatarSize,
                      )
                    : Icon(
                        Icons.person,
                        size: avatarSize * 0.5,
                        color: AppColors.primary.withAlpha(128),
                      ),
              ),
            ),
            Positioned(
              top: -20,
              child: Icon(
                isChampion ? Icons.stars : Icons.workspace_premium,
                size: isChampion ? 32 : 28,
                color: crownColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: double.infinity,
          height: podiumHeight,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(76),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isChampion ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                score,
                style: TextStyle(
                  fontSize: isChampion ? 18 : 14,
                  fontWeight: FontWeight.w800,
                  color: isChampion
                      ? const Color(0xFFFBBF24)
                      : AppColors.primary,
                ),
              ),
              Text(
                rankLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isChampion ? Colors.white70 : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final int rank;
  final String name;
  final String avatarUrl;
  final String department;
  final String score;

  const _PlayerRow({
    required this.rank,
    required this.name,
    this.avatarUrl = '',
    required this.department,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
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
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withAlpha(25),
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  department,
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'điểm',
                style: TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
