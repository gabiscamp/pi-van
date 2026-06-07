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
import '../../../core/services/route_service.dart' as rs;
import '../../../domain/entities/route_stop_entity.dart';
import '../../../domain/enums/route_type.dart';
import '../../../domain/enums/stop_status.dart';
import '../../../domain/repositories/sala_repository.dart';

/// Tela de navegação ativa (item 8).
///
/// - Avança automaticamente de parada quando o motorista entra no raio de
///   chegada (geofence). Sem botão "Próximo".
/// - Registra status de cada parada (aguardando/em andamento/concluída/
///   ausente/cancelada) com confirmação de embarque/desembarque.
/// - Mostra próxima parada de forma inteligente (nome, endereço/quantidade,
///   distância e tempo estimado).
/// - Recalcula a rota quando há mudanças (ausência, cancelamento, etc).
/// - Exibe indicadores da viagem.
/// - Permite abrir navegação externa (Google Maps / Waze).
class ActiveRoutePage extends StatefulWidget {
  const ActiveRoutePage({super.key});
  @override
  State<ActiveRoutePage> createState() => _ActiveRoutePageState();
}

class _ActiveRoutePageState extends State<ActiveRoutePage> {
  final MapController _mapController = MapController();

  /// Raio (em metros) para considerar a parada alcançada. ~40m equilibra
  /// erro de GPS urbano com precisão suficiente para não disparar cedo.
  static const double _arrivalRadiusMeters = 40;

  RouteType _type = RouteType.ida;
  List<RouteStopEntity> _stops = [];
  List<LatLng> _routePoints = [];
  LatLng? _currentPosition;
  bool _isSharing = false;

  StreamSubscription<Position>? _positionSub;
  Timer? _shareTimer;

  String _routeInfo = '';
  String? _nextEta; // tempo estimado até a próxima parada
  String? _nextDistance; // distância até a próxima parada

  String get _salaId => AppRouter.authViewModel.currentUser?.salaId ?? '';
  static const _defaultCenter = LatLng(-19.9167, -43.9345);

  /// Índice da próxima parada pendente (primeira não finalizada).
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
          _stops = args.stops
              .map((s) => s.copyWith(status: StopStatus.aguardando))
              .toList();
          // A primeira parada já entra "em andamento".
          if (_stops.isNotEmpty) {
            _stops[0] = _stops[0].copyWith(status: StopStatus.emAndamento);
          }
        });
        _calculateRoute();
      }
      // Inicia o GPS automaticamente para habilitar a automação.
      _startSharing();
    });
  }

  @override
  void dispose() {
    _stopSharing();
    _positionSub?.cancel();
    _shareTimer?.cancel();
    super.dispose();
  }

  // ===== Rota desenhada =====
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
        setState(() {
          _routePoints = result.points.map((p) => LatLng(p.lat, p.lng)).toList();
          _routeInfo = '${result.distanceText} • ${result.durationText}';
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

  // ===== GPS / compartilhamento =====
  Future<void> _startSharing() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permissão de localização negada — a automação por GPS ficará indisponível'),
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
      _mapController.move(pos, _mapController.camera.zoom);
      _onLocationUpdate(position.latitude, position.longitude);
    });

    _shareTimer = Timer.periodic(const Duration(seconds: 10), (_) => _shareLocation());
    _shareLocation();
  }

  /// Núcleo da automação: monitora a localização e avança a parada quando o
  /// motorista entra no raio de chegada.
  void _onLocationUpdate(double lat, double lng) {
    final stop = _currentStop;
    if (stop == null) return;

    final dist = rs.RouteService.haversineDistance(lat, lng, stop.latitude, stop.longitude);

    // Atualiza distância/tempo estimado exibidos.
    _updateNextEstimate(dist);

    if (dist <= _arrivalRadiusMeters) {
      _onArrivedAtStop(stop);
    }
  }

  void _updateNextEstimate(double straightDist) {
    // Distância em linha reta (rápida e local, sem chamadas de rede).
    final approxText = straightDist >= 1000
        ? '${(straightDist / 1000).toStringAsFixed(1)} km'
        : '${straightDist.round()} m';
    // ETA aproximado considerando ~22 km/h de média urbana (6.1 m/s).
    final etaMin = (straightDist / 6.1 / 60).ceil();
    final etaText = etaMin <= 1 ? 'chegando' : '~$etaMin min';
    if (mounted) {
      setState(() {
        _nextDistance = approxText;
        _nextEta = etaText;
      });
    }
  }

  Future<void> _shareLocation() async {
    if (!_isSharing || _currentPosition == null || _salaId.isEmpty) return;
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      await repo.updateDriverLocation(
        salaId: _salaId, lat: _currentPosition!.latitude, lng: _currentPosition!.longitude, isSharing: true);
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
  /// Disparado automaticamente ao entrar no raio da parada. Abre a folha de
  /// confirmação para o motorista registrar o resultado.
  bool _confirmSheetOpen = false;
  Future<void> _onArrivedAtStop(RouteStopEntity stop) async {
    if (_confirmSheetOpen) return;
    _confirmSheetOpen = true;
    await _showConfirmSheet(stop, auto: true);
    _confirmSheetOpen = false;
  }

  Future<void> _showConfirmSheet(RouteStopEntity stop, {bool auto = false}) async {
    // Em ida: embarque em casa (pickup) e desembarque na faculdade.
    // Em volta: embarque na faculdade e desembarque na casa.
    final isEmbarque = _type == RouteType.ida ? !stop.isFaculdade : stop.isFaculdade;

    final result = await showModalBottomSheet<StopStatus>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !auto,
      builder: (_) => _ConfirmStopSheet(
        stop: stop,
        isEmbarque: isEmbarque,
        auto: auto,
      ),
    );

    if (result != null) {
      _applyStopStatus(stop, result);
    }
  }

  void _applyStopStatus(RouteStopEntity stop, StopStatus status) {
    final idx = _stops.indexWhere((s) => s.id == stop.id);
    if (idx < 0) return;
    setState(() {
      _stops[idx] = _stops[idx].copyWith(status: status);
      // Marca a próxima pendente como "em andamento".
      final next = _stops.indexWhere((s) => !s.status.isResolved);
      if (next >= 0 && _stops[next].status == StopStatus.aguardando) {
        _stops[next] = _stops[next].copyWith(status: StopStatus.emAndamento);
      }
      _nextDistance = null;
      _nextEta = null;
    });
    // Recalcula a rota para as paradas restantes.
    _calculateRoute();

    if (_finished) {
      _finishRoute();
    }
  }

  /// Recálculo manual/explícito (ex: após mudança de endereço externa).
  Future<void> _recalculate() async {
    await _calculateRoute();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rota recalculada com as paradas restantes'),
        backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
    }
  }

  void _openExternalNav() {
    final stop = _currentStop;
    if (stop == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NavChoiceSheet(stop: stop),
    );
  }

  // ===== Indicadores =====
  int get _totalConfirmed {
    // Conta passageiros únicos atendidos por toda a rota.
    final ids = <String>{};
    for (final s in _stops) {
      if (s.isFaculdade) {
        for (final p in s.passengers) {
          ids.add(p.userId);
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        _buildMap(),
        _buildTopBar(),
        _buildBottomPanel(),
      ]),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _stops.isNotEmpty ? LatLng(_stops.first.latitude, _stops.first.longitude) : _defaultCenter,
        initialZoom: 14,
      ),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.vango.app'),
        if (_routePoints.isNotEmpty)
          PolylineLayer(polylines: [Polyline(points: _routePoints, color: AppTheme.primary, strokeWidth: 5)]),
        MarkerLayer(markers: [
          ..._stops.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final isNext = i == _currentIndex;
            return Marker(
              point: LatLng(s.latitude, s.longitude), width: 46, height: 46,
              child: Container(
                decoration: BoxDecoration(
                  color: _markerColor(s, isNext),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: isNext ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 10)] : null,
                ),
                child: Center(child: s.isFaculdade
                    ? const Icon(Icons.school_rounded, color: Colors.white, size: 18)
                    : Icon(s.isPickup ? Icons.person_rounded : Icons.home_rounded, color: Colors.white, size: 18)),
              ),
            );
          }),
          if (_currentPosition != null)
            Marker(
              point: _currentPosition!, width: 50, height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)]),
                child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28),
              ),
            ),
        ]),
      ],
    );
  }

  Color _markerColor(RouteStopEntity s, bool isNext) {
    switch (s.status) {
      case StopStatus.concluida:
        return AppTheme.success;
      case StopStatus.ausente:
        return AppTheme.warning;
      case StopStatus.cancelada:
        return AppTheme.grey400;
      case StopStatus.emAndamento:
        return isNext ? AppTheme.primary : AppTheme.accent;
      case StopStatus.aguardando:
        return isNext ? AppTheme.primary : (s.isFaculdade ? AppTheme.accent : AppTheme.grey500);
    }
  }

  Widget _buildTopBar() {
    return Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        GestureDetector(onTap: _showExitDialog, child: Container(width: 44, height: 44,
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, boxShadow: AppTheme.cardShadow),
          child: const Icon(Icons.arrow_back_rounded, size: 20))),
        const SizedBox(width: 12),
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, boxShadow: AppTheme.cardShadow),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: _isSharing ? AppTheme.success : AppTheme.grey300, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _isSharing ? '${_type.shortLabel} • GPS ativo' : '${_type.shortLabel} • GPS pausado',
              style: TextStyle(color: _isSharing ? AppTheme.success : AppTheme.grey500, fontWeight: FontWeight.w600, fontSize: 13))),
            if (_routeInfo.isNotEmpty) Text(_routeInfo, style: const TextStyle(color: AppTheme.grey500, fontSize: 11)),
          ]),
        )),
        const SizedBox(width: 8),
        GestureDetector(onTap: _recalculate, child: Container(width: 44, height: 44,
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, boxShadow: AppTheme.cardShadow),
          child: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.primary))),
      ]),
    )));
  }

  Widget _buildBottomPanel() {
    return Positioned(bottom: 0, left: 0, right: 0, child: Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        _buildIndicators(),
        const SizedBox(height: 14),
        if (_finished) _buildFinishedCard() else _buildNextStopCard(),
      ]),
    ));
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
    final title = stop.name;
    final subtitle = isFac
        ? '${stop.passengerCount} aluno${stop.passengerCount == 1 ? '' : 's'} ${_type == RouteType.ida ? 'desembarcam' : 'embarcam'} aqui'
        : [if (stop.addressLabel != null) stop.addressLabel!, if (stop.address.isNotEmpty) stop.address].join(' · ');

    return Column(children: [
      Row(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(gradient: isFac ? AppTheme.successGradient : AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
          child: Center(child: Icon(isFac ? Icons.school_rounded : (stop.isPickup ? Icons.person_rounded : Icons.home_rounded), color: Colors.white, size: 26))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Próxima parada', style: TextStyle(color: AppTheme.grey500, fontSize: 12)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: const TextStyle(color: AppTheme.grey500, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (_nextDistance != null) Text(_nextDistance!, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 16)),
          if (_nextEta != null) Text(_nextEta!, style: const TextStyle(color: AppTheme.grey500, fontSize: 11)),
        ]),
      ]),
      if (isFac && stop.passengers.isNotEmpty) ...[
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 6, runSpacing: 6,
          children: stop.passengers.take(6).map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: AppTheme.radiusFull),
            child: Text(p.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          )).toList())),
      ],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _openExternalNav,
          icon: const Icon(Icons.navigation_rounded, size: 18),
          label: const Text('Navegar'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd)),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(
          onPressed: () => _showConfirmSheet(stop),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Registrar'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
        )),
      ]),
      const SizedBox(height: 6),
      Text('A parada avança sozinha quando você chegar (${_arrivalRadiusMeters.round()}m).',
        style: const TextStyle(color: AppTheme.grey400, fontSize: 11), textAlign: TextAlign.center),
    ]);
  }

  Widget _buildFinishedCard() {
    return Column(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.flag_rounded, color: AppTheme.success, size: 30)),
      const SizedBox(height: 12),
      const Text('Rota concluída!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 4),
      Text('$_doneCount paradas concluídas • $_absentCount ausentes', style: const TextStyle(color: AppTheme.grey500, fontSize: 13)),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
        onPressed: () { _stopSharing(); Navigator.pop(context); },
        icon: const Icon(Icons.check_rounded),
        label: const Text('Finalizar', style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white,
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
        TextButton(onPressed: () { Navigator.pop(ctx); _stopSharing(); Navigator.pop(context); },
          child: const Text('Encerrar', style: TextStyle(color: AppTheme.error))),
      ],
    ));
  }

  void _finishRoute() {
    _stopSharing();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rota finalizada! 🎉'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
    }
  }
}

/// Folha de confirmação de embarque/desembarque numa parada.
class _ConfirmStopSheet extends StatelessWidget {
  final RouteStopEntity stop;
  final bool isEmbarque;
  final bool auto;
  const _ConfirmStopSheet({required this.stop, required this.isEmbarque, required this.auto});

  @override
  Widget build(BuildContext context) {
    final isFac = stop.isFaculdade;
    final titulo = stop.name;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        if (auto) Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: AppTheme.radiusMd),
          child: Row(children: const [
            Icon(Icons.location_on_rounded, color: AppTheme.success, size: 18), SizedBox(width: 8),
            Expanded(child: Text('Você chegou nesta parada', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 13))),
          ]),
        ),
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: isFac ? AppTheme.successGradient : AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Icon(isFac ? Icons.school_rounded : (stop.isPickup ? Icons.person_rounded : Icons.home_rounded), color: Colors.white, size: 24))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            if (!isFac && stop.address.isNotEmpty) Text(stop.address, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
            if (isFac) Text('${stop.passengerCount} aluno${stop.passengerCount == 1 ? '' : 's'}', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
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
        Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppTheme.grey500)))),
      ]),
    );
  }

  Widget _btn(BuildContext context, String label, IconData icon, Color color, StopStatus status, {bool outlined = false}) {
    return SizedBox(width: double.infinity, height: 52, child: outlined
        ? OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, status),
            icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd)),
          )
        : ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, status),
            icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
          ));
  }
}

/// Folha para escolher o app de navegação externo.
class _NavChoiceSheet extends StatelessWidget {
  final RouteStopEntity stop;
  const _NavChoiceSheet({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Abrir navegação externa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 4),
        const Text('O VanGo continua organizando a rota; o app externo ajuda com o trânsito em tempo real.',
          textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grey500, fontSize: 12)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
          onPressed: () async { Navigator.pop(context); await ExternalNavService.openGoogleMaps(stop.latitude, stop.longitude); },
          icon: const Icon(Icons.map_rounded, size: 18), label: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
        )),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
          onPressed: () async { Navigator.pop(context); await ExternalNavService.openWaze(stop.latitude, stop.longitude); },
          icon: const Icon(Icons.navigation_rounded, size: 18), label: const Text('Waze', style: TextStyle(fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd)),
        )),
      ]),
    );
  }
}
