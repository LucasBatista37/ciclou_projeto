import 'package:flutter/material.dart';

class CustomCertificate extends StatelessWidget {
  final String nomeColetor;
  final String data;
  final String quantidade;
  final String endereco;

  const CustomCertificate({
    super.key,
    required this.nomeColetor,
    required this.data,
    required this.quantidade,
    required this.endereco,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Certificado de Destinação Final',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          Text('Coletor: $nomeColetor', style: const TextStyle(fontSize: 16)),
          Text('Data: $data', style: const TextStyle(fontSize: 16)),
          Text('Quantidade Coletada: $quantidade Litros',
              style: const TextStyle(fontSize: 16)),
          Text('Endereço: $endereco', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16.0),
          const Text(
            'Este certificado comprova que o óleo coletado foi devidamente destinado, contribuindo para a sustentabilidade ambiental.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
