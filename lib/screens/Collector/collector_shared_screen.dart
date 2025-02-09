import 'package:ciclou_projeto/components/collect_shared/details_card.dart';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/collect_process_rede.dart';
import 'package:ciclou_projeto/screens/login_screen.dart';
import 'package:ciclou_projeto/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class ColetorNotificacaoScreen extends StatefulWidget {
  final String coletaId;
  final UserModel user;

  const ColetorNotificacaoScreen({
    super.key,
    required this.coletaId,
    required this.user,
  });

  @override
  State<ColetorNotificacaoScreen> createState() =>
      _ColetorNotificacaoScreenState();
}

class _ColetorNotificacaoScreenState extends State<ColetorNotificacaoScreen> {
  Map<String, dynamic>? coleta;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchColeta();
  }

  Future<void> _fetchColeta() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(widget.coletaId)
          .get();

      if (snapshot.exists) {
        setState(() {
          coleta = snapshot.data() as Map<String, dynamic>?;
          _loading = false;
        });
      } else {
        developer.log('Coleta não encontrada.');
        setState(() {
          _loading = false;
        });
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Coleta não encontrada.',
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao carregar coleta.',
      );
    }
  }

  Future<void> _salvarDadosColeta() async {
    try {
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(widget.coletaId)
          .update({'isShared': true});

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Coleta aceita com sucesso!',
      );

      DocumentSnapshot coletaAtualizada = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(widget.coletaId)
          .get();

      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => CollectProcessRede(
            coletaAtual: coletaAtualizada,
            user: widget.user,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao salvar dados.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green1,
        centerTitle: true,
        title: const Text(
          'Detalhes da Coleta',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : coleta == null
              ? const Center(
                  child: Text('Detalhes não disponíveis.'),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        DetailsCard(
                          region: coleta?['region'] ?? 'Não disponível',
                          address: coleta?['address'] ?? 'Não disponível',
                          status: coleta?['status'] ?? 'Não disponível',
                          pricePerLiter: coleta?['precoPorLitro']?.toString() ??
                              'Não disponível',
                        ),
                        const Divider(height: 32),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _salvarDadosColeta,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Aceitar Coleta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                                vertical: 12.0,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}