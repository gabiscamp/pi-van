import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import 'driver_dashboard_tab.dart';
import 'driver_students_tab.dart';
import 'driver_route_tab.dart';
import 'driver_profile_tab.dart';

class DriverShell extends StatefulWidget {
  final AuthViewModel viewModel;
  const DriverShell({super.key, required this.viewModel});
  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DriverDashboardTab(viewModel: widget.viewModel),
      DriverStudentsTab(viewModel: widget.viewModel),
      DriverRouteTab(viewModel: widget.viewModel),
      DriverProfileTab(viewModel: widget.viewModel),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.dashboard_rounded, 'Painel', 0),
                _navItem(Icons.people_rounded, 'Alunos', 1),
                _navItem(Icons.route_rounded, 'Rotas', 2),
                _navItem(Icons.person_rounded, 'Perfil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: AppTheme.radiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppTheme.primary : AppTheme.grey400, size: 22),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
