import 'dart:convert';
import 'package:http/http.dart' as http;

class ViaCepService {
  // Retorna um Map (JSON) com os dados do endereço ou null se falhar
  Future<Map<String, dynamic>?> buscarEndereco(String cep) async {
    // Remove qualquer traço ou ponto que o usuário digitar, deixando só números
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    
    // O ViaCEP exige exatamente 8 números
    if (cepLimpo.length != 8) return null;

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // O ViaCEP retorna {"erro": true} se o CEP não existir
        if (data.containsKey('erro')) return null; 
        
        return data;
      }
    } catch (e) {
      // Em caso de erro de internet, retorna nulo silenciosamente
      return null;
    }
    return null;
  }
}