import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_dashboard.dart';
import 'package:ciclou_projeto/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class CodeVerificationScreen extends StatelessWidget {
  final String documentId;
  final UserModel user;

  const CodeVerificationScreen(
      {super.key, required this.documentId, required this.user});

  @override
  Widget build(BuildContext context) {
    final TextEditingController codeController = TextEditingController();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Verificação de Código',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.green1,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
            body: const Center(
              child: Text(
                'Coleta não encontrada.',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'Em andamento';

        if (status == 'Aprovado') {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Verificação de Código',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.green1,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 100,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Coleta Aprovada!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Agora é só aguardar o coletor finalizar a coleta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.home,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Voltar para o Início',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Verificação de Código',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.green1,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Insira o código fornecido pelo coletor para concluir a coleta.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Código de Verificação',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: codeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Digite o código aqui',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final code = codeController.text.trim();

                        if (code.isEmpty) {
                          ScaffoldMessengerHelper.showError(
                            context: context,
                            message: 'Por favor, insira um código.',
                          );
                          return;
                        }

                        try {
                          final doc = await FirebaseFirestore.instance
                              .collection('coletas')
                              .doc(documentId)
                              .get();

                          if (!doc.exists) {
                            ScaffoldMessengerHelper.showError(
                              // ignore: use_build_context_synchronously
                              context: context,
                              message: 'Coleta não encontrada!',
                            );
                            return;
                          }

                          final data = doc.data();
                          if (data?['confirmationCode'] == code) {
                            await FirebaseFirestore.instance
                                .collection('coletas')
                                .doc(documentId)
                                .update({
                              'status': 'Aprovado',
                              'aprovadoEm': DateTime.now(),
                            });

                            ScaffoldMessengerHelper.showSuccess(
                              // ignore: use_build_context_synchronously
                              context: context,
                              message: 'Coleta aprovada com sucesso!',
                            );

                            // ignore: use_build_context_synchronously
                            Navigator.pushReplacement(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RequestorDashboard(
                                        user: user,
                                      )),
                            );
                          } else {
                            ScaffoldMessengerHelper.showError(
                              // ignore: use_build_context_synchronously
                              context: context,
                              message:
                                  'Código incorreto. Por favor, tente novamente',
                            );
                          }
                        } catch (e) {
                          ScaffoldMessengerHelper.showError(
                            // ignore: use_build_context_synchronously
                            context: context,
                            message: 'Erro ao validar o código.',
                          );
                        }
                      },
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Caso o código esteja incorreto, peça ao coletor para verificar novamente.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('coletas')
                        .doc(documentId)
                        .collection('propostas')
                        .where('status', isEqualTo: 'Aceita')
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhuma proposta aceita encontrada.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }

                      final propostaData = snapshot.data!.docs.first.data()
                          as Map<String, dynamic>;

                      final nome = propostaData['nome'] ?? 'Não informado';
                      final cpf = propostaData['cpf'] ?? 'Não informado';
                      final rg = propostaData['rg'] ?? 'Não informado';
                      final veiculo =
                          propostaData['veiculo'] ?? 'Não informado';
                      final placa = propostaData['placa'] ?? 'Não informado';

                      if ([nome, cpf, rg, veiculo, placa]
                          .contains('Não informado')) {
                        return const SizedBox.shrink();
                      }

                      return Center(
                        child: Card(
                          margin: const EdgeInsets.all(16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Dados do Coletor Atribuído',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nome: $nome',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'CPF: $cpf',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'RG: $rg',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Veículo: $veiculo',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Placa: $placa',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
