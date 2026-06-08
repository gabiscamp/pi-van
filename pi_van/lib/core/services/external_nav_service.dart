import 'package:url_launcher/url_launcher.dart';

/// Abre aplicativos de navegação externos para auxiliar com trânsito em
/// tempo real. O app continua responsável pela ordem das paradas; a
/// navegação externa conduz pelo trajeto completo ou até o ponto atual.
class ExternalNavService {
  /// Abre o Google Maps em modo navegação para um único destino.
  static Future<bool> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    return _launch(uri);
  }

  /// Abre o Google Maps com rota completa passando por múltiplas paradas.
  /// Usa o formato /dir/lat1,lng1/lat2,lng2/... que funciona em browser e app.
  static Future<bool> openGoogleMapsWithRoute(List<(double, double)> stops) async {
    if (stops.isEmpty) return false;
    if (stops.length == 1) return openGoogleMaps(stops.first.$1, stops.first.$2);
    final parts = stops.map((s) => '${s.$1},${s.$2}').join('/');
    final uri = Uri.parse('https://www.google.com/maps/dir/$parts');
    return _launch(uri);
  }

  /// Abre o Waze para um único destino.
  static Future<bool> openWaze(double lat, double lng) async {
    final appUri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(appUri)) {
      return launchUrl(appUri, mode: LaunchMode.externalApplication);
    }
    final webUri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    return _launch(webUri);
  }

  /// Abre o Waze navegando até a próxima parada (primeira da lista).
  /// (Waze não suporta múltiplas paradas na URL; o motorista navega passo a passo.)
  static Future<bool> openWazeWithRoute(List<(double, double)> stops) async {
    if (stops.isEmpty) return false;
    final next = stops.first;
    return openWaze(next.$1, next.$2);
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
