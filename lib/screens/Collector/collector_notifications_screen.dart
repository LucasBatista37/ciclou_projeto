import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/collect_process.dart';
import 'package:ciclou_projeto/screens/Collector/payment_screen.dart';
import 'package:ciclou_projeto/screens/Collector/send_proposal.dart';
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

  void _markNotificationsAsRead() {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('collectorId', isEqualTo: collectorId)
        .where('isRead', isEqualTo: false)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        doc.reference.update({'isRead': true});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _markNotificationsAsRead());

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
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 10.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                color: isRead ? Colors.white : Colors.green.shade50,
                child: ListTile(
                  leading: Icon(
                    _getIconForNotification(data['title'] ?? ''),
                    color: _getColorForNotification(data['title'] ?? ''),
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
                        (data['timestamp'] as Timestamp?)
                                ?.toDate()
                                .toString() ??
                            '',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () => _handleNotificationTap(
                    context,
                    data['title'] ?? '',
                    notification,
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
      case 'Pagamento Recebido':
        return Icons.payment;
      case 'Solicitação Cancelada':
        return Icons.cancel_schedule_send;
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
      case 'Pagamento Recebido':
        return Colors.blue;
      case 'Solicitação Cancelada':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(
      BuildContext context, String title, DocumentSnapshot notification) async {
    if (title == 'Proposta Aceita!') {
      final data = notification.data() as Map<String, dynamic>;
      final coletaId = data['coletaId'];

      if (coletaId != null) {
        try {
          final coletaDoc = await FirebaseFirestore.instance
              .collection('coletas')
              .doc(coletaId)
              .get();

          if (coletaDoc.exists) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CollectProcess(
                  coletaAtual: coletaDoc,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coleta não encontrada.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao buscar coleta: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ID da coleta não encontrado na notificação.')),
        );
      }
    } else if (title == 'Pagamento Recebido') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(user: user),
        ),
      );
    } else if (title == 'Proposta Rejeitada') {
      final data = notification.data() as Map<String, dynamic>;
      final coletaId = data['coletaId'];

      if (coletaId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SendProposal(
              documentId: coletaId,
              user: user,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ID da coleta não encontrado na notificação.')),
        );
      }
    }
  }
}