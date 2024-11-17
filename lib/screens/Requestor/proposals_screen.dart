import 'package:flutter/material.dart';

class ProposalsScreen extends StatelessWidget {
  final String solicitationTitle;
  final List<Map<String, dynamic>> proposals = [
    {
      'collectorName': 'Coletor João',
      'pricePerLiter': 'R\$ 2,50',
      'comments': 'Posso coletar amanhã pela manhã.',
      'status': 'Pendente'
    },
    {
      'collectorName': 'Coletor Maria',
      'pricePerLiter': 'R\$ 2,70',
      'comments': 'Disponível hoje à tarde.',
      'status': 'Pendente'
    },
    {
      'collectorName': 'Coletor Pedro',
      'pricePerLiter': 'R\$ 2,30',
      'comments': 'Pronto para coletar agora.',
      'status': 'Pendente'
    },
  ];

  ProposalsScreen({super.key, required this.solicitationTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Propostas para $solicitationTitle',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: proposals.length,
          itemBuilder: (context, index) {
            final proposal = proposals[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal['collectorName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Preço por Litro: ${proposal['pricePerLiter']}'),
                    Text('Comentários: ${proposal['comments']}'),
                    Text(
                      'Status: ${proposal['status']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _rejectProposal(context, proposal['collectorName']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            'Rejeitar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            _acceptProposal(context, proposal['collectorName']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            'Aceitar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _acceptProposal(BuildContext context, String collectorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceitar Proposta'),
        content: Text(
            'Você tem certeza que deseja aceitar a proposta de $collectorName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Proposta de $collectorName aceita!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Aceitar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _rejectProposal(BuildContext context, String collectorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Proposta'),
        content: Text(
            'Você tem certeza que deseja rejeitar a proposta de $collectorName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Proposta de $collectorName rejeitada!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Rejeitar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 