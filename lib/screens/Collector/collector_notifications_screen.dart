import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/collect_process.dart';
import 'package:ciclou_projeto/screens/Requestor/payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CollectorNotificationsScreen extends StatelessWidget {
  final String collectorId;
  final UserModel user;

  CollectorNotificationsScreen({
    super.key,
    required this.collectorId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Notificações', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('collectorId', isEqualTo: collectorId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar notificações.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhuma notificação disponível no momento.'),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 10.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                child: ListTile(
                  leading: Icon(
                    _getIconForNotification(data['title']!),
                    color: _getColorForNotification(data['title']!),
                  ),
                  title: Text(
                    data['title'] ?? 'Notificação',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message'] ?? ''),
                      const SizedBox(height: 4.0),
                      Text(
                        data['timestamp']?.toDate()?.toString() ?? '',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForNotification(String title) {
    switch (title) {
      case 'Proposta Aceita!':
        return Icons.check_circle;
      case 'Proposta Rejeitada':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForNotification(String title) {
    switch (title) {
      case 'Proposta Aceita!':
        return Colors.green;
      case 'Proposta Rejeitada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

void _handleNotificationTap(BuildContext context, String title) {
  switch (title) {
    case 'Proposta Aceita!':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CollectProcess()),
      );
      break;
    case 'Pagamento Recebido':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentScreen()),
      );
      break;
    case 'Solicitação Cancelada':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CollectProcess()),
      );
      break;
    default:
      break;
  }
}
