import 'dart:developer' as developer;
import 'package:ciclou_projeto/components/collect_process/Coleta_info.dart';
import 'package:ciclou_projeto/components/collect_process/Collect_Service.dart';
import 'package:ciclou_projeto/components/collect_process/Pagamento_plataforma.dart';
import 'package:ciclou_projeto/components/collect_process/Pagamento_solicitante.dart';
import 'package:ciclou_projeto/components/collect_process/comprovante_overlay.dart';
import 'package:ciclou_projeto/components/collect_process/generate_certificate.dart';
import 'package:ciclou_projeto/components/collect_process/generete_button.dart';
import 'package:ciclou_projeto/components/collect_process/status_card.dart';
import 'package:ciclou_projeto/components/collect_shared/collect_data_form.dart';
import 'package:ciclou_projeto/components/payment_service.dart';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/collect_finished.dart';
import 'package:ciclou_projeto/screens/Collector/share_collection.dart';
import 'package:ciclou_projeto/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CollectProcessRede extends StatefulWidget {
  final DocumentSnapshot<Object?> coletaAtual;
  final UserModel user;

  const CollectProcessRede({
    super.key,
    required this.coletaAtual,
    required this.user,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CollectProcessRedeState createState() => _CollectProcessRedeState();
}

class _CollectProcessRedeState extends State<CollectProcessRede> {
  late DocumentSnapshot _coletaAtual;
  bool _carregando = true;
  String? _qrCodeBase64;
  String? _qrCodeText;
  String? _confirmationCode;
  bool _isLoading = false;
  bool _isProcessing = false;

  double _quantidadeReal = 0.0;
  bool _coletaFinalizada = false;
  String? _paymentStatus;
  File? _comprovantePagamento;
  double _valorTotalPago = 0.0;

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _placaController = TextEditingController();
  final _veiculoController = TextEditingController();

  String? _nomeError;
  String? _cpfError;
  String? _placaError;
  String? _veiculoError;
  final _cpfMaskFormatter = MaskTextInputFormatter(mask: '###.###.###-##');

  String? _qrCodeSolicitanteBase64;
  String? _qrCodeTextSolicitante;

  final _rgController = TextEditingController();
  final _rgMaskFormatter = MaskTextInputFormatter(mask: '##.###.###-#');
  String? _rgError;

  @override
  void initState() {
    super.initState();
    _coletaAtual = widget.coletaAtual;
    _carregando = false;
    _buscarQrCode();
    _verificarPagamento();
    _carregarValorTotalPago();
    _loadSolicitanteQRCode(_coletaAtual.id, 'proposalId');
  }

  Future<void> _verificarPagamento() async {
    try {
      final result =
          await CollectService.verificarPagamentoComCodigo(_coletaAtual.id);

      setState(() {
        _paymentStatus = result['paymentStatus'];
        _confirmationCode = result['confirmationCode'];
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao verificar pagamento.',
      );
    }
  }

  Future<void> _loadSolicitanteQRCode(
      String documentId, String proposalId) async {
    try {
      final propostaData = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(documentId)
          .collection('propostas')
          .doc(proposalId)
          .get();

      if (propostaData.exists) {
        final data = propostaData.data();

        setState(() {
          _qrCodeSolicitanteBase64 = data?['qrCodeTextSolicitante'];
          _qrCodeTextSolicitante = data?['qrCodeSolicitante'];
        });
      } else {
        developer
            .log("Proposta não encontrada ou sem QR Code para o solicitante.");
      }
    } catch (e) {
      developer.log("Erro ao carregar QR Code do solicitante: $e");
    }
  }

  Future<void> _carregarValorTotalPago() async {
    try {
      final valor = await CollectService.getValorTotalPago(_coletaAtual.id);
      setState(() {
        _valorTotalPago = valor;
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao carregar valor total pago.',
      );
    }
  }

  Future<void> _buscarQrCode() async {
    try {
      final proposalSnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .collection('propostas')
          .where('status', isEqualTo: 'Aceita')
          .get();

      if (proposalSnapshot.docs.isNotEmpty) {
        final proposalData = proposalSnapshot.docs.first.data();
        final proposalId = proposalSnapshot.docs.first.id;

        setState(() {
          _qrCodeBase64 = proposalData['qrCodeBase64'];
          _qrCodeText = proposalData['qrCode'];
        });
        await _loadSolicitanteQRCode(_coletaAtual.id, proposalId);
      } else {
        developer.log(
            "Nenhuma proposta aceita encontrada para a coleta ID: ${_coletaAtual.id}",
            name: "_buscarQrCode");
      }
    } catch (e) {
      developer.log("Erro ao buscar QR Code da proposta",
          error: e, name: "_buscarQrCode");
    }
  }

  Future<void> _gerarCertificado() async {
    final data = _coletaAtual.data() as Map<String, dynamic>;

    try {
      await CertificadoService.gerarCertificado(
        coletaData: data,
        coletaId: _coletaAtual.id,
        quantidadeReal: _quantidadeReal,
      );

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Certificado gerado ao solicitante com sucesso!',
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao gerar certificado.',
      );
    }
  }

  Future<void> _enviarComprovantePagamento() async {
    if (_comprovantePagamento == null) {
      ScaffoldMessengerHelper.showWarning(
        context: context,
        message: 'Nenhum comprovante selecionado.',
      );
      return;
    }

    final fileSizeInMB = _comprovantePagamento!.lengthSync() / (1024 * 1024);
    const maxFileSizeMB = 5;

    if (fileSizeInMB > maxFileSizeMB) {
      ScaffoldMessengerHelper.showWarning(
        context: context,
        message:
            'O arquivo selecionado é muito grande. O tamanho máximo permitido é ${maxFileSizeMB}MB.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado.');
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('comprovantes_pagamento')
          .child('$userId/${DateTime.now().millisecondsSinceEpoch}.pdf');

      final uploadTask = await storageRef.putFile(_comprovantePagamento!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'comprovantePagamento': downloadUrl,
      });

      await _finalizarColeta();

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Comprovante enviado e coleta finalizada com sucesso!',
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao enviar o comprovante ou finalizar coleta.',
      );
    } finally {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<bool> _verificarPermissaoCompartilhar() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) return false;

      final propostasSnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .collection('propostas')
          .where('status', isEqualTo: 'Aceita')
          .get();

      if (propostasSnapshot.docs.isEmpty) return false;

      final proposalData = propostasSnapshot.docs.first.data();
      final String? collectorId = proposalData['collectorId'];

      return collectorId == currentUserId;
    } catch (e) {
      return false;
    }
  }

  Future<void> _atualizarQuantidadeOleo(String collectorId) async {
    developer.log("Atualizando quantidade de óleo pelo coletor...");
    try {
      final collectorDocRef =
          FirebaseFirestore.instance.collection('collector').doc(collectorId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(collectorDocRef);

        final currentAmountRaw = snapshot.data()?['amountOil'] ?? 0.0;
        final double currentAmount = currentAmountRaw is double
            ? currentAmountRaw
            : double.tryParse(currentAmountRaw.toString()) ?? 0.0;

        final newAmount = currentAmount + _quantidadeReal;

        transaction.update(collectorDocRef, {'amountOil': newAmount});
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao atualizar quantidade de óleo pelo coletor.',
      );
    }
  }

  Future<void> _confirmarColeta() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Usuário não autenticado.',
      );
      return;
    }

    final data = _coletaAtual.data() as Map<String, dynamic>;

    if (data['collectorId'] != currentUser.uid) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Permissão negada para essa coleta.',
      );
      return;
    }

    _mostrarSobreposicaoComprovante();
  }

  Future<void> _finalizarColeta() async {
    try {
      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'status': 'Finalizada',
        'quantidadeReal': _quantidadeReal,
        'dataConclusao': FieldValue.serverTimestamp(),
      });

      final data = _coletaAtual.data() as Map<String, dynamic>;
      final String collectorId = data['collectorId'] ?? '';
      if (collectorId.isNotEmpty) {
        await _atualizarQuantidadeOleo(collectorId);
      }

      setState(() {
        _coletaFinalizada = true;
      });

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Coleta confirmada com sucesso!',
      );

      // ignore: use_build_context_synchronously
      await _notificarSolicitanteFinalizacao(context);

      await _gerarCertificado();

      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
              builder: (context) => const ColetaFinalizadaScreen()),
        );
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao finalizar coleta.',
      );
    }
  }

  void _mostrarSobreposicaoComprovante() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ComprovanteOverlay(
          onComprovanteSelecionado: (File? comprovante) {
            setState(() {
              _comprovantePagamento = comprovante;
            });
          },
          onEnviarComprovante: () async {
            await _enviarComprovantePagamento();
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _notificarSolicitanteFinalizacao(BuildContext context) async {
    try {
      final coletaDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .get();

      if (!coletaDoc.exists) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro: coleta não encontrada.',
        );
        return;
      }

      final requestorId = coletaDoc.data()?['userId'];

      if (requestorId == null) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro: solicitante não encontrado.',
        );
        return;
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Coleta Finalizada',
        'message':
            'A coleta foi concluída com sucesso! Verifique o comprovante enviado pelo coletor.',
        'timestamp': FieldValue.serverTimestamp(),
        'requestorId': requestorId,
        'coletaId': _coletaAtual.id,
        'isRead': false,
      });

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Solicitante notificado sobre a finalização da coleta!',
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao notificar o solicitante sobre a finalização.',
      );
    }
  }

  Future<void> _notificarSolicitante(BuildContext context) async {
    try {
      final coletaDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .get();

      if (!coletaDoc.exists) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro: coleta não encontrada.',
        );
        return;
      }

      final requestorId = coletaDoc.data()?['userId'];

      if (requestorId == null) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro: solicitante não encontrado.',
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'coletorACaminho': true,
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Coletor a Caminho',
        'message': 'O coletor está a caminho da coleta.',
        'timestamp': FieldValue.serverTimestamp(),
        'requestorId': requestorId,
        'coletaId': _coletaAtual.id,
        'isRead': false,
      });

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Solicitante notificado que você está a caminho!',
      );

      setState(() {
        _coletaAtual = coletaDoc;
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao notificar o solicitante.',
      );
    }
  }

  Future<void> _confirmarDadosEAtualizarProposta() async {
    setState(() {
      _nomeError =
          _nomeController.text.isEmpty ? 'Nome não pode ser vazio' : null;
      _cpfError = _cpfController.text.isEmpty ? 'CPF não pode ser vazio' : null;
      _placaError = _placaController.text.isEmpty
          ? 'Placa do veículo não pode ser vazia'
          : null;
      _veiculoError = _veiculoController.text.isEmpty
          ? 'Modelo do veículo não pode ser vazio'
          : null;
    });

    if (_nomeError != null ||
        _cpfError != null ||
        _placaError != null ||
        _veiculoError != null) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Preencha todos os campos obrigatórios.',
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessengerHelper.showError(
          context: context,
          message: 'Usuário não autenticado.',
        );
        return;
      }
      final userId = currentUser.uid;

      final propostasSnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .collection('propostas')
          .where('status', isEqualTo: 'Aceita')
          .get();

      if (propostasSnapshot.docs.isEmpty) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Nenhuma proposta aceita encontrada.',
        );
        return;
      }

      final propostaDocId = propostasSnapshot.docs.first.id;

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .collection('propostas')
          .doc(propostaDocId)
          .update({
        'nome': _nomeController.text.trim(),
        'cpf': _cpfController.text.trim(),
        'rg': _rgController.text.trim(),
        'placa': _placaController.text.trim(),
        'veiculo': _veiculoController.text.trim(),
        'coletorId': userId,
      });

      await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .update({
        'statusColetorAtualizado': true,
      });

      ScaffoldMessengerHelper.showSuccess(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Informações salvas com sucesso!',
      );

      final updatedColetaDoc = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(_coletaAtual.id)
          .get();
      setState(() {
        _coletaAtual = updatedColetaDoc;
      });
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro ao salvar informações do coletor.',
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ignore: unnecessary_null_comparison
    if (_coletaAtual == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Nenhuma coleta em andamento.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final data = _coletaAtual.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green1,
        centerTitle: true,
        title: const Text(
          'Processo de Coleta Rede',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('coletas')
                    .doc(_coletaAtual.id)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const SizedBox();
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;

                    if (data != null && data['isShared'] == true) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        color: Colors.amber.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: const [
                              Icon(Icons.warning, color: Colors.amber),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Esta coleta é compartilhada.',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }

                  return const SizedBox();
                },
              ),

              ColetaInfoCard(
                tipoEstabelecimento: data['tipoEstabelecimento'] ?? 'N/A',
                quantidadeOleo: (data['quantidadeOleo'] ?? 'N/A').toString(),
                endereco: data['address'],
                mostrarEndereco: _paymentStatus == 'approved',
                funcionamentoDias:
                    List<String>.from(data['funcionamentoDias'] ?? []),
                funcionamentoHorario: data['funcionamentoHorario'] ?? 'N/A',
                requestorName: data['requestorName'] ?? 'N/A',
              ),

              const SizedBox(height: 24),

              if (_paymentStatus == 'approved' &&
                  (data['status'] ?? '') == 'Aprovado' &&
                  !(data['realQuantityCollected'] ?? false)) ...[
                const Text(
                  'Digite a quantidade real coletada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide:
                          const BorderSide(color: Colors.green, width: 2),
                    ),
                    labelText: 'Quantidade em Litros',
                    labelStyle: const TextStyle(color: Colors.green),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide:
                          const BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _quantidadeReal = double.tryParse(value) ?? 0.0;

                      double precoPorLitro = double.tryParse(
                              data['precoPorLitro']?.toString() ?? '0.0') ??
                          0.0;

                      _valorTotalPago = _quantidadeReal * precoPorLitro;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'R\$',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      _valorTotalPago.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              if (_paymentStatus == 'approved' &&
                  _confirmationCode != null &&
                  (data['status'] ?? '') == 'Aprovado' &&
                  !(data['realQuantityCollected'] ?? false)) ...[
                const SizedBox(height: 12),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('coletas')
                      .doc(_coletaAtual.id)
                      .collection('propostas')
                      .where('status', isEqualTo: 'Aceita')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Erro ao carregar propostas. Por favor, tente novamente.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final proposalId = snapshot.data!.docs.first.id;

                      return Column(
                        children: [
                          GenerateQRCodeButton(
                            documentId: _coletaAtual.id,
                            proposalId: proposalId,
                            amount: _valorTotalPago,
                            user: widget.user,
                            onSuccess: (qrCodeBase64, qrCodeText) async {
                              try {
                                setState(() {
                                  _qrCodeSolicitanteBase64 = qrCodeBase64;
                                  _qrCodeTextSolicitante = qrCodeText;
                                });

                                final updatedColetaDoc = await FirebaseFirestore
                                    .instance
                                    .collection('coletas')
                                    .doc(_coletaAtual.id)
                                    .get();

                                setState(() {
                                  _coletaAtual = updatedColetaDoc;
                                });

                                // ignore: use_build_context_synchronously
                                ScaffoldMessengerHelper.showSuccess(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  message: 'Qr Code gerado com sucesso!',
                                );
                              } catch (e) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Erro ao recarregar a tela')),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }

                    return const Center(
                      child: Text(
                        'Nenhuma proposta aceita encontrada.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (_paymentStatus == 'approved' &&
                  _confirmationCode != null &&
                  (data['status'] ?? '') == 'Aprovado' &&
                  (data['realQuantityCollected'] ?? false)) ...[
                Column(
                  children: [
                    if (_qrCodeSolicitanteBase64 != null &&
                        _qrCodeTextSolicitante != null)
                      PagamentoSolicitanteQRCodeCard(
                        qrCodeSolicitanteBase64: _qrCodeSolicitanteBase64!,
                        qrCodeTextSolicitante: _qrCodeTextSolicitante!,
                        onCopiarCodigoSolicitante: () {
                          Clipboard.setData(
                            ClipboardData(text: _qrCodeTextSolicitante!),
                          );
                          ScaffoldMessengerHelper.showSuccess(
                            // ignore: use_build_context_synchronously
                            context: context,
                            message: 'Chave Pix copiada!',
                          );
                        },
                        onConfirmarPagamentoSolicitante: () async {
                          try {
                            final proposalSnapshot = await FirebaseFirestore
                                .instance
                                .collection('coletas')
                                .doc(_coletaAtual.id)
                                .collection('propostas')
                                .where('status', isEqualTo: 'Aceita')
                                .get();

                            if (proposalSnapshot.docs.isNotEmpty) {
                              final proposalId = proposalSnapshot.docs.first.id;
                              final paymentIdSolicitante = proposalSnapshot
                                  .docs.first
                                  .data()['paymentIdSolicitante'];

                              final paymentService =
                                  PaymentService(paymentIdSolicitante);
                              final paymentStatus =
                                  await paymentService.validatePayment();

                              if (paymentStatus == 'approved') {
                                await FirebaseFirestore.instance
                                    .collection('coletas')
                                    .doc(_coletaAtual.id)
                                    .collection('propostas')
                                    .doc(proposalId)
                                    .update({'statusSolicitante': 'Aprovado'});

                                setState(() {
                                  _paymentStatus = 'approved';
                                });

                                // ignore: use_build_context_synchronously
                                ScaffoldMessengerHelper.showSuccess(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  message:
                                      'Pagamento ao solicitante confirmado! Finalize a coleta.',
                                );
                              } else {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessengerHelper.showSuccess(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  message: 'Pagamento ainda não foi aprovado.',
                                );
                              }
                            } else {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Nenhuma proposta aceita encontrada.')),
                              );
                            }
                          } catch (e) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessengerHelper.showSuccess(
                              // ignore: use_build_context_synchronously
                              context: context,
                              message: 'Erro ao verificar pagamento.',
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],

              if (_qrCodeBase64 != null && _paymentStatus != 'approved')
                PagamentoQRCodeCard(
                  qrCodeBase64: _qrCodeBase64!,
                  qrCodeText: _qrCodeText,
                  onCopiarCodigo: () {
                    if (_qrCodeText != null) {
                      Clipboard.setData(ClipboardData(text: _qrCodeText!));
                      ScaffoldMessengerHelper.showSuccess(
                        context: context,
                        message: 'Código Copiado!',
                      );
                    }
                  },
                  onRevalidarPagamento: () async {
                    await _verificarPagamento();
                    ScaffoldMessengerHelper.showWarning(
                      // ignore: use_build_context_synchronously
                      context: context,
                      message: 'Revalidando Pagamento...',
                    );
                  },
                ),

              const SizedBox(height: 8),

              // Exibe o código de confirmação
              if (_confirmationCode != null &&
                  (data['status'] ?? '') != 'Aprovado' &&
                  (data['statusColetorAtualizado'] ?? false) == true) ...[
                Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Código de Confirmação da Coleta',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _confirmationCode!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    try {
                                      await _verificarPagamento();

                                      final updatedColetaDoc =
                                          await FirebaseFirestore.instance
                                              .collection('coletas')
                                              .doc(_coletaAtual.id)
                                              .get();

                                      setState(() {
                                        _coletaAtual = updatedColetaDoc;
                                        _isLoading = false;
                                      });
                                    } catch (e) {
                                      developer.log(
                                          "Erro ao atualizar a coleta: $e");
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isLoading ? Colors.grey : Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 12.0),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Já confirmado',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_confirmationCode != null &&
                  !(data['coletorACaminho'] ?? false) &&
                  (data['status'] ?? '') != 'Aprovado' &&
                  (data['statusColetorAtualizado'] ?? false) == true) ...[
                Center(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setState(() {
                              _isProcessing = true;
                            });

                            await _notificarSolicitante(context);

                            final updatedColetaDoc = await FirebaseFirestore
                                .instance
                                .collection('coletas')
                                .doc(_coletaAtual.id)
                                .get();

                            setState(() {
                              _coletaAtual = updatedColetaDoc;
                              _isProcessing = false;
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Estou indo',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_confirmationCode != null &&
                  !(data['coletorACaminho'] ?? false) &&
                  (data['status'] ?? '') != 'Aprovado' &&
                  (data['statusColetorAtualizado'] ?? false) == false) ...[
                const SizedBox(height: 16),
                Center(
                  child: CollectDataForm(
                    nomeController: _nomeController,
                    cpfController: _cpfController,
                    placaController: _placaController,
                    veiculoController: _veiculoController,
                    nomeError: _nomeError,
                    cpfError: _cpfError,
                    placaError: _placaError,
                    veiculoError: _veiculoError,
                    cpfMaskFormatter: _cpfMaskFormatter,
                    rgController: _rgController,
                    rgMaskFormatter: _rgMaskFormatter,
                    rgError: _rgError,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            await _confirmarDadosEAtualizarProposta();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirmar Dados',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botão Compartilhar Coleta
              FutureBuilder<bool>(
                future: _verificarPermissaoCompartilhar(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasData && snapshot.data == true) {
                    return Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompartilharColetaScreen(
                                coletaId: _coletaAtual.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text(
                          'Compartilhar Coleta',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),

              // Pagamento Aprovado e Registro da Coleta
              if (_paymentStatus == 'approved' &&
                  (data['status'] ?? '') == 'Aprovado' &&
                  (data['realQuantityCollected'] ?? false) == true)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusCard(
                      message:
                          'Pagamento aprovado e coleta aprovada! Faça o pagamento para o solicitante para prosseguir com a coleta.',
                      backgroundColor: Colors.green[50]!,
                      textColor: Colors.green,
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 12.0),
                        ),
                        onPressed: _coletaFinalizada ? null : _confirmarColeta,
                        child: const Text(
                          'Finalizar Coleta',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              else if (_paymentStatus == 'approved' &&
                  (data['status'] ?? '') != 'Aprovado')
                StatusCard(
                  message:
                      'Pagamento aprovado, peça que o solicitante preencha o código acima para poder prosseguir com a coleta.',
                  backgroundColor: Colors.green[50]!,
                  textColor: Colors.green,
                ),

              if (_paymentStatus == 'pending')
                StatusCard(
                  message:
                      'Pagamento pendente. Por favor, conclua o pagamento para a plataforma em até 24 Horas para continuar.',
                  backgroundColor: Colors.red[50]!,
                  textColor: Colors.red,
                ),

              if (_paymentStatus == 'rejected')
                StatusCard(
                  message:
                      'Pagamento rejeitado. Entre em contato com o suporte.',
                  backgroundColor: Colors.red[50]!,
                  textColor: Colors.red,
                ),

              if (_paymentStatus == 'cancelled')
                StatusCard(
                  message:
                      'Tempo para pagar plataforma esgotado. O pagamento foi cancelado.',
                  backgroundColor: Colors.blueGrey[50]!,
                  textColor: Colors.blueGrey.shade700,
                ),

              if (_qrCodeBase64 == null && _paymentStatus != 'approved')
                const Center(
                  child: Text(
                    'QR Code não disponível.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
