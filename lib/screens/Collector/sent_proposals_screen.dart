import 'package:flutter/material.dart';

class SentProposalsScreen extends StatelessWidget {
  const SentProposalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propostas = [
      {
        'tipoEstabelecimento': 'Restaurante',
        'quantidade': '10 Litros',
        'preco': 'R\$ 5,00 por Litro',
        'dataEnvio': '10/11/2024',
        'status': 'Pendente',
      },
      {
        'tipoEstabelecimento': 'Escola',
        'quantidade': '20 Litros',
        'preco': 'R\$ 4,50 por Litro',
        'dataEnvio': '08/11/2024',
        'status': 'Aceita',
      },
      {
        'tipoEstabelecimento': 'Condomínio',
        'quantidade': '15 Litros',
        'preco': 'R\$ 4,00 por Litro',
        'dataEnvio': '05/11/2024',
        'status': 'Rejeitada',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Propostas Enviadas',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: propostas.length,
        itemBuilder: (context, index) {
          final proposta = propostas[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(proposta['tipoEstabelecimento']!),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantidade: ${proposta['quantidade']}'),
                  Text('Preço: ${proposta['preco']}'),
                  Text('Data de Envio: ${proposta['dataEnvio']}'),
                ],
              ),
              trailing: _buildStatusIcon(proposta['status']!),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'Pendente':
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case 'Aceita':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'Rejeitada':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }
}
