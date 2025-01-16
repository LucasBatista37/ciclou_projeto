import 'package:ciclou_projeto/components/scaffold_mensager.dart';
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
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        link: Uri.parse(
            'https://ciclouprojeto.page.link/coleta?coletaId=${widget.coletaId}'),
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

      final ShortDynamicLink shortDynamicLink =
          await FirebaseDynamicLinks.instance.buildShortLink(parameters);

      final Uri dynamicUrl = shortDynamicLink.shortUrl;
      developer.log('Link gerado com sucesso: $dynamicUrl');

      setState(() {
        _generatedLink = dynamicUrl.toString();
        _loading = false;
      });

      ScaffoldMessengerHelper.showSuccess(
        context: context,
        message: 'Link gerado com sucesso!',
      );
    } catch (e, stackTrace) {
      developer.log('Erro ao gerar o link dinâmico',
          error: e, stackTrace: stackTrace);
      setState(() {
        _loading = false;
      });
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro ao gerar link',
      );
    }
  }

  void _copyToClipboard(String text) {
    developer.log('Copiando link para área de transferência: $text');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessengerHelper.showSuccess(
      context: context,
      message: 'Link copiado para área de transferência!',
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
              icon: const Icon(Icons.link,
                  color: Colors.white), 
              label: _loading
                  ? const Text(
                      'Gerando link...',
                      style: TextStyle(color: Colors.white), 
                    )
                  : const Text(
                      'Gerar Link',
                      style: TextStyle(color: Colors.white),
                    ),
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