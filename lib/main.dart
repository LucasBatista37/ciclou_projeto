import 'package:ciclou_projeto/screens/Collector/collector_shared_screen.dart';
import 'package:ciclou_projeto/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ciclou App',
      theme: ThemeData(primarySwatch: Colors.green),
      navigatorKey: navigatorKey,
      home: const DynamicLinkHandler(),
    );
  }
}

class DynamicLinkHandler extends StatefulWidget {
  const DynamicLinkHandler({Key? key}) : super(key: key);

  @override
  State<DynamicLinkHandler> createState() => _DynamicLinkHandlerState();
}

class _DynamicLinkHandlerState extends State<DynamicLinkHandler> {
  String? _pendingColetaId; // Renomeado para refletir coletaId

  @override
  void initState() {
    super.initState();
    _handleDynamicLinks();
  }

  Future<void> _handleDynamicLinks() async {
    developer.log('Iniciando o manuseio de links dinâmicos.');

    FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData data) {
      final Uri? deepLink = data.link;
      if (deepLink != null) {
        developer.log('Link dinâmico recebido: $deepLink');
        _processDeepLink(deepLink);
      }
    }).onError((error) {
      developer.log('Erro ao processar link dinâmico: $error');
    });

    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();

    if (initialLink?.link != null) {
      developer.log('Link dinâmico inicial recebido: ${initialLink!.link}');
      _processDeepLink(initialLink.link!);
    }
  }

  void _processDeepLink(Uri deepLink) {
    developer.log('Processando deep link: $deepLink');

    final String? coletaId = deepLink.queryParameters['coletaId'];

    if (coletaId != null) {
      developer.log(
          'Parâmetro coletaId encontrado: $coletaId. Verificando estado do usuário.');

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        developer.log(
            'Usuário está logado (${user.email}). Redirecionando para ColetorNotificacaoScreen.');

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ColetorNotificacaoScreen(
              coletaId: coletaId,
            ),
          ),
        );
      } else {
        developer.log(
            'Usuário não está logado. Salvando coletaId para redirecionamento após login.');

        setState(() {
          _pendingColetaId = coletaId; // Ajustado para coletaId
        });

        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              onLoginSuccess: _handlePostLoginNavigation,
            ),
          ),
        );
      }
    } else {
      developer.log(
          'Deep link não contém o parâmetro coletaId. Nenhuma ação será tomada.');
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Link inválido ou sem informações de coleta.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handlePostLoginNavigation() {
    if (_pendingColetaId != null) {
      developer.log(
          'Usuário logado com sucesso. Redirecionando para ColetorNotificacaoScreen com coletaId: $_pendingColetaId');

      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (context) => ColetorNotificacaoScreen(
            coletaId: _pendingColetaId!,
          ),
        ),
      );

      _pendingColetaId = null; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
