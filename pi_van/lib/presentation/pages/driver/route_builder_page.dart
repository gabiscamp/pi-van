import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/active_route_args.dart';
import '../../../core/services/route_service.dart';
import '../../../domain/entities/attendance.dart';
import '../../../domain/entities/route_stop_entity.dart';
import '../../../domain/enums/attendance_status.dart';
import '../../../domain/enums/route_type.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../../domain/usecases/route_builder_service.dart';

class RouteBuilderPage extends StatefulWidget {
  const RouteBuilderPage({super.key});
  @override
  State<RouteBuilderPage> createState() => _RouteBuilderPageState();
}

class _RouteBuilderPageState extends State<RouteBuilderPage> {
  RouteType _type = RouteType.ida;
  List<RouteStopEntity> _stops = [];
  // Ordem canônica construída pelo servidor — nunca alterada por drag ou otimização.
  // Usada como base para o TSP, garantindo que "Otimizar" sempre encontra o melhor caminho.
  List<RouteStopEntity> _originalStops = [];
  bool _loading = true;
  bool _optimizing = false;
  String? _routeInfo;

  String get _salaId => AppRouter.authViewModel.currentUser?.salaId ?? '';
  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RouteType && args != _type) {
      _type = args;
    }
    if (_loading) _loadStops();
  }

  Future<void> _loadStops() async {
    if (_salaId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() { _loading = true; _routeInfo = null; });
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      final builder = ServiceLocator.getIt<RouteBuilderService>();

      final faculdades = await repo.getFaculdades(_salaId);
      final votes = await repo.getAttendance(salaId: _salaId, date: _today);

      // Converte votos do dia em inputs para o builder.
      final inputs = <RoutePassengerInput>[];
      votes.forEach((userId, raw) {
        final data = (raw as Map).cast<String, dynamic>();
        final statusStr = data['status'] as String?;
        if (statusStr == null) return;
        final status = AttendanceStatus.values.firstWhere(
          (e) => e.name == statusStr, orElse: () => AttendanceStatus.pendente,
        );
        if (status == AttendanceStatus.pendente || status == AttendanceStatus.naoVai) return;

        // Rota de volta: só inclui alunos que já marcaram "Estou liberado"
        if (_type == RouteType.volta) {
          final liberado = data['liberado'] as bool? ?? false;
          if (!liberado) return;
        }

        inputs.add(RoutePassengerInput(
          userId: userId,
          name: data['userName'] as String? ?? 'Aluno',
          status: status,
          faculdadeId: data['faculdadeId'] as String?,
          faculdadeName: data['faculdadeName'] as String?,
          boarding: AddressRef.fromMap((data['boarding'] as Map?)?.cast<String, dynamic>()),
          dropoff: AddressRef.fromMap((data['dropoff'] as Map?)?.cast<String, dynamic>()),
        ));
      });

      final stops = builder.buildStops(type: _type, passengers: inputs, faculdades: faculdades);

      if (mounted) {
        setState(() {
          _stops = stops;
          _originalStops = List.from(stops);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('Error loading stops: $e');
    }
  }

  /// Otimiza apenas dentro de cada fase (embarques / faculdades para ida;
  /// faculdades / desembarques para volta), preservando a prioridade da rota.
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

      // Usa sempre a ordem original do servidor como base para o TSP.
      final base = _originalStops.isNotEmpty ? _originalStops : _stops;

      // Divide em duas fases pela ordem natural construída pelo builder.
      // Ida:   [pickups...] + [faculdades...]
      // Volta: [faculdades...] + [dropoffs...]
      final firstPhase = base.where((s) =>
          _type == RouteType.ida ? !s.isFaculdade : s.isFaculdade).toList();
      final secondPhase = base.where((s) =>
          _type == RouteType.ida ? s.isFaculdade : !s.isFaculdade).toList();

      // Tenta obter localização atual para iniciar pela parada mais próxima.
      Position? currentPos;
      try {
        currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}

      // Move a parada mais próxima ao motorista para o início da 1ª fase.
      if (currentPos != null && firstPhase.length > 1) {
        var nearestIdx = 0;
        var nearestDist = double.infinity;
        for (var i = 0; i < firstPhase.length; i++) {
          final d = RouteService.haversineDistance(
            currentPos.latitude, currentPos.longitude,
            firstPhase[i].latitude, firstPhase[i].longitude,
          );
          if (d < nearestDist) { nearestDist = d; nearestIdx = i; }
        }
        if (nearestIdx != 0) {
          firstPhase.insert(0, firstPhase.removeAt(nearestIdx));
        }
      }

      final optimizedFirst = await _optimizePhase(routeService, firstPhase);
      final optimizedSecond = await _optimizePhase(routeService, secondPhase);
      final optimized = [...optimizedFirst, ...optimizedSecond];

      // Calcula info total da rota otimizada.
      final waypoints = optimized.map((s) => LatLng(lat: s.latitude, lng: s.longitude)).toList();
      final route = await routeService.getRoute(waypoints);

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
          title: const Text('Rota otimizada!'),
          content: Text(route != null
              ? 'Distância: ${route.distanceText}\nTempo estimado: ${route.durationText}\n\nDeseja aplicar a ordem otimizada?'
              : 'Ordem das paradas otimizada dentro de cada fase. Deseja aplicar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Manter')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          _stops = optimized;
          if (route != null) _routeInfo = '${route.distanceText} • ${route.durationText}';
        });
      } else if (route != null) {
        setState(() => _routeInfo = '${route.distanceText} • ${route.durationText}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao otimizar: $e'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  Future<List<RouteStopEntity>> _optimizePhase(RouteService service, List<RouteStopEntity> phase) async {
    if (phase.length < 3) return phase; // TSP exige 3+ pontos
    final waypoints = phase.map((s) => LatLng(lat: s.latitude, lng: s.longitude)).toList();
    final result = await service.optimizeRoute(waypoints, sourceIndex: 0);
    if (result == null) return phase;
    // result.optimizedOrder[i] = posição no trajeto do waypoint de entrada i.
    // Ordena os índices de entrada pela posição no trajeto para reconstruir
    // a sequência correta (abordagem correta para qualquer permutação).
    final indices = List.generate(phase.length, (i) => i);
    indices.sort((a, b) => result.optimizedOrder[a].compareTo(result.optimizedOrder[b]));
    final reordered = indices.map((i) => phase[i]).toList();
    return reordered.length == phase.length ? reordered : phase;
  }

  void _startRoute() {
    if (_stops.isEmpty) return;
    Navigator.of(context).pushNamed(
      AppRoutes.activeRoute,
      arguments: ActiveRouteArgs(type: _type, stops: _stops),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Montar ${_type.label}'),
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
      body: Column(children: [
        _buildTypeSwitch(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _stops.isEmpty ? _buildEmptyState() : _buildRouteList()),
      ]),
      bottomNavigationBar: _stops.isNotEmpty ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildTypeSwitch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: AppTheme.radiusMd),
      child: Row(children: RouteType.values.map((t) {
        final selected = _type == t;
        return Expanded(child: GestureDetector(
          onTap: () { if (!selected) { setState(() { _type = t; _loading = true; }); _loadStops(); } },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: selected ? AppTheme.white : Colors.transparent, borderRadius: AppTheme.radiusMd,
              boxShadow: selected ? AppTheme.cardShadow : null),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(t == RouteType.ida ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                size: 16, color: selected ? AppTheme.primary : AppTheme.grey500),
              const SizedBox(width: 6),
              Text(t.shortLabel, style: TextStyle(color: selected ? AppTheme.primary : AppTheme.grey500, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ));
      }).toList()),
    );
  }

  Widget _buildEmptyState() {
    final hint = _type == RouteType.ida
        ? 'Nenhum aluno marcou ida hoje (com endereço de embarque e coordenadas).'
        : 'Nenhum aluno está liberado ainda. A rota de volta só é montada com alunos que marcaram "Estou liberado" no app.';
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.alt_route_rounded, color: AppTheme.primary, size: 40)),
      const SizedBox(height: 20),
      const Text('Nenhuma parada', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 8),
      Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5)),
    ])));
  }

  Widget _buildRouteList() {
    return Column(children: [
      if (_routeInfo != null) Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0), padding: const EdgeInsets.all(14),
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
          Expanded(child: Text(
            _type == RouteType.ida
                ? 'Primeiro busca os alunos, depois entrega nas faculdades. Arraste para reordenar.'
                : 'Primeiro passa nas faculdades, depois leva os alunos para casa. Arraste para reordenar.',
            style: const TextStyle(color: AppTheme.info, fontSize: 12))),
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
                child: Center(child: stop.isFaculdade
                  ? const Icon(Icons.school_rounded, color: Colors.white, size: 18)
                  : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
              title: Text(_titleFor(stop), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text(_subtitleFor(stop), style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
              trailing: ReorderableDragStartListener(index: i, child: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: AppTheme.radiusMd),
                child: const Icon(Icons.drag_handle_rounded, color: AppTheme.grey400, size: 20))),
            ),
          );
        },
      )),
    ]);
  }

  String _titleFor(RouteStopEntity stop) {
    if (stop.isFaculdade) return '🎓 ${stop.name}';
    final verb = stop.isPickup ? 'Buscar' : 'Deixar';
    return '$verb ${stop.name}';
  }

  String _subtitleFor(RouteStopEntity stop) {
    if (stop.isFaculdade) {
      final n = stop.passengers.length;
      return '$n aluno${n == 1 ? '' : 's'} • ${stop.address}';
    }
    final parts = <String>[
      if (stop.addressLabel != null) stop.addressLabel!,
      if (stop.address.isNotEmpty) stop.address,
    ];
    final base = parts.join(' · ');
    return stop.faculdadeName != null && stop.faculdadeName!.isNotEmpty ? '$base → ${stop.faculdadeName}' : base;
  }

  Widget _buildBottomBar(BuildContext context) {
    final alunos = _stops.fold<int>(0, (sum, s) => sum + s.passengerCount);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: AppTheme.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))]),
      child: Row(children: [
        Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_stops.length} paradas • $alunos alunos', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text(_routeInfo ?? 'Otimize para ver distância', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
        ])),
        ElevatedButton.icon(
          onPressed: _startRoute,
          icon: const Icon(Icons.navigation_rounded, size: 20), label: const Text('Iniciar'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
        ),
      ]),
    );
  }
}
