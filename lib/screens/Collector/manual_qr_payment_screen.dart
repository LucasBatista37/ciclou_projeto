import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManualQrPaymentScreen extends StatefulWidget {
  const ManualQrPaymentScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ManualQrPaymentScreenState createState() => _ManualQrPaymentScreenState();
}

class _ManualQrPaymentScreenState extends State<ManualQrPaymentScreen> {
  final TextEditingController _pixKeyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _qrCodeBase64;
  String? _confirmationCode;

  Future<void> _generateManualQr() async {
    final pixKey = _pixKeyController.text;
    final amount = _amountController.text;
    final description = _descriptionController.text;

    if (pixKey.isEmpty || amount.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _qrCodeBase64 = null;
      _confirmationCode = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api-mercado-pago-ciclou.vercel.app/pix/manual_qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chavePix': pixKey,
          'amount': double.parse(amount),
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _qrCodeBase64 = data['qrCode'];
          _confirmationCode = data['confirmationCode'];
        });
      } else {
        throw Exception('Erro ao gerar QR Code PIX: ${response.body}');
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar Pagamento Manual PIX'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chave PIX',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _pixKeyController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: chavepix@email.com',
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Valor (R\$)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 150.00',
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Descrição',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Pagamento manual PIX',
                ),
              ),
              const SizedBox(height: 24.0),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: _isLoading ? null : _generateManualQr,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Gerar QR Code'),
                ),
              ),
              const SizedBox(height: 24.0),
              if (_qrCodeBase64 != null) ...[
                const Text(
                  'Escaneie o QR Code para realizar o pagamento:',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                Image.memory(
                  base64Decode(
                      _qrCodeBase64!.split(',')[1]), 
                  height: 200,
                  width: 200,
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Código de Confirmação: $_confirmationCode',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}