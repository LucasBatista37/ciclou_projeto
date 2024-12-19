import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> generateManualQr({
  required String pixKey,
  required double amount,
  required String description,
}) async {
  const String endpoint =
      'https://api-mercado-pago-ciclou.vercel.app/pix/manual_qr';

  if (pixKey.isEmpty || amount <= 0 || description.isEmpty) {
    throw Exception('Todos os campos devem ser preenchidos corretamente.');
  }

  try {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chavePix': pixKey,
        'amount': amount,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        'qrCodeBase64': data['qrCode'],
        'confirmationCode': data['confirmationCode'],
      };
    } else {
      throw Exception('Erro ao gerar QR Code PIX: ${response.body}');
    }
  } catch (e) {
    throw Exception('Erro ao processar solicitação: $e');
  }
}
