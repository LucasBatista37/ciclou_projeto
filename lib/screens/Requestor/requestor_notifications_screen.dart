import 'package:flutter/material.dart';

class RequestorNotificationsScreen extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      'title': 'Nova Proposta Recebida!',
      'message':
          'Um coletor enviou uma proposta para a sua solicitação no Restaurante.',
      'time': '10 minutos atrás',
    },
    {
      'title': 'Coleta Confirmada',
      'message':
          'O coletor confirmou que está a caminho para a coleta agendada.',
      'time': '30 minutos atrás',
    },
    {
      'title': 'Proposta Aceita',
      'message': 'Sua proposta foi aceita pelo coletor. Aguarde a coleta.',
      'time': '1 hora atrás',
    },
    {
      'title': 'Coleta Concluída',
      'message':
          'A coleta foi realizada com sucesso. Avalie o serviço do coletor.',
      'time': '2 horas atrás',
    },
  ];

  RequestorNotificationsScreen({super.key});

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
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: ListTile(
              leading: Icon(
                _getIconForNotification(notification['title']!),
                color: _getColorForNotification(notification['title']!),
              ),
              title: Text(
                notification['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['message']!),
                  const SizedBox(height: 4.0),
                  Text(
                    notification['time']!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              onTap: () =>
                  _handleNotificationTap(context, notification['title']!),
            ),
          );
        },
      ),
    );
  }

  // Helper method to get the appropriate icon for each notification
  IconData _getIconForNotification(String title) {
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

  Color _getColorForNotification(String title) {
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

  void _handleNotificationTap(BuildContext context, String title) {
    switch (title) {
      case 'Nova Proposta Recebida!':
        break;
      case 'Coleta Confirmada':
        break;
      case 'Proposta Aceita':
        break;
      case 'Coleta Concluída':
        break;
      default:
        break;
    }
  }
}
