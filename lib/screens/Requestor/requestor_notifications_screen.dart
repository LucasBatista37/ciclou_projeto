import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestorNotificationsScreen extends StatelessWidget {
  final String requestorId;

  const RequestorNotificationsScreen({super.key, required this.requestorId});

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
            .where('requestorId', isEqualTo: requestorId)
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
            return _buildEmptyState();
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data()
                  as Map<String, dynamic>; // Dados da notificação
              return _buildNotificationCard(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Nenhuma notificação encontrada.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, Map<String, dynamic> notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(
          _getIconForNotification(notification['title']),
          color: _getColorForNotification(notification['title']),
        ),
        title: Text(
          notification['title'] ?? 'Notificação',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(notification['message'] ?? ''),
        trailing: Text(
          _formatTimestamp(notification['timestamp']),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  IconData _getIconForNotification(String? title) {
    switch (title) {
      case 'Nova Proposta Recebida!':
        return Icons.email;
      case 'Coleta Confirmada':
        return Icons.check_circle;
      case 'Proposta Aceita':
        return Icons.thumb_up;
      case 'Coleta Concluída':
        return Icons.done_all;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForNotification(String? title) {
    switch (title) {
      case 'Nova Proposta Recebida!':
        return Colors.blue;
      case 'Coleta Confirmada':
        return Colors.green;
      case 'Proposta Aceita':
        return Colors.orange;
      case 'Coleta Concluída':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Agora';
    final dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute}';
  }
}
