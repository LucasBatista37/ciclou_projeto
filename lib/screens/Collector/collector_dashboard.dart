import 'dart:io';

import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/collector_notifications_screen.dart';
import 'package:ciclou_projeto/screens/Collector/collects_screen.dart';
import 'package:ciclou_projeto/screens/Collector/payment_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_notifications_screen.dart';
import 'package:ciclou_projeto/screens/register_requestor_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ciclou_projeto/components/custom_collector_navigationbar.dart';
import 'package:ciclou_projeto/components/custom_drawer.dart';
import 'package:ciclou_projeto/screens/Collector/collect_history_screen.dart';
import 'package:ciclou_projeto/screens/Collector/sent_proposals_screen.dart';
import 'package:ciclou_projeto/screens/Collector/request_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CollectorDashboard extends StatefulWidget {
  final UserModel user;

  const CollectorDashboard({super.key, required this.user});

  @override
  _CollectorDashboardState createState() => _CollectorDashboardState();
}

class _CollectorDashboardState extends State<CollectorDashboard> {
  int _selectedIndex = 0;
  bool _showAll = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('collector')
                  .doc(widget.user.userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  print('Erro no snapshot: ${snapshot.error}');
                  return const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.error, color: Colors.white),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  print('Documento não encontrado ou vazio.');
                  return const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final profileImageUrl = data['photoUrl'];
                final responsibleName = data['responsible'] ?? '';

                ImageProvider? imageProvider;

                if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
                  if (profileImageUrl.startsWith('http')) {
                    imageProvider = NetworkImage(profileImageUrl);
                  } else {
                    imageProvider = FileImage(File(profileImageUrl));
                  }
                }

                return CircleAvatar(
                  radius: 24,
                  backgroundImage: imageProvider,
                  backgroundColor: Colors.grey.shade300,
                  child: imageProvider == null
                      ? Text(
                          responsibleName.isNotEmpty
                              ? responsibleName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ),
        title: Text(
          'Bem-vindo, ${widget.user.responsible}!',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CollectorNotificationsScreen(
                    collectorId: widget.user.userId,
                    user: widget.user,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('collector')
            .doc(widget.user.userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Drawer(
              child: Center(child: Text('Erro ao carregar o perfil.')),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final profileImageUrl = data['photoUrl'];

          return CustomDrawer(
            userName: widget.user.responsible,
            userEmail: widget.user.email,
            profileImageUrl: profileImageUrl,
            onEditProfile: () {},
            onSettings: () {},
            onLogout: () {
              FirebaseAuth.instance.signOut().then((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterRequestorScreen()),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao fazer logout: $error')),
                );
              });
            },
          );
        },
      ),
      body: _getBodyContent(),
      bottomNavigationBar: CollectorBottomNavigationBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return CollectsScreen(
          collectorId: widget.user.userId,
        );
      case 2:
        return CollectorHistoryScreen(
          collectorId: widget.user.userId,
        );
      case 3:
        return const PaymentScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.lightGreen,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Text(
              'Dica: Verifique as solicitações próximas para otimizar suas rotas!',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionButton(
                  Icons.local_shipping, 'Coletas Ativas', Colors.blue),
              _buildQuickActionButton(
                  Icons.send, 'Propostas Enviadas', Colors.orange),
              _buildQuickActionButton(Icons.history, 'Histórico', Colors.green),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Solicitações Disponíveis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          _buildSolicitationsList(),
          const SizedBox(height: 16.0),
          const Text(
            'Estatísticas de Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Coletado', '120 Litros', Colors.teal),
              _buildStatCard('Ganhos', 'R\$ 1,200', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coletas')
          .where('status', isEqualTo: 'Pendente')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 80, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Erro ao carregar solicitações.',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty, // Ícone de lista vazia
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhuma solicitação disponível no momento.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final documents = snapshot.data!.docs;
        final int itemCount = _showAll
            ? documents.length
            : (documents.length < 3 ? documents.length : 3);

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final data = documents[index].data() as Map<String, dynamic>;
                final documentId = documents[index].id;

                return _buildSolicitationCard(
                  data['tipoEstabelecimento'] ?? 'N/A',
                  '${data['quantidadeOleo'] ?? 'N/A'} Litros',
                  data['prazo'] ?? 'N/A',
                  data['comentarios'] ?? 'Sem observações',
                  documentId,
                );
              },
            ),
            if (documents.length > 3)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
                child: Text(_showAll ? 'Ver Menos' : 'Ver Mais'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        if (label == 'Coletas Ativas') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectsScreen(
                collectorId: widget.user.userId,
              ),
            ),
          );
        } else if (label == 'Propostas Enviadas') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SentProposalsScreen(
                collectorId: widget.user.userId,
              ),
            ),
          );
        } else if (label == 'Histórico') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectorHistoryScreen(
                collectorId: widget.user.userId,
              ),
            ),
          );
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 4.0),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSolicitationCard(String title, String quantity, String prazo,
      String comentarios, String documentId) {
    final formattedPrazo =
        DateTime.tryParse(prazo)?.toLocal().toString().split(' ')[0] ?? prazo;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text('$quantity - Prazo: $formattedPrazo'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestDetails(
                tipoEstabelecimento: title,
                quantidadeOleo: quantity,
                prazo: prazo,
                endereco: 'Endereço não disponível',
                observacoes: comentarios,
                documentId: documentId,
                user: widget.user,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
