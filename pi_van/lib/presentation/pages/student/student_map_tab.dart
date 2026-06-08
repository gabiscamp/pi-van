import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/route_service.dart' show RouteService;
import '../../../domain/repositories/sala_repository.dart';

class StudentMapTab extends StatefulWidget {
  final AuthViewModel viewModel;
  const StudentMapTab({super.key, required this.viewModel});
  @override
  State<StudentMapTab> createState() => _StudentMapTabState();
}

class _StudentMapTabState extends State<StudentMapTab> {
  final MapController _mapController = MapController();
  StreamSubscription? _locationSub;

  LatLng? _driverPosition;
  bool _driverOnline = false;

  /// Coordenadas da faculdade do aluno (carregadas no init).
  /// Usadas para detectar quando a van se aproxima para a rota de volta.
  LatLng? _faculdadePosition;

  static const _defaultCenter = LatLng(-19.9167, -43.9345);
  static const _proximityMeters = 300.0;

  @override
  void initState() {
    super.initState();
    _loadFaculdade();
    _listenDriverLocation();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  /// Carrega as coordenadas da faculdade do aluno para o check de proximidade.
  Future<void> _loadFaculdade() async {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null || user?.faculdadeId == null) return;
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      final facs = await repo.getFaculdades(user!.salaId!);
      final fac = facs.where((f) => f.id == user.faculdadeId).firstOrNull;
      if (fac != null && (fac.latitude != 0 || fac.longitude != 0)) {
        setState(() => _faculdadePosition = LatLng(fac.latitude, fac.longitude));
      }
    } catch (_) {}
  }

  void _listenDriverLocation() {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null) return;

    final repo = ServiceLocator.getIt<SalaRepository>();
    _locationSub = repo.driverLocationStream(user!.salaId!).listen((data) {
      if (!mounted) return;
      if (data != null && data['isSharing'] == true) {
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          setState(() {
            _driverPosition = LatLng(lat, lng);
            _driverOnline = true;
          });
          _mapController.move(_driverPosition!, _mapController.camera.zoom);
          _checkProximity(lat, lng);
        }
      } else {
        setState(() => _driverOnline = false);
        NotificationService.resetDriverApproaching();
      }
    });
  }

  /// Verifica se a van está a menos de 300m da casa OU da faculdade do aluno.
  /// Casa = rota de ida (van vem buscar em casa).
  /// Faculdade = rota de volta (van vem buscar na faculdade).
  void _checkProximity(double driverLat, double driverLng) {
    final user = widget.viewModel.currentUser;
    var isNear = false;

    // Distância até a casa do aluno
    if (user?.latitude != null && user?.longitude != null) {
      final d = RouteService.haversineDistance(
          driverLat, driverLng, user!.latitude!, user.longitude!);
      if (d < _proximityMeters) isNear = true;
    }

    // Distância até a faculdade do aluno (rota de volta)
    if (!isNear && _faculdadePosition != null) {
      final d = RouteService.haversineDistance(
          driverLat, driverLng, _faculdadePosition!.latitude, _faculdadePosition!.longitude);
      if (d < _proximityMeters) isNear = true;
    }

    if (isNear) {
      NotificationService.showDriverApproaching();
    } else {
      NotificationService.resetDriverApproaching();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverPosition ?? _defaultCenter,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vango.app',
              ),
              if (_driverPosition != null && _driverOnline)
                MarkerLayer(markers: [
                  Marker(
                    point: _driverPosition!,
                    width: 50, height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ]),
              // Marcador da casa do aluno
              if (widget.viewModel.currentUser?.latitude != null &&
                  widget.viewModel.currentUser?.longitude != null)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(widget.viewModel.currentUser!.latitude!,
                        widget.viewModel.currentUser!.longitude!),
                    width: 40, height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppTheme.accent, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3)),
                      child: const Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              // Marcador da faculdade do aluno
              if (_faculdadePosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _faculdadePosition!,
                    width: 40, height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppTheme.success, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3)),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
            ],
          ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: AppTheme.radiusMd,
                    boxShadow: AppTheme.cardShadow),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: AppTheme.radiusMd),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text('Localização da Van',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
              ),
            ),
          ),

          // Bottom info card
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppTheme.white, borderRadius: AppTheme.radiusXl,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4))]),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _driverOnline ? AppTheme.primaryLight : AppTheme.grey100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.directions_bus_rounded,
                      color: _driverOnline ? AppTheme.primary : AppTheme.grey400, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_driverOnline ? 'Motorista em rota' : 'Motorista offline',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    _driverOnline
                        ? 'Você será notificado quando a van estiver a ${_proximityMeters.round()}m'
                        : 'Aguardando início da rota',
                    style: const TextStyle(color: AppTheme.grey500, fontSize: 13),
                  ),
                ])),
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                      color: _driverOnline ? AppTheme.success : AppTheme.grey300,
                      shape: BoxShape.circle),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
