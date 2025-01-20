import 'package:ciclou_projeto/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class GenerateQRCodeButton extends StatefulWidget {
  final String documentId;
  final double amount;
  final String proposalId;
  final UserModel user;
  final void Function(String qrCodeBase64, String qrCodeText) onSuccess;

  const GenerateQRCodeButton({
    super.key,
    required this.documentId,
    required this.amount,
    required this.proposalId,
    required this.user,
    required this.onSuccess,
  });

  @override
  State<GenerateQRCodeButton> createState() => _GenerateQRCodeButtonState();
}

class _GenerateQRCodeButtonState extends State<GenerateQRCodeButton> {
  bool _isGeneratingQRCode = false;

  Future<void> _generateQRCode() async {
    setState(() {
      _isGeneratingQRCode = true;
    });

    try {
      final qrCodeData = await _generateFixedPixPayment(
        amount: widget.amount.toStringAsFixed(2),
        user: widget.user,
        documentId: widget.documentId,
      );

      if (qrCodeData != null) {
        // Atualiza o campo em "propostas"
        await FirebaseFirestore.instance
            .collection('coletas')
            .doc(widget.documentId)
            .collection('propostas')
            .doc(widget.proposalId)
            .update({
          'qrCodeSolicitante': qrCodeData['qrCode'],
          'qrCodeTextSolicitante': qrCodeData['qrCodeBase64'],
          'paymentIdSolicitante': qrCodeData['paymentId'],
        });

        await FirebaseFirestore.instance
            .collection('coletas')
            .doc(widget.documentId)
            .update({
          'realQuantityCollected': true,
        });

        widget.onSuccess(qrCodeData['qrCodeBase64'], qrCodeData['qrCode']);

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code gerado com sucesso!')),
        );
      } else {
        throw Exception('Falha ao gerar QR Code.');
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar QR Code: $e')),
      );
      developer.log('Erro ao gerar QR Code:', error: e);
    } finally {
      setState(() {
        _isGeneratingQRCode = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _generateFixedPixPayment({
    required String amount,
    required UserModel user,
    required String documentId,
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
        return {
          'qrCode': data['qrCode'],
          'qrCodeBase64': data['qrCodeBase64'],
          'paymentId': data['paymentId'].toString(),
        };
      } else {
        return null;
      }
    } catch (e) {
      developer.log('Erro ao chamar a API de pagamento PIX:', error: e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _isGeneratingQRCode ? null : _generateQRCode,
        icon: _isGeneratingQRCode
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.qr_code, color: Colors.white),
        label: const Text(
          'Gerar QR Code para Solicitante',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isGeneratingQRCode ? Colors.grey : Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }
}
