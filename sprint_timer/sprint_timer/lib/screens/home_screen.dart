import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/session_service.dart';
import '../utils/app_theme.dart';
import '../widgets/connection_badge.dart';
import 'timing_screen.dart';
import 'sessions_screen.dart';
import 'athletes_screen.dart';
import 'ble_scan_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    TimingScreen(),
    SessionsScreen(),
    AthletesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionService>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _NavItem(icon: Icons.timer_outlined, label: 'Timer', selected: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                  _NavItem(icon: Icons.folder_outlined, label: 'Sessions', selected: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
                  _NavItem(icon: Icons.people_outline, label: 'Athletes', selected: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                  _NavItem(icon: Icons.settings_outlined, label: 'Settings', selected: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BleScanScreen())),
                    child: const ConnectionBadge(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppTheme.accent : AppTheme.textSecondary, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
