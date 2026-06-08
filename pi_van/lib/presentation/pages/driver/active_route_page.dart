import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/active_route_args.dart';
import '../../../core/services/external_nav_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/route_service.dart' as rs;
import '../../../domain/entities/attendance.dart';
import '../../../domain/entities/faculdade.dart';
import '../../../domain/entities/route_stop_entity.dart';
import '../../../domain/enums/attendance_status.dart';
import '../../../domain/enums/route_type.dart';
import '../../../domain/enums/stop_status.dart';
import '../../../domain/repositories/sala_repository.dart';

/// Tela de navegação ativa.
///
/// - Avança automaticamente quando o motorista entra no raio de chegada (300 m).
/// - Mapa gira na direção do deslocamento, com instrução de curva no topo.
/// - Volta: escuta liberações em tempo real e recalcula a rota automaticamente.
/// - Faculdade (volta): aguarda todos os alunos liberados antes de abrir o modal.
/// - Navegar: abre Google Maps ou Waze com todas as paradas pendentes.
class ActiveRoutePage extends StatefulWidget {
  const ActiveRoutePage({super.key});
  @override
  State<ActiveRoutePage> createState() => _ActiveRoutePageState();
}

class _ActiveRoutePageState extends State<ActiveRoutePage> {
  final MapController _mapController = MapController();

  static const double _arrivalRadiusMeters = 300;

  RouteType _type = RouteType.ida;
  List<RouteStopEntity> _stops = [];
  List<LatLng> _routePoints = [];
  LatLng? _currentPosition;
  bool _isSharing = false;

  // === Navegação turn-by-turn ===
  List<rs.RouteStep> _steps = [];
  int _nextStepIdx = 0;
  double _distToNextStep = 0;
  bool _followHeading = true; // mapa gira com a direção do motorista

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<Map<String, dynamic>>? _attendanceSub;
  Timer? _shareTimer;

  String _routeInfo = '';
  String? _nextEta;
  String? _nextDistance;

  // === Estado da rota de volta ===
  final DateTime _sessionStart = DateTime.now();
  Map<String, Faculdade> _faculdadesCache = {};
  final Map<String, Set<String>> _facVaiVoltaStudents = {};
  final Set<String> _liberadoUserIds = {};
  RouteStopEntity? _pendingFaculdadeArrival;

  String get _salaId => AppRouter.authViewModel.currentUser?.salaId ?? '';
  static const _defaultCenter = LatLng(-19.9167, -43.9345);

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get _currentIndex {
    final i = _stops.indexWhere((s) => !s.status.isResolved);
    return i < 0 ? _stops.length : i;
  }

  RouteStopEntity? get _currentStop {
    final i = _currentIndex;
    return i < _stops.length ? _stops[i] : null;
  }

  bool get _finished => _currentStop == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ActiveRouteArgs) {
        setState(() {
          _type = args.type;
          _stops = args.stops.map((s) => s.copyWith(status: StopStatus.aguardando)).toList();
          if (_stops.isNotEmpty) {
            _stops[0] = _stops[0].copyWith(status: StopStatus.emAndamento);
          }
        });
        _calculateRoute();
        if (_type == RouteType.volta) _initVoltaListener();
      }
      _startSharing();
    });
  }

  @override
  void dispose() {
    _stopSharing();
    _positionSub?.cancel();
    _shareTimer?.cancel();
    _attendanceSub?.cancel();
    super.dispose();
  }

  // ===== Rota =====
  Future<void> _calculateRoute() async {
    final pending = _stops.where((s) => !s.status.isResolved).toList();
    if (pending.isEmpty) {
      if (mounted) setState(() => _routePoints = []);
      return;
    }
    try {
      final routeService = ServiceLocator.getIt<rs.RouteService>();
      final waypoints = [
        if (_currentPosition != null)
          rs.LatLng(lat: _currentPosition!.latitude, lng: _currentPosition!.longitude),
        ...pending.map((s) => rs.LatLng(lat: s.latitude, lng: s.longitude)),
      ];
      if (waypoints.length < 2) {
        if (mounted) setState(() => _routePoints = []);
        return;
      }
      final result = await routeService.getRoute(waypoints);
      if (result != null && mounted) {
        // Encontra o primeiro step que não é "depart" para exibição
        final firstMeaningfulStep = result.steps.indexWhere((s) => s.maneuverType != 'depart');
        setState(() {
          _routePoints = result.points.map((p) => LatLng(p.lat, p.lng)).toList();
          _routeInfo = '${result.distanceText} • ${result.durationText}';
          _steps = result.steps;
          _nextStepIdx = firstMeaningfulStep >= 0 ? firstMeaningfulStep : 0;
          _distToNextStep = 0;
        });
        if (_routePoints.isNotEmpty && !_isSharing) {
          _mapController.fitCamera(
            CameraFit.coordinates(coordinates: _routePoints, padding: const EdgeInsets.all(60)),
          );
        }
      }
    } catch (e) {
      debugPrint('Route calc error: $e');
    }
  }

  // ===== Listener de liberações (somente rota de volta) =====
  Future<void> _initVoltaListener() async {
    if (_salaId.isEmpty) return;
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      final facs = await repo.getFaculdades(_salaId);
      _faculdadesCache = {for (final f in facs) f.id: f};

      final allVotes = await repo.getAttendance(salaId: _salaId, date: _today);
      for (final entry in allVotes.entries) {
        final userId = entry.key;
        final data = (entry.value as Map).cast<String, dynamic>();
        final statusStr = data['status'] as String?;
        if (statusStr == null) continue;
        final status = AttendanceStatus.values.firstWhere(
          (e) => e.name == statusStr, orElse: () => AttendanceStatus.pendente,
        );
        final vaiVolta =
            status == AttendanceStatus.vaiEVolta || status == AttendanceStatus.soVolta;
        if (!vaiVolta) continue;
        final facId = data['faculdadeId'] as String?;
        if (facId != null && facId.isNotEmpty) {
          _facVaiVoltaStudents.putIfAbsent(facId, () => {}).add(userId);
        }
        if (data['liberado'] as bool? ?? false) _liberadoUserIds.add(userId);
      }

      _attendanceSub = repo
          .attendanceStream(salaId: _salaId, date: _today)
          .listen(_onAttendanceUpdate);
    } catch (e) {
      debugPrint('Erro ao iniciar listener de liberações: $e');
    }
  }

  void _onAttendanceUpdate(Map<String, dynamic> attendance) {
    for (final entry in attendance.entries) {
      final userId = entry.key;
      final data = (entry.value as Map).cast<String, dynamic>();
      if (!(data['liberado'] as bool? ?? false)) continue;
      if (_liberadoUserIds.contains(userId)) continue;

      _liberadoUserIds.add(userId);
      final nome = data['userName'] as String? ?? 'Aluno';
      final facId = data['faculdadeId'] as String?;
      final facNome = data['faculdadeName'] as String?;

      // Só notifica se o aluno foi liberado nesta sessão de rota
      final liberadoAt = data['liberadoAt'] as String?;
      final liberadoTime = liberadoAt != null ? DateTime.tryParse(liberadoAt) : null;
      if (liberadoTime != null && liberadoTime.isAfter(_sessionStart)) {
        NotificationService.showLiberado(userId, nome, facNome);
      }
      _addStudentToRoute(userId, nome, data);

      if (_pendingFaculdadeArrival != null && facId != null) {
        final pendingFacId = _pendingFaculdadeArrival!.id.replaceFirst('fac_', '');
        if (pendingFacId == facId) {
          final needed = _facVaiVoltaStudents[facId] ?? {};
          if (needed.every((uid) => _liberadoUserIds.contains(uid)) && !_confirmSheetOpen) {
            final pendingStop = _pendingFaculdadeArrival!;
            _pendingFaculdadeArrival = null;
            WidgetsBinding.instance.addPostFrameCallback((_) => _onArrivedAtStop(pendingStop));
          }
        }
      }
    }
  }

  void _addStudentToRoute(String userId, String nome, Map<String, dynamic> data) {
    final dropoffId = 'dropoff_$userId';
    if (_stops.any((s) => s.id == dropoffId)) return;

    final facId = data['faculdadeId'] as String?;
    final facNome = data['faculdadeName'] as String?;
    final dropoff = AddressRef.fromMap((data['dropoff'] as Map?)?.cast<String, dynamic>());
    final newPassenger = StopPassenger(userId: userId, name: nome, faculdadeName: facNome);
    final facStopsToAdd = <RouteStopEntity>[];

    if (facId != null && facId.isNotEmpty && _faculdadesCache.containsKey(facId)) {
      final fac = _faculdadesCache[facId]!;
      final facStopId = 'fac_$facId';
      final existingIdx = _stops.indexWhere((s) => s.id == facStopId);
      if (existingIdx >= 0) {
        final existing = _stops[existingIdx];
        if (!existing.passengers.any((p) => p.userId == userId) && !existing.status.isResolved) {
          setState(() {
            _stops[existingIdx] = existing.copyWith(
              passengers: [...existing.passengers, newPassenger],
            );
          });
        }
      } else {
        facStopsToAdd.add(RouteStopEntity(
          id: facStopId, kind: RouteStopKind.faculdade,
          name: fac.name, address: fac.address,
          latitude: fac.latitude, longitude: fac.longitude,
          passengers: [newPassenger], status: StopStatus.aguardando,
        ));
      }
    }

    final dropoffStop = (dropoff != null && dropoff.hasCoordinates)
        ? RouteStopEntity(
            id: dropoffId, kind: RouteStopKind.desembarqueAluno,
            name: nome, address: dropoff.shortAddress,
            latitude: dropoff.latitude!, longitude: dropoff.longitude!,
            faculdadeName: facNome, addressLabel: dropoff.label,
            status: StopStatus.aguardando,
          )
        : null;

    if (facStopsToAdd.isEmpty && dropoffStop == null) return;

    setState(() {
      if (facStopsToAdd.isNotEmpty) {
        final firstDropoffIdx =
            _stops.indexWhere((s) => !s.isFaculdade && !s.status.isResolved);
        if (firstDropoffIdx >= 0) {
          _stops.insertAll(firstDropoffIdx, facStopsToAdd);
        } else {
          _stops.addAll(facStopsToAdd);
        }
      }
      if (dropoffStop != null) _stops.add(dropoffStop);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('$nome liberado! Rota atualizada.',
              style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Navegar', textColor: Colors.white, onPressed: _openExternalNav),
      ));
    }
    _calculateRoute();
  }

  // ===== GPS / compartilhamento =====
  Future<void> _startSharing() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permissão de localização negada — automação por GPS indisponível'),
            backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating));
        }
        return;
      }
    }
    setState(() => _isSharing = true);
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((position) {
      if (!mounted) return;
      final pos = LatLng(position.latitude, position.longitude);
      setState(() => _currentPosition = pos);

      // Segue o motorista e rotaciona o mapa na direção do movimento
      if (_followHeading && position.heading >= 0) {
        _mapController.move(pos, _mapController.camera.zoom);
        _mapController.rotate(position.heading);
      } else {
        _mapController.move(pos, _mapController.camera.zoom);
      }

      _onLocationUpdate(position.latitude, position.longitude);
    });
    _shareTimer = Timer.periodic(const Duration(seconds: 10), (_) => _shareLocation());
    _shareLocation();
  }

  void _onLocationUpdate(double lat, double lng) {
    final stop = _currentStop;
    if (stop == null) return;

    final dist = rs.RouteService.haversineDistance(lat, lng, stop.latitude, stop.longitude);
    _updateNextEstimate(dist);
    _updateStepProgress(lat, lng);

    if (dist <= _arrivalRadiusMeters) _onArrivedAtStop(stop);
  }

  void _updateNextEstimate(double straightDist) {
    final approxText = straightDist >= 1000
        ? '${(straightDist / 1000).toStringAsFixed(1)} km'
        : '${straightDist.round()} m';
    final etaMin = (straightDist / 6.1 / 60).ceil();
    final etaText = etaMin <= 1 ? 'chegando' : '~$etaMin min';
    if (mounted) setState(() { _nextDistance = approxText; _nextEta = etaText; });
  }

  /// Avança o índice do passo de instrução conforme o motorista se move.
  void _updateStepProgress(double lat, double lng) {
    if (_steps.isEmpty || _nextStepIdx >= _steps.length) return;

    // Avança enquanto o motorista já passou pelo ponto de manobra
    while (_nextStepIdx < _steps.length - 1) {
      final step = _steps[_nextStepIdx];
      final dist = rs.RouteService.haversineDistance(lat, lng, step.lat, step.lng);
      if (dist < 35) {
        setState(() => _nextStepIdx++);
      } else {
        if (mounted) setState(() => _distToNextStep = dist);
        return;
      }
    }
    // Atualiza distância para o passo atual
    if (_nextStepIdx < _steps.length) {
      final step = _steps[_nextStepIdx];
      final dist = rs.RouteService.haversineDistance(lat, lng, step.lat, step.lng);
      if (mounted) setState(() => _distToNextStep = dist);
    }
  }

  Future<void> _shareLocation() async {
    if (!_isSharing || _currentPosition == null || _salaId.isEmpty) return;
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      await repo.updateDriverLocation(
        salaId: _salaId, lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude, isSharing: true);
    } catch (_) {}
  }

  Future<void> _stopSharing() async {
    _positionSub?.cancel();
    _shareTimer?.cancel();
    if (_salaId.isNotEmpty) {
      try {
        final repo = ServiceLocator.getIt<SalaRepository>();
        await repo.updateDriverLocation(salaId: _salaId, lat: 0, lng: 0, isSharing: false);
      } catch (_) {}
    }
    if (mounted) setState(() => _isSharing = false);
  }

  // ===== Chegada / confirmação =====
  bool _confirmSheetOpen = false;

  Future<void> _onArrivedAtStop(RouteStopEntity stop) async {
    if (_confirmSheetOpen) return;

    // Volta + faculdade: aguarda todos os alunos estarem liberados
    if (_type == RouteType.volta && stop.isFaculdade) {
      final facId = stop.id.replaceFirst('fac_', '');
      final needed = _facVaiVoltaStudents[facId] ?? {};
      if (needed.isNotEmpty) {
        final pendingCount = needed.where((uid) => !_liberadoUserIds.contains(uid)).length;
        if (pendingCount > 0) {
          // Já estamos aguardando nesta mesma faculdade — não repetir o snackbar
          if (_pendingFaculdadeArrival?.id == stop.id) return;
          _pendingFaculdadeArrival = stop;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Aguardando $pendingCount aluno${pendingCount > 1 ? 's' : ''} em ${stop.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
              backgroundColor: AppTheme.warning, behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
            ));
          }
          return;
        }
      }
    }

    _confirmSheetOpen = true;
    await _showConfirmSheet(stop, auto: true);
    _confirmSheetOpen = false;
  }

  Future<void> _showConfirmSheet(RouteStopEntity stop, {bool auto = false}) async {
    final isEmbarque = _type == RouteType.ida ? !stop.isFaculdade : stop.isFaculdade;
    final result = await showModalBottomSheet<StopStatus>(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent, isDismissible: !auto,
      builder: (_) => _ConfirmStopSheet(stop: stop, isEmbarque: isEmbarque, auto: auto),
    );
    if (result != null) _applyStopStatus(stop, result);
  }

  void _applyStopStatus(RouteStopEntity stop, StopStatus status) {
    final idx = _stops.indexWhere((s) => s.id == stop.id);
    if (idx < 0) return;
    setState(() {
      _stops[idx] = _stops[idx].copyWith(status: status);
      final next = _stops.indexWhere((s) => !s.status.isResolved);
      if (next >= 0 && _stops[next].status == StopStatus.aguardando) {
        _stops[next] = _stops[next].copyWith(status: StopStatus.emAndamento);
      }
      _nextDistance = null; _nextEta = null;
    });
    _calculateRoute();
    if (_finished) _finishRoute();
  }

  Future<void> _recalculate() async {
    await _calculateRoute();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rota recalculada'), backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
    }
  }

  void _openExternalNav() {
    final pending = _stops.where((s) => !s.status.isResolved).toList();
    if (pending.isEmpty) return;
    final waypoints = pending.map((s) => (s.latitude, s.longitude)).toList();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _NavChoiceSheet(waypoints: waypoints),
    );
  }

  // ===== Indicadores =====
  int get _totalConfirmed {
    final ids = <String>{};
    for (final s in _stops) {
      if (s.isFaculdade) {
        for (final p in s.passengers) { ids.add(p.userId); }
      } else {
        ids.add(s.id);
      }
    }
    return ids.length;
  }

  int get _doneCount => _stops.where((s) => s.status == StopStatus.concluida).length;
  int get _absentCount => _stops.where((s) => s.status == StopStatus.ausente).length;
  int get _remainingCount => _stops.where((s) => !s.status.isResolved).length;

  int get _transportedStudents {
    int n = 0;
    for (final s in _stops.where((s) => s.status == StopStatus.concluida)) {
      n += s.passengerCount;
    }
    return n;
  }

  // ===== Build =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        _buildMap(),
        _buildManeuverBanner(),
        _buildTopBar(),
        _buildBottomPanel(),
      ]),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _stops.isNotEmpty
            ? LatLng(_stops.first.latitude, _stops.first.longitude)
            : _defaultCenter,
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.vango.app',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(points: _routePoints, color: AppTheme.primary, strokeWidth: 5),
          ]),
        MarkerLayer(markers: [
          ..._stops.asMap().entries.map((e) {
            final i = e.key; final s = e.value;
            final isNext = i == _currentIndex;
            return Marker(
              point: LatLng(s.latitude, s.longitude), width: 46, height: 46,
              child: Container(
                decoration: BoxDecoration(
                  color: _markerColor(s, isNext), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: isNext
                      ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 10)]
                      : null,
                ),
                child: Center(child: s.isFaculdade
                    ? const Icon(Icons.school_rounded, color: Colors.white, size: 18)
                    : Icon(s.isPickup ? Icons.person_rounded : Icons.home_rounded,
                        color: Colors.white, size: 18)),
              ),
            );
          }),
          if (_currentPosition != null)
            Marker(
              point: _currentPosition!, width: 50, height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)],
                ),
                child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 28),
              ),
            ),
        ]),
      ],
    );
  }

  Color _markerColor(RouteStopEntity s, bool isNext) {
    switch (s.status) {
      case StopStatus.concluida:   return AppTheme.success;
      case StopStatus.ausente:     return AppTheme.warning;
      case StopStatus.cancelada:   return AppTheme.grey400;
      case StopStatus.emAndamento: return isNext ? AppTheme.primary : AppTheme.accent;
      case StopStatus.aguardando:  return isNext ? AppTheme.primary : (s.isFaculdade ? AppTheme.accent : AppTheme.grey500);
    }
  }

  /// Banner de instrução de curva — aparece no topo quando há uma manobra próxima.
  Widget _buildManeuverBanner() {
    if (_steps.isEmpty || _nextStepIdx >= _steps.length) return const SizedBox.shrink();
    final step = _steps[_nextStepIdx];
    if (step.maneuverType == 'depart' || step.maneuverType == 'arrive') {
      return const SizedBox.shrink();
    }

    final distText = _distToNextStep >= 1000
        ? '${(_distToNextStep / 1000).toStringAsFixed(1)} km'
        : '${_distToNextStep.round()} m';

    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: AppTheme.radiusMd,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(children: [
              Icon(_stepIcon(step.maneuverType, step.maneuverModifier),
                  color: Colors.white, size: 36),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Em $distText',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(step.instruction,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                if (step.streetName.isNotEmpty)
                  Text(step.streetName,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
        ),
      ),
    );
  }

  static IconData _stepIcon(String type, String? modifier) {
    if (type == 'arrive')                              return Icons.flag_rounded;
    if (type == 'roundabout' || type == 'rotary')     return Icons.roundabout_right_rounded;
    if (type == 'on ramp' || type == 'off ramp')      return Icons.merge_rounded;
    switch (modifier) {
      case 'left':
      case 'sharp left':   return Icons.turn_left_rounded;
      case 'right':
      case 'sharp right':  return Icons.turn_right_rounded;
      case 'slight left':  return Icons.turn_slight_left_rounded;
      case 'slight right': return Icons.turn_slight_right_rounded;
      default:             return Icons.straight_rounded;
    }
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          // Deixa espaço para o banner de manobra quando ele existe
          padding: EdgeInsets.fromLTRB(16, _hasManeuvBanner ? 80 : 8, 16, 8),
          child: Row(children: [
            _iconBtn(Icons.arrow_back_rounded, _showExitDialog),
            const SizedBox(width: 8),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, boxShadow: AppTheme.cardShadow),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(
                  color: _isSharing ? AppTheme.success : AppTheme.grey300, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _isSharing ? '${_type.shortLabel} • GPS ativo' : '${_type.shortLabel} • GPS pausado',
                  style: TextStyle(color: _isSharing ? AppTheme.success : AppTheme.grey500,
                      fontWeight: FontWeight.w600, fontSize: 12))),
                if (_routeInfo.isNotEmpty)
                  Text(_routeInfo, style: const TextStyle(color: AppTheme.grey500, fontSize: 10)),
              ]),
            )),
            const SizedBox(width: 8),
            // Botão bússola: ativa/desativa rotação com direção
            _iconBtn(
              _followHeading ? Icons.explore_rounded : Icons.explore_off_rounded,
              () {
                setState(() {
                  _followHeading = !_followHeading;
                  if (!_followHeading) _mapController.rotate(0);
                });
              },
              color: _followHeading ? AppTheme.primary : AppTheme.grey400,
            ),
            const SizedBox(width: 8),
            _iconBtn(Icons.refresh_rounded, _recalculate, color: AppTheme.primary),
          ]),
        ),
      ),
    );
  }

  bool get _hasManeuvBanner =>
      _steps.isNotEmpty &&
      _nextStepIdx < _steps.length &&
      _steps[_nextStepIdx].maneuverType != 'depart' &&
      _steps[_nextStepIdx].maneuverType != 'arrive';

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, boxShadow: AppTheme.cardShadow),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, -4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          _buildIndicators(),
          const SizedBox(height: 14),
          if (_finished) _buildFinishedCard() else _buildNextStopCard(),
        ]),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(children: [
      _indicator(Icons.people_rounded, '$_transportedStudents/$_totalConfirmed', 'Transportados', AppTheme.primary),
      _indicator(Icons.check_circle_rounded, '$_doneCount', 'Concluídas', AppTheme.success),
      _indicator(Icons.pending_actions_rounded, '$_remainingCount', 'Restantes', AppTheme.info),
      _indicator(Icons.person_off_rounded, '$_absentCount', 'Ausentes', AppTheme.warning),
    ]);
  }

  Widget _indicator(IconData icon, String value, String label, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: const TextStyle(color: AppTheme.grey500, fontSize: 10), textAlign: TextAlign.center),
    ]));
  }

  Widget _buildNextStopCard() {
    final stop = _currentStop!;
    final isFac = stop.isFaculdade;
    final isWaiting = _pendingFaculdadeArrival?.id == stop.id;

    final subtitle = isFac
        ? '${stop.passengerCount} aluno${stop.passengerCount == 1 ? '' : 's'} '
            '${_type == RouteType.ida ? 'desembarcam' : 'embarcam'} aqui'
        : [if (stop.addressLabel != null) stop.addressLabel!, if (stop.address.isNotEmpty) stop.address].join(' · ');

    return Column(children: [
      Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: isFac ? AppTheme.successGradient : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16)),
          child: Center(child: Icon(
            isFac ? Icons.school_rounded : (stop.isPickup ? Icons.person_rounded : Icons.home_rounded),
            color: Colors.white, size: 26)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Próxima parada', style: TextStyle(color: AppTheme.grey500, fontSize: 12)),
            if (isWaiting) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.warningLight, borderRadius: BorderRadius.circular(6)),
                child: const Text('Aguardando', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (_nextDistance != null) Text(_nextDistance!,
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 16)),
          if (_nextEta != null) Text(_nextEta!,
              style: const TextStyle(color: AppTheme.grey500, fontSize: 11)),
        ]),
      ]),
      if (isFac && stop.passengers.isNotEmpty) ...[
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 6, runSpacing: 6,
          children: stop.passengers.take(6).map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: AppTheme.radiusFull),
            child: Text(p.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          )).toList(),
        )),
      ],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _openExternalNav,
          icon: const Icon(Icons.navigation_rounded, size: 18), label: const Text('Navegar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd)),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(
          onPressed: () => _showConfirmSheet(stop),
          icon: const Icon(Icons.check_rounded, size: 18), label: const Text('Registrar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
        )),
      ]),
      const SizedBox(height: 6),
      Text('A parada avança sozinha quando você chegar (${_arrivalRadiusMeters.round()}m).',
          style: const TextStyle(color: AppTheme.grey400, fontSize: 11), textAlign: TextAlign.center),
    ]);
  }

  Widget _buildFinishedCard() {
    return Column(children: [
      Container(width: 56, height: 56,
        decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.flag_rounded, color: AppTheme.success, size: 30)),
      const SizedBox(height: 12),
      const Text('Rota concluída!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 4),
      Text('$_doneCount paradas concluídas • $_absentCount ausentes',
          style: const TextStyle(color: AppTheme.grey500, fontSize: 13)),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 52,
        child: ElevatedButton.icon(
          onPressed: () { _stopSharing(); Navigator.pop(context); },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Finalizar', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
        )),
    ]);
  }

  void _showExitDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
      title: const Text('Encerrar navegação?'),
      content: const Text('Sua localização deixará de ser compartilhada com os alunos.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuar')),
        TextButton(
          onPressed: () { Navigator.pop(ctx); _stopSharing(); Navigator.pop(context); },
          child: const Text('Encerrar', style: TextStyle(color: AppTheme.error))),
      ],
    ));
  }

  void _finishRoute() {
    _stopSharing();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rota finalizada! 🎉'),
        backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
    }
  }
}

// ===== Widgets auxiliares =====

class _ConfirmStopSheet extends StatelessWidget {
  final RouteStopEntity stop;
  final bool isEmbarque;
  final bool auto;
  const _ConfirmStopSheet({required this.stop, required this.isEmbarque, required this.auto});

  @override
  Widget build(BuildContext context) {
    final isFac = stop.isFaculdade;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        if (auto) Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: AppTheme.radiusMd),
          child: Row(children: const [
            Icon(Icons.location_on_rounded, color: AppTheme.success, size: 18), SizedBox(width: 8),
            Expanded(child: Text('Você chegou nesta parada',
                style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 13))),
          ]),
        ),
        Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: isFac ? AppTheme.successGradient : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14)),
            child: Center(child: Icon(
              isFac ? Icons.school_rounded : (stop.isPickup ? Icons.person_rounded : Icons.home_rounded),
              color: Colors.white, size: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            if (!isFac && stop.address.isNotEmpty)
              Text(stop.address, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
            if (isFac)
              Text('${stop.passengerCount} aluno${stop.passengerCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 20),
        if (isEmbarque) ...[
          _btn(context, 'Embarcou', Icons.login_rounded, AppTheme.success, StopStatus.concluida),
          const SizedBox(height: 10),
          _btn(context, 'Ausente', Icons.person_off_rounded, AppTheme.warning, StopStatus.ausente),
        ] else ...[
          _btn(context, 'Desembarque realizado', Icons.logout_rounded, AppTheme.success, StopStatus.concluida),
        ],
        const SizedBox(height: 10),
        _btn(context, 'Pular parada', Icons.skip_next_rounded, AppTheme.grey500, StopStatus.cancelada, outlined: true),
        const SizedBox(height: 6),
        Center(child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppTheme.grey500)))),
      ]),
    );
  }

  Widget _btn(BuildContext context, String label, IconData icon, Color color, StopStatus status, {bool outlined = false}) {
    return SizedBox(width: double.infinity, height: 52,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, status),
              icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd)))
          : ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, status),
              icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0)));
  }
}

class _NavChoiceSheet extends StatelessWidget {
  final List<(double, double)> waypoints;
  const _NavChoiceSheet({required this.waypoints});

  @override
  Widget build(BuildContext context) {
    final count = waypoints.length;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Abrir navegação externa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 4),
        Text(
          'Abre com $count parada${count != 1 ? 's' : ''} pendente${count != 1 ? 's' : ''}. '
          'O VanGo continua organizando; o app externo mostra trânsito em tempo real.',
          textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
          onPressed: () async { Navigator.pop(context); await ExternalNavService.openGoogleMapsWithRoute(waypoints); },
          icon: const Icon(Icons.map_rounded, size: 18), label: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
          onPressed: () async { Navigator.pop(context); await ExternalNavService.openWazeWithRoute(waypoints); },
          icon: const Icon(Icons.navigation_rounded, size: 18), label: const Text('Waze', style: TextStyle(fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd)))),
      ]),
    );
  }
}
