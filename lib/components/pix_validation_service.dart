import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class PixValidationService {
  final String _endpoint = 'https://validar-comprovante-pix.onrender.com/api/validate';

  Future<bool> validatePixProof(File comprovante) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));

      request.files.add(await http.MultipartFile.fromPath('file', comprovante.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['success'] == true && decodedResponse['isValid'] == true) {
          return true; 
        } else {
          throw Exception(decodedResponse['message'] ?? 'Comprovante inválido.');
        }
      } else {
        throw Exception('Erro na validação: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Erro ao validar comprovante: $e');
    }
  }
}
