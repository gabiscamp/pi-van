import 'dart:convert';
import 'package:http/http.dart' as http;

class ViaCepService {
  // Retorna um Map (JSON) com os dados do endereço ou null se falhar
  Future<Map<String, dynamic>?> buscarEndereco(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) return null;

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');
      final response = await http.get(url);

      if (response.statusCode != 200) return null; // ← mais explícito

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data.containsKey('erro')) return null;

      return data;
    } catch (e) {
      print('Erro ViaCEP: $e'); // remova depois de resolver
      return null;
    }
  }
}
