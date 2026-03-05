import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/simulation_model.dart';
import '../../services/auth_service.dart';
import '../../services/simulation_service.dart';
import '../../services/user_service.dart';
import 'simulation_result_screen.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  int workers = 50;
  int machines = 12;
  int hours = 8;
  int technologyLevel = 1;
  double capitalConstant = 1200000;
  double capitalVariable = 450000;
  bool _isLoading = true;
  bool _isRunning = false;
  SimulationModel? _lastSimulation;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    final userId = AuthService.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final sim = await SimulationService.getLatest(userId);
      if (sim != null && mounted) {
        setState(() {
          workers = sim.workers;
          machines = sim.machines;
          hours = sim.workingHours;
          technologyLevel = sim.technologyLevel;
          capitalConstant = sim.capitalConstant;
          capitalVariable = sim.capitalVariable;
          _lastSimulation = sim;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _runSimulation() async {
    final userId = AuthService.currentUser?.id;
    if (userId == null) return;
    setState(() => _isRunning = true);

    // Calculate economic results
    final surplusValue =
        capitalVariable * (hours / 8.0) * technologyLevel * 0.5;
    final profit = surplusValue - (machines * 10000) + (workers * 2000);

    try {
      final sim = SimulationModel(
        id: '',
        userId: userId,
        capitalConstant: capitalConstant,
        capitalVariable: capitalVariable,
        workers: workers,
        machines: machines,
        technologyLevel: technologyLevel,
        workingHours: hours,
        profit: profit,
        surplusValue: surplusValue,
        createdAt: DateTime.now(),
      );
      final saved = await SimulationService.save(sim);

      // Grant XP for running simulation
      await UserService.addXp(userId, 25);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SimulationResultScreen(simulation: saved),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
    if (mounted) setState(() => _isRunning = false);
  }

  String _formatMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Nhà Máy Chiến Thuật')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cStr = _formatMoney(capitalConstant);
    final vStr = _formatMoney(capitalVariable);
    final surplusValue =
        capitalVariable * (hours / 8.0) * technologyLevel * 0.5;
    final mStr = _formatMoney(surplusValue);
    final prevSurplus = _lastSimulation?.surplusValue ?? surplusValue;
    final cTrend = _lastSimulation != null
        ? '${((capitalConstant - _lastSimulation!.capitalConstant) / _lastSimulation!.capitalConstant * 100).toStringAsFixed(0)}%'
        : '+0%';
    final vTrend = _lastSimulation != null
        ? '${((capitalVariable - _lastSimulation!.capitalVariable) / _lastSimulation!.capitalVariable * 100).toStringAsFixed(0)}%'
        : '+0%';
    final mTrend = prevSurplus > 0
        ? '+${((surplusValue - prevSurplus) / prevSurplus * 100).toStringAsFixed(0)}%'
        : '+0%';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu, size: 20),
          ),
        ),
        title: const Text('Nhà Máy Chiến Thuật'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, size: 20),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Key Economic Indicators (C + V + m)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _IndicatorCard(
                  label: 'Tư bản (C)',
                  value: cStr,
                  trend: cTrend,
                  trendUp: !cTrend.startsWith('-'),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                _IndicatorCard(
                  label: 'Lương (V)',
                  value: vStr,
                  trend: vTrend,
                  trendUp: !vTrend.startsWith('-'),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                _IndicatorCard(
                  label: 'Thặng dư (m)',
                  value: mStr,
                  trend: mTrend,
                  trendUp: true,
                  color: AppColors.primary,
                  isPrimary: true,
                ),
              ],
            ),
          ),

          // Factory Status Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Icon(
                      Icons.precision_manufacturing,
                      size: 64,
                      color: Colors.white.withAlpha(25),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRẠNG THÁI NHÀ MÁY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withAlpha(200),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _FactoryStatItem(
                            icon: Icons.groups,
                            label: 'Công nhân',
                            value: '$workers người',
                          ),
                          const SizedBox(width: 24),
                          _FactoryStatItem(
                            icon: Icons.precision_manufacturing,
                            label: 'Máy móc',
                            value: '$machines dàn máy',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _FactoryStatItem(
                            icon: Icons.bolt,
                            label: 'Công nghệ',
                            value: 'Cấp $technologyLevel',
                          ),
                          const SizedBox(width: 24),
                          _FactoryStatItem(
                            icon: Icons.schedule,
                            label: 'Làm việc',
                            value: '$hours giờ/ngày',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons Grid (4 buttons)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.more_time,
                    label: 'Tăng giờ làm',
                    onTap: () => setState(() {
                      hours++;
                      capitalVariable += 20000;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.person_add,
                    label: 'Thuê công nhân',
                    onTap: () => setState(() {
                      workers += 5;
                      capitalVariable += 50000;
                    }),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add_shopping_cart,
                    label: 'Mua máy móc',
                    onTap: () => setState(() {
                      machines++;
                      capitalConstant += 100000;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.upgrade,
                    label: 'Nâng cấp CN',
                    onTap: () => setState(() {
                      technologyLevel++;
                      capitalConstant += 200000;
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Production Report
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Báo cáo Sản lượng',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
                          'KỲ HIỆN TẠI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng sản phẩm:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${(workers * hours * technologyLevel * 0.6).toStringAsFixed(0)} đơn vị',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          (workers * hours * technologyLevel * 0.6) /
                          (100 * 12 * 3 * 0.6),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lợi nhuận ròng:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatMoney(
                            surplusValue -
                                (machines * 10000) +
                                (workers * 2000),
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Run simulation button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isRunning ? null : _runSimulation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isRunning
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow),
                        SizedBox(width: 8),
                        Text(
                          'Chạy Mô Phỏng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  final Color color;
  final bool isPrimary;

  const _IndicatorCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withAlpha(25)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            bottom: BorderSide(
              color: isPrimary
                  ? AppColors.primary.withAlpha(76)
                  : Colors.grey.shade300,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isPrimary ? AppColors.primary : AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  size: 12,
                  color: trendUp ? AppColors.accentGreen : AppColors.error,
                ),
                const SizedBox(width: 2),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: trendUp ? AppColors.accentGreen : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FactoryStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FactoryStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withAlpha(178),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withAlpha(51),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
