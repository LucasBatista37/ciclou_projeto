import 'package:ciclou_projeto/components/generate_manualqr_payment.dart';
import 'package:ciclou_projeto/components/payment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class CollectService {
  static Future<Map<String, dynamic>> verificarPagamentoComCodigo(
      String coletaId) async {
    String? paymentStatus;
    String? confirmationCode;

    try {
      final proposalSnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(coletaId)
          .collection('propostas')
          .where('status', isEqualTo: 'Aceita')
          .get();

      if (proposalSnapshot.docs.isNotEmpty) {
        final proposalData = proposalSnapshot.docs.first.data();
        final paymentId = proposalData['paymentId'];

        if (paymentId != null) {
          final paymentService = PaymentService(paymentId);
          paymentStatus = await paymentService.validatePayment();
          developer.log("Status do pagamento: $paymentStatus");

          if (paymentStatus == 'approved') {
            confirmationCode = await _generateConfirmationCode(coletaId);
          }
        } else {
          developer.log("Nenhum ID de pagamento encontrado na proposta.");
        }
      }
    } catch (e, stack) {
      developer.log("Erro ao verificar status do pagamento: $e",
          error: e, stackTrace: stack);
      rethrow;
    }

    return {
      'paymentStatus': paymentStatus,
      'confirmationCode': confirmationCode,
    };
  }

  static Future<double> getValorTotalPago(String coletaId) async {
    try {
      final proposalSnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(coletaId)
          .collection('propostas')
          .where('status', isEqualTo: 'Aceita')
          .get();

      if (proposalSnapshot.docs.isNotEmpty) {
        final proposalData = proposalSnapshot.docs.first.data();
        final valorTotalPagoRaw = proposalData['valorTotalPago'];
        final valorTotalPago = valorTotalPagoRaw is double
            ? valorTotalPagoRaw
            : double.tryParse(valorTotalPagoRaw.toString()) ?? 0.0;
        return valorTotalPago;
      }
    } catch (e) {
      rethrow;
    }
    return 0.0;
  }

  static Future<String> _generateConfirmationCode(String coletaId) async {
    try {
      final coletaDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(coletaId)
          .get();
      final data = coletaDoc.data() as Map<String, dynamic>;

      final result = await generateManualQr(
        pixKey: data['chavePix'],
        amount: data['quantidadeOleo'] ?? 0.0,
        description:
            'Confirmação de coleta para ${data['tipoEstabelecimento']}',
      );

      final confirmationCode = result['confirmationCode'] as String;

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(coletaId)
          .update({
        'confirmationCode': confirmationCode,
      });

      developer
          .log("Código de confirmação salvo com sucesso na coleta $coletaId");

      return confirmationCode;
    } catch (e) {
      developer.log("Erro ao gerar código de confirmação: $e");
      throw Exception('Erro ao gerar código de confirmação: $e');
    }
  }
}