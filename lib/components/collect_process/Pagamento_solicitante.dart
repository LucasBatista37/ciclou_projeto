import 'dart:convert';
import 'package:flutter/material.dart';

class PagamentoSolicitanteQRCodeCard extends StatelessWidget {
  final String qrCodeSolicitanteBase64;
  final String qrCodeTextSolicitante;
  final VoidCallback onCopiarCodigoSolicitante;
  final VoidCallback onConfirmarPagamentoSolicitante;

  const PagamentoSolicitanteQRCodeCard({
    Key? key,
    required this.qrCodeSolicitanteBase64,
    required this.qrCodeTextSolicitante,
    required this.onCopiarCodigoSolicitante,
    required this.onConfirmarPagamentoSolicitante,
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
                'Pagamento com QR Code para o Solicitante',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Use o QR Code para efetuar o pagamento ao solicitante. Após isso, confirme o pagamento.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Image.memory(
                  base64Decode(qrCodeSolicitanteBase64),
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Código QR do Solicitante:',
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
                  '${qrCodeTextSolicitante.substring(0, 22)}...',
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
                    onPressed: onCopiarCodigoSolicitante,
                    icon: const Icon(Icons.copy, color: Colors.white),
                    label: const Text(
                      'Copiar Código',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
                    onPressed: onConfirmarPagamentoSolicitante,
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
          ),
        ),
      ),
    );
  }
}