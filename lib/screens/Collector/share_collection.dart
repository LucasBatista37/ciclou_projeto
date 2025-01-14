import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:ciclou_projeto/screens/login_screen.dart';

class CompartilharColetaScreen extends StatefulWidget {
  final String coletaId;

  const CompartilharColetaScreen({Key? key, required this.coletaId})
      : super(key: key);

  @override
  State<CompartilharColetaScreen> createState() =>
      _CompartilharColetaScreenState();
}

class _CompartilharColetaScreenState extends State<CompartilharColetaScreen> {
  bool _loading = false;
  String? _generatedLink;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      developer
          .log('Usuário não autenticado. Redirecionando para LoginScreen.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      developer.log('Usuário autenticado: ${user.email}');
    }
  }

  Future<void> _generateLink() async {
    developer.log(
        'Iniciando geração do link dinâmico para coletaId: ${widget.coletaId}');
    setState(() {
      _loading = true;
    });

    try {
      // Buscar os dados da coleta no Firestore
      DocumentSnapshot coletaSnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .doc(widget.coletaId)
          .get();

      if (!coletaSnapshot.exists) {
        developer.log('Coleta não encontrada no Firestore.');
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coleta não encontrada.')),
        );
        return;
      }

      // Extrair os dados da coleta
      Map<String, dynamic> coletaData =
          coletaSnapshot.data() as Map<String, dynamic>;

      // Verifique os dados extraídos
      developer.log('Dados da coleta: $coletaData');

      final notificationData = {
        'coletaId': widget.coletaId,
        'region': coletaData['region'] ?? 'Não informado',
        'address': coletaData['address'] ?? 'Não informado',
        'statusAtual': coletaData['status'] ?? 'Pendente',
        'precoPorLitro':
            coletaData['precoPorLitro']?.toString() ?? 'Não informado',
        'collectorId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      developer
          .log('Dados para salvar na coleção notifications: $notificationData');

      // Salvar os dados na coleção de notificações
      DocumentReference notificationRef = await FirebaseFirestore.instance
          .collection('notifications')
          .add(notificationData);

      final notificationId = notificationRef.id;

      // Criar o link dinâmico com o ID da notificação
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        link: Uri.parse(
            'https://ciclouprojeto.page.link/notificacao?notificacaoId=$notificationId'),
        uriPrefix: 'https://ciclouprojeto.page.link',
        androidParameters: AndroidParameters(
          packageName: 'com.example.ciclou_projeto',
          minimumVersion: 1,
        ),
        iosParameters: IOSParameters(
          bundleId: 'com.example.ciclou_projeto',
          minimumVersion: '1.0.0',
        ),
      );

      developer.log('Parâmetros configurados: $parameters');

      // Gerar o link curto
      final ShortDynamicLink shortDynamicLink =
          await FirebaseDynamicLinks.instance.buildShortLink(parameters);

      final Uri dynamicUrl = shortDynamicLink.shortUrl;
      developer.log('Link gerado com sucesso: $dynamicUrl');

      setState(() {
        _generatedLink = dynamicUrl.toString();
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link gerado com sucesso!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e, stackTrace) {
      developer.log('Erro ao gerar o link dinâmico',
          error: e, stackTrace: stackTrace);
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar o link: $e')),
      );
    }
  }

  void _copyToClipboard(String text) {
    developer.log('Copiando link para área de transferência: $text');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado para a área de transferência!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Construindo tela de Compartilhar Coleta');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Compartilhar Coleta',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Column(
              children: [
                Icon(
                  Icons.share,
                  color: Colors.green,
                  size: 64,
                ),
                SizedBox(height: 8),
                Text(
                  'Compartilhe esta coleta!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Clique no botão abaixo para gerar e compartilhar o link desta coleta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      developer.log('Botão de gerar link clicado.');
                      await _generateLink();
                    },
              icon: const Icon(Icons.link),
              label: _loading
                  ? const Text('Gerando link...')
                  : const Text('Gerar Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_generatedLink != null)
              Column(
                children: [
                  Text(
                    'Link Gerado:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _generatedLink!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.green),
                          onPressed: () {
                            _copyToClipboard(_generatedLink!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
