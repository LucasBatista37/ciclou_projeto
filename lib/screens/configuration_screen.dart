import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/upload_documents.dart';
import 'package:ciclou_projeto/screens/Requestor/suporte_screen_requestor.dart';
import 'package:ciclou_projeto/screens/edit_collector_profile.dart';
import 'package:ciclou_projeto/screens/edit_requestor_profile.dart';
import 'package:ciclou_projeto/screens/Collector/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:ciclou_projeto/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilConfiguracoesScreen extends StatelessWidget {
  final UserModel user;

  const PerfilConfiguracoesScreen({super.key, required this.user});

  Future<String?> _getUserType() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final requestorDoc = await FirebaseFirestore.instance
          .collection('requestor')
          .doc(uid)
          .get();
      if (requestorDoc.exists) {
        return requestorDoc.data()?['userType'];
      }

      final collectorDoc = await FirebaseFirestore.instance
          .collection('collector')
          .doc(uid)
          .get();
      if (collectorDoc.exists) {
        return collectorDoc.data()?['userType'];
      }
    }
    return null;
  }

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

      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro: usuário não encontrado.',
      );
    } else {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Usuário não autenticado.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserType(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userType = snapshot.data;

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
                title:
                    const Text('Editar Perfil', style: TextStyle(fontSize: 16)),
                onTap: () {
                  navigateToProfile(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.support_agent_rounded,
                    color: Colors.green),
                title: const Text('Suporte', style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SupportScreenRequestor(
                              user: user,
                            )),
                  );
                },
              ),
              const Divider(),
              if (userType == 'Coletor')
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.green),
                  title: const Text('Upload de Documentos',
                      style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UploadDocumentsScreen(
                                user: user,
                              )),
                    );
                  },
                ),
              if (userType == 'Coletor') const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('Sair',
                    style: TextStyle(fontSize: 16, color: Colors.red)),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
