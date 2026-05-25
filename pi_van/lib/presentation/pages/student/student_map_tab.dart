import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';

class StudentMapTab extends StatelessWidget {
  final AuthViewModel viewModel;
  const StudentMapTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: AppTheme.white,
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: AppTheme.radiusMd),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Localização da Van', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('Acompanhe em tempo real', style: TextStyle(color: AppTheme.grey500, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            // Map area
            Expanded(
              child: Stack(
                children: [
                  // Placeholder para o flutter_map
                  Container(
                    width: double.infinity,
                    color: AppTheme.grey100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
                          child: const Icon(Icons.map_outlined, color: AppTheme.primary, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text('Mapa em tempo real', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 48),
                          child: Text(
                            'Aqui você verá a localização da van quando o motorista iniciar uma rota.\n\nIntegre com flutter_map + OpenStreetMap.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom info card
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: AppTheme.radiusXl,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.grey100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.directions_bus_rounded, color: AppTheme.grey400, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Motorista offline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                SizedBox(height: 2),
                                Text('Aguardando início da rota', style: TextStyle(color: AppTheme.grey500, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: AppTheme.grey300, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
