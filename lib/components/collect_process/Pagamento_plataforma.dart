import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PagamentoQRCodeCard extends StatelessWidget {
  final String? qrCodeText;
  final String qrCodeBase64;
  final VoidCallback onCopiarCodigo;
  final VoidCallback onRevalidarPagamento;

  const PagamentoQRCodeCard({
    Key? key,
    required this.qrCodeBase64,
    this.qrCodeText,
    required this.onCopiarCodigo,
    required this.onRevalidarPagamento,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 5,
        shadowColor: Colors.grey.shade300,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Pagamento com QR Code para a Plataforma',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Use o QR Code para efetuar o pagamento para a plataforma. Após isso, poderá visualizar o endereço e pagar o solicitante.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Image.memory(
                  base64Decode(qrCodeBase64),
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 20),
              if (qrCodeText != null) ...[
                const Text(
                  'Código QR:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: SelectableText(
                    '${qrCodeText!.substring(0, 22)}...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontFamily: 'Courier',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onCopiarCodigo,
                      icon: const Icon(Icons.copy, color: Colors.white),
                      label: const Text(
                        'Copiar Código',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onRevalidarPagamento,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Já Paguei',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
