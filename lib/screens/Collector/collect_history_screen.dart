import 'package:flutter/material.dart';

class CollectorHistoryScreen extends StatefulWidget {
  const CollectorHistoryScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CollectorHistoryScreenState createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends State<CollectorHistoryScreen> {
  final List<Map<String, String>> _historico = [
    {'data': '10/11/2024', 'quantidade': '15 Litros', 'status': 'Concluída'},
    {'data': '05/11/2024', 'quantidade': '20 Litros', 'status': 'Em andamento'},
    {'data': '01/11/2024', 'quantidade': '10 Litros', 'status': 'Concluída'},
    {'data': '28/10/2024', 'quantidade': '30 Litros', 'status': 'Cancelada'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Histórico de Coletas',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildHistoryList(),
    );
  }

  Widget _buildHistoryList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _historico.isEmpty
          ? const Center(child: Text('Nenhuma coleta registrada.'))
          : ListView.builder(
              itemCount: _historico.length,
              itemBuilder: (context, index) {
                final coleta = _historico[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text('Coleta em: ${coleta['data']}'),
                    subtitle: Text('Quantidade: ${coleta['quantidade']}'),
                    trailing: _buildStatusTag(coleta['status']!),
                    onTap: () {},
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Concluída':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Em andamento':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'Cancelada':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, color: statusColor, size: 18.0),
        const SizedBox(width: 4.0),
        Text(
          status,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
