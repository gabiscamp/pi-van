import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ActiveRoutePage extends StatefulWidget {
  const ActiveRoutePage({super.key});
  @override
  State<ActiveRoutePage> createState() => _ActiveRoutePageState();
}

class _ActiveRoutePageState extends State<ActiveRoutePage> {
  bool _isSharing = false;
  int _currentStopIndex = 0;

  // TODO: Substituir por dados reais da rota salva
  final List<_NavStop> _stops = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey100,
      body: Stack(
        children: [
          // Map placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
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
                const Text('Mapa de navegação', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Aqui aparecerá o mapa com a rota traçada, sua localização em tempo real e os pontos de parada.\n\nIntegre com flutter_map + OSRM.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showExitDialog(),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: AppTheme.radiusMd,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: AppTheme.radiusMd,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: _isSharing ? AppTheme.success : AppTheme.grey300,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isSharing ? 'Compartilhando localização' : 'Localização pausada',
                              style: TextStyle(
                                color: _isSharing ? AppTheme.success : AppTheme.grey500,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),

                  // Current / next stop
                  if (_stops.isEmpty)
                    _buildNoStopsInfo()
                  else
                    _buildCurrentStopInfo(),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      // Share location toggle
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSharing = !_isSharing),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _isSharing ? AppTheme.successLight : AppTheme.grey100,
                              border: Border.all(color: _isSharing ? AppTheme.success : AppTheme.grey200),
                              borderRadius: AppTheme.radiusMd,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isSharing ? Icons.location_on_rounded : Icons.location_off_rounded,
                                  color: _isSharing ? AppTheme.success : AppTheme.grey500,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isSharing ? 'Ao vivo' : 'Iniciar',
                                  style: TextStyle(
                                    color: _isSharing ? AppTheme.success : AppTheme.grey600,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Next stop / finish
                      Expanded(
                        child: GestureDetector(
                          onTap: _stops.isEmpty ? null : () {
                            if (_currentStopIndex < _stops.length - 1) {
                              setState(() => _currentStopIndex++);
                            } else {
                              _finishRoute();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: AppTheme.radiusMd,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _stops.isNotEmpty && _currentStopIndex >= _stops.length - 1
                                      ? Icons.flag_rounded
                                      : Icons.skip_next_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _stops.isNotEmpty && _currentStopIndex >= _stops.length - 1
                                      ? 'Finalizar'
                                      : 'Próxima',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoStopsInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.infoLight, borderRadius: AppTheme.radiusMd),
      child: const Column(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 24),
          SizedBox(height: 8),
          Text(
            'Monte uma rota primeiro antes de iniciar a navegação. O mapa mostrará o percurso e as paradas em tempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.info, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStopInfo() {
    final stop = _stops[_currentStopIndex];
    return Row(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: Text('${_currentStopIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Próxima parada', style: TextStyle(color: AppTheme.grey500, fontSize: 12)),
              const SizedBox(height: 2),
              Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              Text(stop.address, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
            ],
          ),
        ),
        Column(
          children: [
            Text('${_currentStopIndex + 1}/${_stops.length}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const Text('paradas', style: TextStyle(color: AppTheme.grey500, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
        title: const Text('Encerrar navegação?'),
        content: const Text('Sua localização deixará de ser compartilhada com os alunos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Encerrar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _finishRoute() {
    setState(() => _isSharing = false);
    // TODO: Parar compartilhamento no Firestore (driverLocation.isSharing = false)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rota finalizada!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
    );
    Navigator.pop(context);
  }
}

class _NavStop {
  final String name;
  final String address;
  final double lat;
  final double lng;
  _NavStop({required this.name, required this.address, this.lat = 0, this.lng = 0});
}
