import 'package:ciclou_projeto/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'collector_dashboard.dart'; 

class PaymentProcessingScreen extends StatefulWidget {
  final String paymentId;
  final String qrCodeBase64;
  final UserModel user; 

  const PaymentProcessingScreen({
    required this.paymentId,
    required this.qrCodeBase64,
    required this.user, 
    super.key,
  });

  @override
  _PaymentProcessingScreenState createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _validatePayment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://api-mercado-pago-ciclou.vercel.app/pix/validate_pix_payment/${widget.paymentId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentStatus = data['paymentStatus'];

        if (paymentStatus == "approved") {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CollectorDashboard(
                user: widget.user, 
              ),
            ),
          );
        } else if (paymentStatus == "pending") {
          setState(() {
            _statusMessage = 'Pagamento pendente. Tente novamente mais tarde.';
          });
        } else {
          setState(() {
            _statusMessage = 'Pagamento não aprovado. Verifique os detalhes.';
          });
        }
      } else {
        throw Exception('Erro ao validar pagamento: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao processar o pagamento: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List qrCodeBytes = base64Decode(widget.qrCodeBase64);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento PIX'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Escaneie o QR Code para realizar o pagamento:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            Image.memory(
              qrCodeBytes,
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 24.0),
            if (_statusMessage != null) ...[
              Text(
                _statusMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
            ],
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              onPressed: _isLoading ? null : _validatePayment,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Já Paguei'),
            ),
          ],
        ),
      ),
    );
  }
}
