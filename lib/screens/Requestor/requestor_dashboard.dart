import 'dart:io';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_notifications_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_stats_screen.dart';
import 'package:ciclou_projeto/screens/register_requestor_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ciclou_projeto/components/requestor_drawer.dart';
import 'package:ciclou_projeto/components/custom_requestor_navigationbar.dart';
import 'package:ciclou_projeto/screens/Requestor/create_collection_screen.dart';
import 'package:ciclou_projeto/screens/Collector/payment_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_history_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/proposals_screen.dart';

class RequestorDashboard extends StatefulWidget {
  final UserModel user;

  const RequestorDashboard({super.key, required this.user});

  @override
  _RequestorDashboardState createState() => _RequestorDashboardState();
}

class _RequestorDashboardState extends State<RequestorDashboard> {
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
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requestor')
                  .doc(widget.user.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.error, color: Colors.white),
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
          'Olá, ${widget.user.responsible}!',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('requestorId', isEqualTo: widget.user.userId)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestorNotificationsScreen(
                          requestorId: widget.user.userId,
                        ),
                      ),
                    );
                  },
                );
              }

              final unreadCount = snapshot.data!.docs.length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestorNotificationsScreen(
                            requestorId: widget.user.userId,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requestor')
            .doc(widget.user.userId)
            .snapshots(),
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

          return RequestorDrawer(
            userName: widget.user.responsible,
            userEmail: widget.user.email,
            profileImageUrl: profileImageUrl,
            user: widget.user,
            onEditProfile: () {},
            onSettings: () {},
            onLogout: () async {
              try {
                await FirebaseAuth.instance.signOut();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterRequestorScreen(),
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao fazer logout: $error')),
                );
              }
            },
          );
        },
      ),
      body: _getBodyContent(),
      bottomNavigationBar: CustomBottomNavigationBar(
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
        return CreateCollection(user: widget.user);
      case 2:
        return RequestorHistoryScreen(userId: widget.user.userId);
      case 3:
        return PaymentScreen(user: widget.user);
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
              'Dica: Recicle seu óleo e ajude o meio ambiente!',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionButton(
                  Icons.add_circle, 'Solicitar Coleta', Colors.green),
              _buildQuickActionButton(Icons.map, 'Mapa', Colors.blue),
              _buildQuickActionButton(
                  Icons.bar_chart, 'Relatórios', Colors.orange),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text('Minhas Solicitações Ativas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          _buildSolicitationsList(),
          const SizedBox(height: 16.0),
          const Text('Estatísticas de Sustentabilidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('coletas')
                .where('userId', isEqualTo: widget.user.userId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text(
                    'Erro ao carregar estatísticas.',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                );
              }

              final coletas = snapshot.data!.docs;
              double totalOil = 0.0;

              for (var doc in coletas) {
                final data = doc.data() as Map<String, dynamic>;
                if (data.containsKey('quantidadeReal') &&
                    data['quantidadeReal'] != null) {
                  totalOil += (data['quantidadeReal'] ?? 0).toDouble();
                }
              }

              final double avoidedCO2 = totalOil * 5.24;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Óleo Coletado',
                      '${totalOil.toStringAsFixed(1)} L',
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'CO₂ Evitado',
                      '${avoidedCO2.toStringAsFixed(0)} Kg',
                      Colors.green,
                    ),
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        if (label == 'Solicitar Coleta') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateCollection(user: widget.user),
            ),
          );
        } else if (label == 'Relatórios') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RequesterStatsScreen(userId: widget.user.userId),
            ),
          );
        } else if (label == 'Mapa') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(user: widget.user),
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
          const SizedBox(height: 4.0),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSolicitationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coletas')
          .where('userId', isEqualTo: widget.user.userId)
          .where('status', whereIn: ['Pendente', 'Em andamento'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar solicitações.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhuma solicitação ativa no momento.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final documents = snapshot.data!.docs;
        final itemCount =
            documents.length < 3 || _showAll ? documents.length : 3;

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
                  data['status'] ?? 'N/A',
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

  Widget _buildSolicitationCard(
      String title, String quantity, String status, String documentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .snapshots(),
      builder: (context, snapshot) {
        final numPropostas = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('coletas')
              .doc(documentId)
              .get(),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = futureSnapshot.data!.data() as Map<String, dynamic>;
            final prazo = DateTime.parse(
                data['prazo'] ?? DateTime.now().toIso8601String());
            final tempoRestante = prazo.difference(DateTime.now());

            final tempoRestanteStr = tempoRestante.isNegative
                ? 'Tempo esgotado'
                : '${tempoRestante.inMinutes} minutos restantes';

            double progress = tempoRestante.isNegative
                ? 1.0
                : 1.0 - (tempoRestante.inSeconds / (24 * 60 * 60));

            Color statusColor;
            switch (status) {
              case 'Pendente':
                statusColor = Colors.amber; // Amarelo
                break;
              case 'Em andamento':
                statusColor = Colors.green; // Verde
                break;
              case 'Concluído':
                statusColor = Colors.blue; // Azul
                break;
              default:
                statusColor = Colors.grey;
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProposalsScreen(
                      solicitationTitle: title,
                      documentId: documentId,
                      user: widget.user,
                    ),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          const Icon(Icons.oil_barrel,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 4.0),
                          Text(quantity),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 18, color: Colors.grey),
                          const SizedBox(width: 4.0),
                          Text(tempoRestanteStr),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          const Icon(Icons.group, size: 18, color: Colors.grey),
                          const SizedBox(width: 4.0),
                          Text('Propostas: $numPropostas'),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade300,
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
