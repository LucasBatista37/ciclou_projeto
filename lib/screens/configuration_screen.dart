import 'package:ciclou_projeto/screens/Collector/upload_documents.dart';
import 'package:ciclou_projeto/screens/edit_collector_profile.dart';
import 'package:ciclou_projeto/screens/edit_requestor_profile.dart';
import 'package:ciclou_projeto/screens/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:ciclou_projeto/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilConfiguracoesScreen extends StatelessWidget {
  const PerfilConfiguracoesScreen({super.key});

  void navigateToProfile(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final requestorDoc = await FirebaseFirestore.instance
          .collection('requestor')
          .doc(uid)
          .get();
      if (requestorDoc.exists) {
        final userType = requestorDoc.data()?['userType'];
        if (userType == 'Solicitante') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditRequestorProfile(),
            ),
          );
          return;
        }
      }

      final collectorDoc = await FirebaseFirestore.instance
          .collection('collector')
          .doc(uid)
          .get();
      if (collectorDoc.exists) {
        final userType = collectorDoc.data()?['userType'];
        if (userType == 'Coletor') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditCollectorProfile(),
            ),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não encontrado.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
    }
  }

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
              navigateToProfile(context);
            },
          ),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.support_agent_rounded, color: Colors.green),
            title: const Text('Suporte', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.green),
            title: const Text('Upload de Documentos',
                style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UploadDocumentsScreen()),
              );
            },
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
