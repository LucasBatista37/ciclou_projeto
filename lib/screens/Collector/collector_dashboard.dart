import 'dart:io';
import 'package:ciclou_projeto/components/collector_drawer.dart';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/collector_notifications_screen.dart';
import 'package:ciclou_projeto/screens/Collector/collects_screen.dart';
import 'package:ciclou_projeto/screens/Collector/manual_qr_payment_screen.dart';
import 'package:ciclou_projeto/screens/Collector/payment_screen.dart';
import 'package:ciclou_projeto/screens/register_collector_screen.dart';
import 'package:ciclou_projeto/screens/register_requestor_screen.dart';
import 'package:ciclou_projeto/screens/support_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ciclou_projeto/components/custom_collector_navigationbar.dart';
import 'package:ciclou_projeto/components/requestor_drawer.dart';
import 'package:ciclou_projeto/screens/Collector/collect_history_screen.dart';
import 'package:ciclou_projeto/screens/Collector/collector_stats_screen.dart';
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
  String _currentTip = "Carregando dica...";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentTip();
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('collectorId', isEqualTo: widget.user.userId)
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
                        builder: (context) => CollectorNotificationsScreen(
                          collectorId: widget.user.userId,
                          user: widget.user,
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
                          builder: (context) => CollectorNotificationsScreen(
                            collectorId: widget.user.userId,
                            user: widget.user,
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

          return CollectorDrawer(
            userName: widget.user.responsible,
            userEmail: widget.user.email,
            profileImageUrl: profileImageUrl,
            onEditProfile: () {},
            onSettings: () {},
            onLogout: () async {
              try {
                await FirebaseAuth.instance.signOut();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterCollectorScreen(),
                  ),
                  (route) => false,
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
        return SupportScreen();
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
            child: Text(
              _currentTip,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionButton(
                  Icons.local_shipping, 'Coletas Ativas', Colors.blue),
              _buildQuickActionButton(
                  Icons.bar_chart, 'Estatísticas', Colors.orange),
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
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('collector')
                .doc(widget.user.userId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!.exists) {
                return const Center(
                  child: Text(
                    'Erro ao carregar estatísticas.',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final double totalLiters = (data['amountOil'] ?? 0).toDouble();
              final double avoidedCO2 = totalLiters * 5.24;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Óleo Coletado',
                      '${totalLiters.toStringAsFixed(1)} L',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'CO₂ Evitado',
                      '${avoidedCO2.toStringAsFixed(0)} Kg',
                      Colors.teal,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCurrentTip() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tips')
          .where('isCollector', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _currentTip = querySnapshot.docs.first['tipDescription'];
        });
      } else {
        setState(() {
          _currentTip = "Nenhuma dica cadastrada.";
        });
      }
    } catch (e) {
      setState(() {
        _currentTip = "Erro ao carregar a dica.";
      });
      print("Erro ao buscar dica: $e");
    }
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
                  Icons.hourglass_empty,
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

                final funcionamentoDias = data['funcionamentoDias'];
                final funcionamentoHorario = data['funcionamentoHorario'];
                final region = data['region'] ?? 'Região não especificada';

                final diasFormatted = funcionamentoDias is List<dynamic>
                    ? funcionamentoDias.join(', ')
                    : funcionamentoDias ?? 'N/A';

                final horarioFormatted = funcionamentoHorario is List<dynamic>
                    ? funcionamentoHorario.join(', ')
                    : funcionamentoHorario ?? 'N/A';

                return _buildSolicitationCard(
                  data['tipoEstabelecimento'] ?? 'N/A',
                  '${data['quantidadeOleo'] ?? 'N/A'} Litros',
                  data['prazo'] ?? 'N/A',
                  region,
                  documentId,
                  diasFormatted,
                  horarioFormatted,
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
        } else if (label == 'Estatísticas') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectorStatsScreen(
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

  Widget _buildSolicitationCard(
      String title,
      String quantity,
      String prazo,
      String region,
      String documentId,
      String funcionamentoDias,
      String funcionamentoHorario) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('Erro ao carregar informações da coleta.'),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isNetCollection = data['IsNetCollection'] ?? false;

        final formattedPrazo =
            DateTime.tryParse(prazo)?.toLocal() ?? DateTime.now();
        final tempoRestante = formattedPrazo.difference(DateTime.now());

        final bool isPrazoEsgotado = tempoRestante.isNegative;

        return GestureDetector(
          onTap: isPrazoEsgotado
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestDetails(
                        tipoEstabelecimento: title,
                        quantidadeOleo: quantity,
                        prazo: prazo,
                        endereco: 'Endereço não disponível',
                        observacoes: region,
                        documentId: documentId,
                        funcionamentoDias: funcionamentoDias,
                        funcionamentoHorario: funcionamentoHorario,
                        user: widget.user,
                      ),
                    ),
                  );
                },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
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
                          color: isPrazoEsgotado
                              ? Colors.red.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          isPrazoEsgotado ? 'Esgotado' : 'Ativo',
                          style: TextStyle(
                            fontSize: 12,
                            color: isPrazoEsgotado ? Colors.red : Colors.green,
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
                      Text(
                        'Prazo: ${formattedPrazo.toString().split(' ')[0]}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          region,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (isNetCollection)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.star, size: 16, color: Colors.yellow),
                            SizedBox(width: 4.0),
                            Text(
                              'Módulo Rede',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  LinearProgressIndicator(
                    value: isPrazoEsgotado
                        ? 1.0
                        : 1.0 - (tempoRestante.inSeconds / (24 * 60 * 60)),
                    backgroundColor: Colors.grey.shade300,
                    color: isPrazoEsgotado ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
