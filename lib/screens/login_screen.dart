import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Collector/collector_shared_screen.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_dashboard.dart';
import 'package:ciclou_projeto/screens/Collector/collector_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_requestor_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final String? coletaId; // Adiciona o parâmetro coletaId

  const LoginScreen({super.key, this.onLoginSuccess, this.coletaId});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Exibe o indicador de carregamento
    });

    try {
      // Autentica o usuário
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user?.uid;

      if (userId != null) {
        // Verifica se o usuário está na coleção de coletores
        final collectorDoc = await FirebaseFirestore.instance
            .collection('collector')
            .doc(userId)
            .get();

        if (collectorDoc.exists) {
          // Usuário é coletor
          final user = UserModel.fromFirestore(collectorDoc.data()!, userId);

          if (widget.coletaId != null) {
            // Redireciona para a tela de notificação se coletaId estiver presente
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ColetorNotificacaoScreen(
                  coletaId: widget.coletaId!,
                  user: user,
                ),
              ),
            );
          } else {
            // Redireciona para o dashboard do coletor
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CollectorDashboard(user: user),
              ),
            );
          }
          widget.onLoginSuccess?.call();
          return;
        }

        // Verifica se o usuário está na coleção de solicitantes
        final requestorDoc = await FirebaseFirestore.instance
            .collection('requestor')
            .doc(userId)
            .get();

        if (requestorDoc.exists) {
          // Usuário é solicitante
          final user = UserModel.fromFirestore(requestorDoc.data()!, userId);

          // Redireciona para o dashboard do solicitante
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RequestorDashboard(user: user),
            ),
          );

          widget.onLoginSuccess?.call();
          return;
        }

        throw Exception('Usuário não encontrado em nenhuma coleção.');
      } else {
        throw Exception('UID do usuário não encontrado.');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Usuário não encontrado. Verifique o e-mail inserido.';
          break;
        case 'wrong-password':
          errorMessage = 'Senha incorreta. Tente novamente.';
          break;
        case 'invalid-email':
          errorMessage = 'Formato de e-mail inválido. Por favor, corrija.';
          break;
        default:
          errorMessage = 'Erro inesperado. Tente novamente.';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado. Tente novamente.')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Oculta o indicador de carregamento
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/ciclou.png',
                  height: 350,
                ),
                Column(
                  children: const [
                    Text(
                      'Bem-vindo ao Ciclou!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'O app de coleta de óleo que você precisa.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email',
                  isPassword: false,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Senha',
                  isPassword: true,
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Center(
                          child: Text(
                            'Entrar',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterRequestorScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Criar Conta',
                    style: TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isPassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
