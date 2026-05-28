import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/route_service.dart';
import '../../../domain/repositories/sala_repository.dart';

class RouteBuilderPage extends StatefulWidget {
  const RouteBuilderPage({super.key});
  @override
  State<RouteBuilderPage> createState() => _RouteBuilderPageState();
}

class _RouteBuilderPageState extends State<RouteBuilderPage> {
  List<RouteStop> _stops = [];
  bool _loading = true;
  bool _optimizing = false;
  String? _routeInfo;

  String get _salaId => AppRouter.authViewModel.currentUser?.salaId ?? '';
  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    if (_salaId.isEmpty) { setState(() => _loading = false); return; }
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      final fs = FirebaseFirestore.instance;

      // Carregar faculdades da sala
      final faculdades = await repo.getFaculdades(_salaId);

      // Carregar votos de hoje para saber quem vai
      final votesSnap = await fs.collection('salas').doc(_salaId).collection('attendance').doc(_today).collection('votes').get();
      final votes = <String, Map<String, dynamic>>{};
      for (final doc in votesSnap.docs) { votes[doc.id] = doc.data(); }

      // Carregar dados dos alunos que vão na ida (vaiEVolta ou soIda)
      final stops = <RouteStop>[];
      for (final entry in votes.entries) {
        final status = entry.value['status'] as String?;
        if (status != 'vaiEVolta' && status != 'soIda') continue;

        // Buscar dados do usuário para lat/lng
        final userDoc = await fs.collection('users').doc(entry.key).get();
        if (!userDoc.exists) continue;
        final userData = userDoc.data()!;
        final lat = (userData['latitude'] as num?)?.toDouble();
        final lng = (userData['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null || lat == 0) continue;

        stops.add(RouteStop(
          id: entry.key,
          name: userData['name'] ?? 'Aluno',
          address: '${userData['logradouro'] ?? ''}, ${userData['numero'] ?? ''}',
          lat: lat, lng: lng,
          isFaculdade: false,
        ));
      }

      // Adicionar faculdades como destinos
      for (final fac in faculdades) {
        if (fac.latitude == 0 && fac.longitude == 0) continue;
        stops.add(RouteStop(
          id: 'fac_${fac.id}',
          name: '🎓 ${fac.name}',
          address: fac.address,
          lat: fac.latitude, lng: fac.longitude,
          isFaculdade: true,
        ));
      }

      if (mounted) setState(() { _stops = stops; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      print('Error loading stops: $e');
    }
  }

  Future<void> _optimizeRoute() async {
    if (_stops.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precisa de pelo menos 3 paradas para otimizar'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() { _optimizing = true; _routeInfo = null; });

    try {
      final routeService = ServiceLocator.getIt<RouteService>();
      final waypoints = _stops.map((s) => LatLng(lat: s.lat, lng: s.lng)).toList();
      final result = await routeService.optimizeRoute(waypoints, sourceIndex: 0);

      if (result != null && mounted) {
        // Reordenar stops pela ordem otimizada
        final optimized = <RouteStop>[];
        for (final idx in result.optimizedOrder) {
          if (idx < _stops.length) optimized.add(_stops[idx]);
        }

        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
            title: const Text('Rota otimizada!'),
            content: Text('Distância: ${result.distanceText}\nTempo estimado: ${result.durationText}\n\nDeseja aceitar a rota otimizada?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Manter original')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
                child: const Text('Aceitar'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          setState(() {
            _stops = optimized;
            _routeInfo = '${result.distanceText} • ${result.durationText}';
          });
        } else {
          // Calcular rota na ordem atual pra mostrar info
          final currentRoute = await routeService.getRoute(waypoints);
          if (currentRoute != null && mounted) {
            setState(() => _routeInfo = '${currentRoute.distanceText} • ${currentRoute.durationText}');
          }
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao otimizar. Verifique se todos os endereços têm coordenadas.'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  void _startRoute() {
    if (_stops.isEmpty) return;
    Navigator.of(context).pushNamed(AppRoutes.activeRoute, arguments: _stops);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Montar Rota'),
        backgroundColor: AppTheme.white, surfaceTintColor: Colors.transparent,
        actions: [
          if (_stops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _optimizing
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : TextButton.icon(
                    onPressed: _optimizeRoute,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('Otimizar'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primary, backgroundColor: AppTheme.primaryLight,
                      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stops.isEmpty ? _buildEmptyState() : _buildRouteList(),
      bottomNavigationBar: _stops.isNotEmpty ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.alt_route_rounded, color: AppTheme.primary, size: 40)),
      const SizedBox(height: 20),
      const Text('Nenhuma parada', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 8),
      const Text('Os alunos precisam marcar presença e ter endereço com coordenadas para aparecer aqui.',
        textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5)),
    ])));
  }

  Widget _buildRouteList() {
    return Column(children: [
      if (_routeInfo != null) Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: AppTheme.radiusMd),
        child: Row(children: [
          const Icon(Icons.route_rounded, color: AppTheme.success, size: 18), const SizedBox(width: 10),
          Text(_routeInfo!, style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.infoLight, borderRadius: AppTheme.radiusMd),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 18), const SizedBox(width: 10),
          const Expanded(child: Text('Arraste para reordenar. "Otimizar" calcula o melhor percurso.', style: TextStyle(color: AppTheme.info, fontSize: 12))),
        ]),
      ),
      Expanded(child: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), itemCount: _stops.length,
        onReorder: (old, nw) { setState(() { if (old < nw) nw--; _stops.insert(nw, _stops.removeAt(old)); }); },
        itemBuilder: (_, i) {
          final stop = _stops[i];
          return Container(
            key: ValueKey(stop.id), margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(width: 36, height: 36,
                decoration: BoxDecoration(gradient: stop.isFaculdade ? AppTheme.successGradient : AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
              title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text(stop.address, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
              trailing: ReorderableDragStartListener(index: i, child: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: AppTheme.radiusMd),
                child: const Icon(Icons.drag_handle_rounded, color: AppTheme.grey400, size: 20))),
            ),
          );
        },
      )),
    ]);
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: AppTheme.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))]),
      child: Row(children: [
        Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_stops.length} paradas', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text(_routeInfo ?? 'Otimize para ver distância', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
        ])),
        ElevatedButton.icon(
          onPressed: _startRoute,
          icon: const Icon(Icons.navigation_rounded, size: 20), label: const Text('Iniciar Rota'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
        ),
      ]),
    );
  }
}

class RouteStop {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final bool isFaculdade;
  RouteStop({required this.id, required this.name, required this.address, this.lat = 0, this.lng = 0, this.isFaculdade = false});
}
