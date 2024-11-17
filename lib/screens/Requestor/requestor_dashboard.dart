import 'package:ciclou_projeto/components/custom_drawer.dart';
import 'package:ciclou_projeto/components/custom_requestor_navigationbar.dart';
import 'package:ciclou_projeto/screens/Requestor/create_collection_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/payment_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_history_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_map_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_notifications_screen.dart';
import 'package:ciclou_projeto/screens/register_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/proposals_screen.dart';
import 'package:flutter/material.dart';

class RequestorDashboard extends StatefulWidget {
  const RequestorDashboard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RequestorDashboardState createState() => _RequestorDashboardState();
}

class _RequestorDashboardState extends State<RequestorDashboard> {
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
      appBar: _selectedIndex == 0
          ? AppBar(
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
              title: const Text(
                'Olá, Caio!',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestorNotificationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      drawer: CustomDrawer(
        userName: 'Caio',
        userEmail: 'Caio@gmail.com',
        profileImageUrl: 'assets/user_profile.jpg',
        onEditProfile: () {},
        onSettings: () {},
        onLogout: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
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
        return const RequestorMapScreen();
      case 2:
        return const CreateCollection();
      case 3:
        return RequestorHistoryScreen();
      case 4:
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
          _buildSolicitationCard(
              'Restaurante', '10 Litros', 'Aguardando Propostas'),
          _buildSolicitationCard('Condomínio', '5 Litros', 'Aguardando Aceita'),
          TextButton(
            onPressed: () {},
            child: const Text('Ver Todas'),
          ),
          const SizedBox(height: 16.0),
          const Text('Estatísticas de Sustentabilidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Coletado', '50 Litros', Colors.teal),
              _buildStatCard('Impacto', '20 Árvores Salvas', Colors.green),
            ],
          ),
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
            MaterialPageRoute(builder: (context) => const CreateCollection()),
          );
        } else if (label == 'Mapa') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RequestorMapScreen()),
          );
        } else {}
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

  Widget _buildSolicitationCard(String title, String quantity, String status) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text('$quantity - $status'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProposalsScreen(solicitationTitle: title),
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
