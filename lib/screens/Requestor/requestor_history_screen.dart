import 'package:ciclou_projeto/models/user_model.dart';
import 'package:flutter/material.dart';

class RequestorHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> history = [
    {
      'date': '12/11/2024',
      'collectorName': 'Coletor João',
      'quantity': '15 Litros',
      'status': 'Concluído'
    },
    {
      'date': '08/11/2024',
      'collectorName': 'Coletor Maria',
      'quantity': '10 Litros',
      'status': 'Concluído'
    },
    {
      'date': '01/11/2024',
      'collectorName': 'Coletor Pedro',
      'quantity': '20 Litros',
      'status': 'Concluído'
    },
  ];

  RequestorHistoryScreen({super.key, required UserModel user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Coletas',
          style: TextStyle(color: Colors.white),
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
          itemCount: history.length,
          itemBuilder: (context, index) {
            final record = history[index];
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
                      'Data: ${record['date']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text('Coletor: ${record['collectorName']}'),
                    Text('Quantidade: ${record['quantity']}'),
                    Text(
                      'Status: ${record['status']}',
                      style: const TextStyle(color: Colors.grey),
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
}
