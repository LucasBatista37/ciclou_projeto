import 'package:ciclou_projeto/screens/Collector/send_proposal.dart';
import 'package:flutter/material.dart';

class RequestDetails extends StatelessWidget {
  final String tipoEstabelecimento;
  final String quantidadeOleo;
  final String prazo;
  final String endereco;
  final String observacoes;

  const RequestDetails({
    super.key,
    required this.tipoEstabelecimento,
    required this.quantidadeOleo,
    required this.prazo,
    required this.endereco,
    required this.observacoes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Detalhes da Solicitação',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de Estabelecimento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              tipoEstabelecimento,
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24.0, thickness: 1.0),
            const Text(
              'Quantidade de Óleo Estimada',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              quantidadeOleo,
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24.0, thickness: 1.0),
            const Text(
              'Prazo para Propostas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              prazo,
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24.0, thickness: 1.0),
            const Text(
              'Endereço',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              endereco,
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 24.0, thickness: 1.0),
            const Text(
              'Observações Adicionais',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              observacoes.isNotEmpty ? observacoes : 'Nenhuma observação',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24.0),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 12.0),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SendProposal(),
                    ),
                  );
                },
                child: const Text(
                  'Enviar Proposta',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
