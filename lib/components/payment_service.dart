import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  final String paymentId;

  PaymentService(this.paymentId);

  Future<String> validatePayment() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api-mercado-pago-ciclou.vercel.app/pix/validate_pix_payment/$paymentId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!data.containsKey('paymentStatus')) {
          throw Exception('Campo paymentStatus não encontrado na resposta.');
        }

        final paymentStatus = data['paymentStatus'];

        if (paymentStatus is! String) {
          throw Exception(
              'Tipo inesperado para paymentStatus: ${paymentStatus.runtimeType}');
        }
        return paymentStatus;
      } else {
        throw Exception('Erro ao validar pagamento: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao processar o pagamento: $e');
    }
  }
}
