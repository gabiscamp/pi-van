import 'package:url_launcher/url_launcher.dart';

/// Abre aplicativos de navegação externos para auxiliar com trânsito em
/// tempo real. O app continua responsável pela ordem das paradas; a
/// navegação externa só conduz até o ponto atual.
class ExternalNavService {
  /// Abre o Google Maps em modo navegação para o destino informado.
  static Future<bool> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    return _launch(uri);
  }

  /// Abre o Waze para o destino informado.
  static Future<bool> openWaze(double lat, double lng) async {
    final appUri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(appUri)) {
      return launchUrl(appUri, mode: LaunchMode.externalApplication);
    }
    // Fallback para a versão web do Waze.
    final webUri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    return _launch(webUri);
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
