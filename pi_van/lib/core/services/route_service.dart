import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Serviço de rotas usando OSRM (gratuito, sem API key)
class RouteService {
  static const _baseUrl = 'https://router.project-osrm.org';

  /// Calcula rota entre waypoints (retorna polyline, distância, duração e passos).
  Future<RouteResult?> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;
    try {
      final coords = waypoints.map((w) => '${w.lng},${w.lat}').join(';');
      final url = Uri.parse(
          '$_baseUrl/route/v1/driving/$coords?overview=full&geometries=geojson&steps=true');
      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body);
      if (data['code'] != 'Ok') return null;

      final route = data['routes'][0];
      final geometry = route['geometry']['coordinates'] as List;
      final points = geometry
          .map<LatLng>(
              (c) => LatLng(lat: (c[1] as num).toDouble(), lng: (c[0] as num).toDouble()))
          .toList();

      // Parseia os passos de instrução de cada leg
      final legs = route['legs'] as List? ?? [];
      final steps = <RouteStep>[];
      for (final leg in legs) {
        for (final step in (leg['steps'] as List? ?? [])) {
          final maneuver = step['maneuver'] as Map?;
          if (maneuver == null) continue;
          final type = maneuver['type'] as String? ?? 'continue';
          final modifier = maneuver['modifier'] as String?;
          final loc = maneuver['location'] as List?;
          if (loc == null || loc.length < 2) continue;
          steps.add(RouteStep(
            instruction: _translateManeuver(type, modifier),
            distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
            lat: (loc[1] as num).toDouble(), // OSRM retorna [lng, lat]
            lng: (loc[0] as num).toDouble(),
            streetName: step['name'] as String? ?? '',
            maneuverType: type,
            maneuverModifier: modifier,
          ));
        }
      }

      return RouteResult(
        points: points,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
        steps: steps,
      );
    } catch (e) {
      debugPrint('OSRM route error: $e');
      return null;
    }
  }

  /// Otimiza a ordem dos waypoints (TSP) usando OSRM /trip
  Future<TripResult?> optimizeRoute(List<LatLng> waypoints, {int? sourceIndex}) async {
    if (waypoints.length < 3) return null;
    try {
      final coords = waypoints.map((w) => '${w.lng},${w.lat}').join(';');
      final source = sourceIndex != null ? '&source=first' : '';
      final url = Uri.parse(
          '$_baseUrl/trip/v1/driving/$coords?overview=full&geometries=geojson&roundtrip=false$source&destination=last');
      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body);
      if (data['code'] != 'Ok') return null;

      final trip = data['trips'][0];
      final waypointOrder =
          (data['waypoints'] as List).map<int>((w) => w['waypoint_index'] as int).toList();
      final geometry = trip['geometry']['coordinates'] as List;
      final points = geometry
          .map<LatLng>(
              (c) => LatLng(lat: (c[1] as num).toDouble(), lng: (c[0] as num).toDouble()))
          .toList();

      return TripResult(
        optimizedOrder: waypointOrder,
        points: points,
        distanceMeters: (trip['distance'] as num).toDouble(),
        durationSeconds: (trip['duration'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('OSRM trip error: $e');
      return null;
    }
  }

  /// Calcula distância Haversine entre dois pontos (em metros)
  static double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  /// Traduz os tipos de manobra do OSRM para o português.
  static String _translateManeuver(String type, String? modifier) {
    switch (type) {
      case 'turn':
        switch (modifier) {
          case 'left':         return 'Vire à esquerda';
          case 'right':        return 'Vire à direita';
          case 'sharp left':   return 'Vire à esquerda (fechado)';
          case 'sharp right':  return 'Vire à direita (fechado)';
          case 'slight left':  return 'Mantenha-se à esquerda';
          case 'slight right': return 'Mantenha-se à direita';
          default:             return 'Siga em frente';
        }
      case 'new name':
      case 'continue':         return 'Continue em frente';
      case 'depart':           return 'Inicie a rota';
      case 'arrive':           return 'Destino à frente';
      case 'merge':            return 'Incorpore-se à via';
      case 'on ramp':          return 'Entre na rampa';
      case 'off ramp':         return 'Saia pela rampa';
      case 'fork':
        if (modifier == 'left')  return 'Mantenha-se à esquerda';
        if (modifier == 'right') return 'Mantenha-se à direita';
        return 'Bifurcação';
      case 'roundabout':
      case 'rotary':           return 'Entre na rotatória';
      case 'exit roundabout':
      case 'exit rotary':      return 'Saia da rotatória';
      case 'end of road':
        if (modifier == 'left')  return 'Ao fim, vire à esquerda';
        if (modifier == 'right') return 'Ao fim, vire à direita';
        return 'Ao fim da rua';
      case 'notification':     return 'Continue';
      default:                 return 'Continue em frente';
    }
  }
}

class LatLng {
  final double lat, lng;
  const LatLng({required this.lat, required this.lng});
}

/// Um passo de instrução de navegação retornado pelo OSRM.
class RouteStep {
  final String instruction;
  final double distanceMeters;
  /// Coordenadas onde a manobra acontece (OSRM: location).
  final double lat;
  final double lng;
  final String streetName;
  final String maneuverType;
  final String? maneuverModifier;

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.lat,
    required this.lng,
    required this.streetName,
    required this.maneuverType,
    this.maneuverModifier,
  });
}

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
  });

  String get distanceText {
    if (distanceMeters >= 1000) return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    return '${distanceMeters.round()} m';
  }

  String get durationText {
    final mins = (durationSeconds / 60).round();
    if (mins >= 60) return '${mins ~/ 60}h ${mins % 60}min';
    return '$mins min';
  }
}

class TripResult extends RouteResult {
  final List<int> optimizedOrder;
  TripResult({
    required this.optimizedOrder,
    required super.points,
    required super.distanceMeters,
    required super.durationSeconds,
  });
}
