import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ciclou_projeto/models/user_model.dart';

class PaymentScreen extends StatelessWidget {
  final UserModel user;
  final String documentId;
  final String proposalId;
  final double quantityOleo;

  const PaymentScreen({
    super.key,
    required this.user,
    required this.documentId,
    required this.proposalId,
    required this.quantityOleo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento Plataforma'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _processPayment(context),
          child: const Text('Gerar QR Code para Pagamento'),
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    try {
      final amount = _calculateAmount(quantityOleo);

      await generateFixedPixPayment(
        amount: amount.toString(),
        user: user,
        documentId: documentId,
        proposalId: proposalId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento gerado com sucesso!')),
      );

      final proposalDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .get();

      final proposalData = proposalDoc.data();
      if (proposalData != null && proposalData['qrCodeBase64'] != null) {
        final qrCodeBase64 = proposalData['qrCodeBase64'];
        _showQrCode(context, qrCodeBase64);
      } else {
        throw Exception('QR Code não encontrado no banco de dados.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar o pagamento: $e')),
      );
    }
  }

  double _calculateAmount(double liters) {
    if (liters >= 20 && liters <= 30) return 7.5;
    if (liters > 30 && liters <= 45) return 10.0;
    if (liters > 45 && liters <= 60) return 12.0;
    if (liters > 60 && liters <= 75) return 14.0;
    if (liters > 75 && liters <= 100) return 16.0;
    throw Exception('Quantidade de litros fora do intervalo permitido.');
  }

  void _showQrCode(BuildContext context, String qrCodeBase64) {
    final Uint8List qrCodeBytes = base64Decode(qrCodeBase64);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code para Pagamento'),
          content: Image.memory(qrCodeBytes),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

Future<void> generateFixedPixPayment({
  required String amount,
  required UserModel user,
  required String documentId,
  required String proposalId,
}) async {
  const String endpoint =
      'https://api-mercado-pago-ciclou.vercel.app/pix/generate_pix_payment';
  const String description = 'Pagamento Plataforma';

  try {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': double.parse(amount),
        'description': description,
        'payerEmail': user.email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final qrCodeBase64 = data['qrCodeBase64'];
      if (qrCodeBase64 != null) {
        await FirebaseFirestore.instance
            .collection('coletas')
            .doc(documentId)
            .collection('propostas')
            .doc(proposalId)
            .update({
          'paymentId': data['paymentId'],
          'qrCodeBase64': qrCodeBase64,
          'statusPagamento': 'Pendente',
        });
      } else {
        throw Exception('QR Code não encontrado na resposta.');
      }
    } else {
      throw Exception('Erro ao gerar pagamento PIX: ${response.body}');
    }
  } catch (e) {
    print('Erro ao gerar o pagamento: $e');
    rethrow;
  }
}