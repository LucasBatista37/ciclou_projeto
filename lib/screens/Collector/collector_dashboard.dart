import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/register_collector_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ciclou_projeto/components/custom_collector_navigationbar.dart';
import 'package:ciclou_projeto/components/custom_drawer.dart';
import 'package:ciclou_projeto/screens/Collector/collect_history_screen.dart';
import 'package:ciclou_projeto/screens/Collector/collect_process.dart';
import 'package:ciclou_projeto/screens/Collector/collector_map_screen.dart';
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
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/user_profile.jpg'),
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
              Navigator.pushNamed(context, '/collectorNotifications');
            },
          ),
        ],
      ),
      drawer: CustomDrawer(
        userName: widget.user.responsible,
        userEmail: widget.user.email,
        profileImageUrl: 'assets/user_profile.jpg',
        onEditProfile: () {},
        onSettings: () {},
        onLogout: () {
          FirebaseAuth.instance.signOut().then((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const RegisterCollectorScreen()),
            );
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao fazer logout: $error')),
            );
          });
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
        return const CollectorMapScreen();
      case 2:
        return const CollectProcess();
      case 3:
        return const CollectorHistoryScreen();
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
                  Icons.map, 'Solicitações Próximas', Colors.blue),
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
          return const Center(child: Text('Erro ao carregar solicitações.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Nenhuma solicitação disponível no momento.'),
          );
        }

        final documents = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final data = documents[index].data() as Map<String, dynamic>;

            return _buildSolicitationCard(
              data['tipoEstabelecimento'] ?? 'N/A',
              '${data['quantidadeOleo'] ?? 'N/A'} Litros',
              data['prazo'] ?? 'N/A',
              data['comentarios'] ?? 'Sem observações',
              documents[index].id,
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        if (label == 'Solicitações Próximas') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CollectorMapScreen()),
          );
        } else if (label == 'Propostas Enviadas') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SentProposalsScreen()),
          );
        } else if (label == 'Histórico') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CollectorHistoryScreen()),
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

  Widget _buildSolicitationCard(String title, String quantity, String prazo,
      String comentarios, String documentId) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text('$quantity - Prazo: $prazo'),
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