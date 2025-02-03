import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/collector_shared_screen.dart';
import 'package:ciclou_projeto/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  const DynamicLinkHandler({super.key});

  @override
  State<DynamicLinkHandler> createState() => _DynamicLinkHandlerState();
}

class _DynamicLinkHandlerState extends State<DynamicLinkHandler> {
  String? _pendingColetaId;

  @override
  void initState() {
    super.initState();
    _handleDynamicLinks();
  }

  Future<void> _handleDynamicLinks() async {
    // ignore: deprecated_member_use
    FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData data) {
      final Uri deepLink = data.link;
      _processDeepLink(deepLink);
    }).onError((error) {
      developer.log('Erro ao processar link dinâmico: $error');
    });

    final PendingDynamicLinkData? initialLink =
        // ignore: deprecated_member_use
        await FirebaseDynamicLinks.instance.getInitialLink();

    if (initialLink?.link != null) {
      _processDeepLink(initialLink!.link);
    }
  }

  void _processDeepLink(Uri deepLink) async {
    final String? coletaId = deepLink.queryParameters['coletaId'];

    if (coletaId != null) {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await _redirectToScreen(currentUser.uid, coletaId);
      } else {
        if (mounted) {
          setState(() {
            _pendingColetaId = coletaId;
          });
        }

        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              onLoginSuccess: _handlePostLoginNavigation,
              coletaId: coletaId,
            ),
          ),
        );
      }
    } else {
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('Link inválido ou sem informações de coleta.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _redirectToScreen(String userId, String coletaId) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('collector')
          .doc(userId)
          .get();

      if (!userSnapshot.exists) {
        throw Exception('Usuário não encontrado no Firestore.');
      }

      final userModel = UserModel.fromFirestore(
        userSnapshot.data()!,
        userId,
      );

      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (context) => ColetorNotificacaoScreen(
            coletaId: coletaId,
            user: userModel,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Erro ao carregar informações do usuário.'),
        ),
      );
    }
  }

  void _handlePostLoginNavigation() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && _pendingColetaId != null) {
      await _redirectToScreen(currentUser.uid, _pendingColetaId!);
      _pendingColetaId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
