import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../learn/learn_screen.dart';
import '../quiz/quiz_selection_screen.dart';
import '../simulation/simulation_screen.dart';
import '../leaderboard/leaderboard_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _learnKey = GlobalKey<LearnScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      LearnScreen(key: _learnKey),
      const QuizSelectionScreen(),
      const SimulationScreen(),
      const LeaderboardScreen(),
    ];
  }

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) _homeKey.currentState?.reload();
    if (index == 1) _learnKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}
