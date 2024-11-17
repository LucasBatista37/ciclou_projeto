import 'package:ciclou_projeto/screens/Collector/collect_process.dart';
import 'package:ciclou_projeto/screens/Collector/collector_map_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/payment_screen.dart';
import 'package:flutter/material.dart';

class CollectorNotificationsScreen extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      'title': 'Proposta Aceita!',
      'message':
          'Sua proposta para o Restaurante foi aceita. Prepare-se para a coleta!',
      'time': '5 minutos atrás',
    },
    {
      'title': 'Nova Solicitação Próxima',
      'message':
          'Um novo condomínio precisa de coleta de óleo. Veja os detalhes.',
      'time': '10 minutos atrás',
    },
    {
      'title': 'Pagamento Recebido',
      'message':
          'Você recebeu R\$ 500 pelo serviço de coleta no Escola Municipal.',
      'time': '1 hora atrás',
    },
    {
      'title': 'Solicitação Cancelada',
      'message':
          'O Solicitante cancelou a coleta agendada. Verifique o histórico.',
      'time': '3 horas atrás',
    },
  ];

  CollectorNotificationsScreen({super.key});

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

  IconData _getIconForNotification(String title) {
    switch (title) {
      case 'Proposta Aceita!':
        return Icons.check_circle;
      case 'Nova Solicitação Próxima':
        return Icons.location_on;
      case 'Pagamento Recebido':
        return Icons.attach_money;
      case 'Solicitação Cancelada':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForNotification(String title) {
    switch (title) {
      case 'Proposta Aceita!':
        return Colors.green;
      case 'Nova Solicitação Próxima':
        return Colors.blue;
      case 'Pagamento Recebido':
        return Colors.teal;
      case 'Solicitação Cancelada':
        return Colors.red;
      default:
        return Colors.grey;
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
      case 'Nova Solicitação Próxima':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CollectorMapScreen()),
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
}
