import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': 'VanGoApp/1.0 (contato@vango.app)'};
  static const _timeout = Duration(seconds: 8);

  /// Endereço livre → lat/lng
  Future<GeoResult?> geocode(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final url = Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(address.trim())}&format=json&limit=1&countrycodes=br');
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as List;
      if (data.isEmpty) return null;
      final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
      final lng = double.tryParse(data[0]['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;
      return GeoResult(lat: lat, lng: lng, display: data[0]['display_name'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  /// Geocodifica endereço estruturado com fallback progressivo
  Future<GeoResult?> geocodeAddress({
    required String rua,
    required String numero,
    required String bairro,
    required String cidade,
    required String uf,
  }) async {
    // Tentativa 1: endereço completo
    if (rua.isNotEmpty && cidade.isNotEmpty) {
      final parts = <String>[];
      if (rua.isNotEmpty) parts.add(rua);
      if (numero.isNotEmpty) parts.add(numero);
      if (bairro.isNotEmpty) parts.add(bairro);
      if (cidade.isNotEmpty) parts.add(cidade);
      if (uf.isNotEmpty) parts.add(uf);
      parts.add('Brasil');
      final r1 = await geocode(parts.join(', '));
      if (r1 != null) return r1;
    }

    // Tentativa 2: apenas bairro + cidade + UF
    if (cidade.isNotEmpty) {
      final parts = <String>[];
      if (bairro.isNotEmpty) parts.add(bairro);
      parts.add(cidade);
      if (uf.isNotEmpty) parts.add(uf);
      parts.add('Brasil');
      final r2 = await geocode(parts.join(', '));
      if (r2 != null) return r2;
    }

    // Tentativa 3: apenas cidade + UF
    if (cidade.isNotEmpty && uf.isNotEmpty) {
      return geocode('$cidade, $uf, Brasil');
    }

    return null;
  }

  /// lat/lng → endereço
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse('$_baseUrl/reverse?lat=$lat&lon=$lng&format=json');
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;
      return (json.decode(res.body))['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class GeoResult {
  final double lat, lng;
  final String display;
  GeoResult({required this.lat, required this.lng, required this.display});
}
