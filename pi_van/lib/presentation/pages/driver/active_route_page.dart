import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/route_service.dart' as rs;
import '../../../domain/repositories/sala_repository.dart';
import 'route_builder_page.dart';

class ActiveRoutePage extends StatefulWidget {
  const ActiveRoutePage({super.key});
  @override
  State<ActiveRoutePage> createState() => _ActiveRoutePageState();
}

class _ActiveRoutePageState extends State<ActiveRoutePage> {
  final MapController _mapController = MapController();
  List<RouteStop> _stops = [];
  List<LatLng> _routePoints = [];
  LatLng? _currentPosition;
  bool _isSharing = false;
  int _currentStopIndex = 0;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription? _attendanceSub;
  Timer? _shareTimer;
  String _routeInfo = '';

  // Mapa faculdadeId → {studentId → {name, liberado}}
  Map<String, Map<String, Map<String, dynamic>>> _facStudents = {};
  final Set<String> _notifiedLiberados = {};

  String get _salaId => AppRouter.authViewModel.currentUser?.salaId ?? '';
  static const _defaultCenter = LatLng(-19.9167, -43.9345);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is List<RouteStop>) {
        setState(() => _stops = args);
        _calculateRoute();
      }
      _startAttendanceListener();
    });
  }

  @override
  void dispose() {
    _stopSharing();
    _positionSub?.cancel();
    _attendanceSub?.cancel();
    _shareTimer?.cancel();
    super.dispose();
  }

  void _startAttendanceListener() {
    if (_salaId.isEmpty) return;
    final today = DateTime.now();
    final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final repo = ServiceLocator.getIt<SalaRepository>();
    _attendanceSub = repo.attendanceStream(salaId: _salaId, date: date).listen((votes) {
      if (!mounted) return;
      // Atualiza status de liberação para cada faculdade
      final newFacStudents = <String, Map<String, Map<String, dynamic>>>{};
      votes.forEach((userId, data) {
        final facId = data['faculdadeId'] as String? ?? '';
        if (facId.isEmpty) return;
        newFacStudents.putIfAbsent(facId, () => {});
        newFacStudents[facId]![userId] = {
          'name': data['userName'] as String? ?? 'Aluno',
          'liberado': data['liberado'] == true,
        };
        // Notificação para alunos recém-liberados
        if (data['liberado'] == true && !_notifiedLiberados.contains(userId)) {
          _notifiedLiberados.add(userId);
          final nome = data['userName'] as String? ?? 'Aluno';
          final fac = data['faculdadeName'] as String? ?? '';
          NotificationService.showLiberado(userId, nome, fac);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$nome foi liberado! 🎉'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)),
            );
          }
        }
      });
      setState(() => _facStudents = newFacStudents);
    });
  }

  Future<void> _calculateRoute() async {
    if (_stops.isEmpty) return;
    try {
      final routeService = ServiceLocator.getIt<rs.RouteService>();
      final waypoints = _stops.map((s) => rs.LatLng(lat: s.lat, lng: s.lng)).toList();
      final result = await routeService.getRoute(waypoints);
      if (result != null && mounted) {
        setState(() {
          _routePoints = result.points.map((p) => LatLng(p.lat, p.lng)).toList();
          _routeInfo = '${result.distanceText} • ${result.durationText}';
        });
        // Centralizar mapa na rota
        if (_routePoints.isNotEmpty) {
          _mapController.fitCamera(CameraFit.coordinates(coordinates: _routePoints, padding: const EdgeInsets.all(60)));
        }
      }
    } catch (e) {
      print('Route calculation error: $e');
    }
  }

  Future<void> _startSharing() async {
    // Verificar permissão GPS
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização negada'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating));
        return;
      }
    }

    setState(() => _isSharing = true);

    // Começar a escutar posição GPS
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      if (!mounted) return;
      setState(() => _currentPosition = LatLng(position.latitude, position.longitude));
      _mapController.move(_currentPosition!, _mapController.camera.zoom);
    });

    // Compartilhar no Firestore a cada 10 segundos
    _shareTimer = Timer.periodic(const Duration(seconds: 10), (_) => _shareLocation());
    _shareLocation(); // Primeira vez imediata
  }

  Future<void> _shareLocation() async {
    if (!_isSharing || _currentPosition == null || _salaId.isEmpty) return;
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      await repo.updateDriverLocation(
        salaId: _salaId, lat: _currentPosition!.latitude, lng: _currentPosition!.longitude, isSharing: true,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _stops.isNotEmpty ? LatLng(_stops.first.lat, _stops.first.lng) : _defaultCenter,
              initialZoom: 13,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.vango.app'),
              // Rota desenhada
              if (_routePoints.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(points: _routePoints, color: AppTheme.primary, strokeWidth: 5),
                ]),
              // Marcadores das paradas
              MarkerLayer(markers: [
                ..._stops.asMap().entries.expand((e) {
                  final i = e.key;
                  final s = e.value;
                  final isNext = i == _currentStopIndex;
                  final isPast = i < _currentStopIndex;

                  final markers = <Marker>[];
                  // Marcador principal da parada
                  markers.add(Marker(
                    point: LatLng(s.lat, s.lng), width: 46, height: 46,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPast ? AppTheme.grey400 : (s.isFaculdade ? AppTheme.success : (isNext ? AppTheme.primary : AppTheme.accent)),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: isNext ? [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 10)] : null,
                      ),
                      child: Center(child: s.isFaculdade
                        ? const Icon(Icons.school_rounded, color: Colors.white, size: 18)
                        : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                    ),
                  ));

                  // Para faculdades: mostrar mini-badges dos alunos
                  if (s.isFaculdade) {
                    final facId = s.id.replaceFirst('fac_', '');
                    final students = _facStudents[facId]?.values.toList() ?? [];
                    if (students.isNotEmpty) {
                      markers.add(Marker(
                        point: LatLng(s.lat + 0.0003, s.lng + 0.0004),
                        width: 80, height: 30,
                        child: _buildStudentBadge(students),
                      ));
                    }
                  }
                  return markers;
                }),
                // Posição atual do motorista
                if (_currentPosition != null)
                  Marker(
                    point: _currentPosition!, width: 50, height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28),
                    ),
                  ),
              ]),
            ],
          ),

          // Top bar
          Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: Padding(
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
                  Expanded(child: Text(_isSharing ? 'Compartilhando localização' : 'Localização pausada',
                    style: TextStyle(color: _isSharing ? AppTheme.success : AppTheme.grey500, fontWeight: FontWeight.w600, fontSize: 13))),
                  if (_routeInfo.isNotEmpty)
                    Text(_routeInfo, style: const TextStyle(color: AppTheme.grey500, fontSize: 11)),
                ]),
              )),
            ]),
          ))),

          // Bottom panel
          Positioned(bottom: 0, left: 0, right: 0, child: Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(color: AppTheme.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, -4))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              // Next stop info
              if (_stops.isNotEmpty && _currentStopIndex < _stops.length) ...[
                Row(children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text('${_currentStopIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Próxima parada', style: TextStyle(color: AppTheme.grey500, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(_stops[_currentStopIndex].name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  ])),
                  Text('${_currentStopIndex + 1}/${_stops.length}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ]),
              ] else
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.infoLight, borderRadius: AppTheme.radiusMd),
                  child: const Text('Monte uma rota antes de iniciar', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.info, fontSize: 13))),
              const SizedBox(height: 20),
              // Action buttons
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => _isSharing ? _stopSharing() : _startSharing(),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isSharing ? AppTheme.successLight : AppTheme.grey100,
                      border: Border.all(color: _isSharing ? AppTheme.success : AppTheme.grey200),
                      borderRadius: AppTheme.radiusMd),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_isSharing ? Icons.location_on_rounded : Icons.location_off_rounded, color: _isSharing ? AppTheme.success : AppTheme.grey500, size: 20),
                      const SizedBox(width: 8),
                      Text(_isSharing ? 'Ao vivo' : 'Iniciar GPS', style: TextStyle(color: _isSharing ? AppTheme.success : AppTheme.grey600, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(
                  onTap: _stops.isEmpty ? null : () {
                    if (_currentStopIndex < _stops.length - 1) { setState(() => _currentStopIndex++); }
                    else { _finishRoute(); }
                  },
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: AppTheme.radiusMd),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_currentStopIndex >= _stops.length - 1 ? Icons.flag_rounded : Icons.skip_next_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(_currentStopIndex >= _stops.length - 1 ? 'Finalizar' : 'Próxima', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                  ),
                )),
              ]),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildStudentBadge(List<Map<String, dynamic>> students) {
    final liberados = students.where((s) => s['liberado'] == true).length;
    final total = students.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: liberados == total ? AppTheme.success : (liberados > 0 ? AppTheme.warning : AppTheme.grey400),
        borderRadius: AppTheme.radiusFull,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_rounded, color: Colors.white, size: 12),
        const SizedBox(width: 4),
        Text('$liberados/$total', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  void _showExitDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
      title: const Text('Encerrar navegação?'),
      content: const Text('Sua localização deixará de ser compartilhada.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuar')),
        TextButton(onPressed: () { Navigator.pop(ctx); _stopSharing(); Navigator.pop(context); },
          child: const Text('Encerrar', style: TextStyle(color: AppTheme.error))),
      ],
    ));
  }

  void _finishRoute() {
    _stopSharing();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rota finalizada!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
    Navigator.pop(context);
  }
}
