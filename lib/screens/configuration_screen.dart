import 'package:ciclou_projeto/screens/edit_perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:ciclou_projeto/screens/login_screen.dart';

class PerfilConfiguracoesScreen extends StatelessWidget {
  const PerfilConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Perfil e Configurações',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text('Editar Perfil', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditarPerfilScreen(),
                ),
              );
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications, color: Colors.grey),
            title: Text('Configurações de Notificações',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            onTap: null,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.payment, color: Colors.grey),
            title: Text('Métodos de Pagamento',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            onTap: null,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.upload_file, color: Colors.grey),
            title: Text('Upload de Documentos',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            onTap: null,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.bar_chart, color: Colors.grey),
            title: Text('Estatísticas Pessoais',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            onTap: null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Sair',
                style: TextStyle(fontSize: 16, color: Colors.red)),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
