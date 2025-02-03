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
  final String? coletaId;

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
      _isLoading = true;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('UID do usuário não encontrado.');
      }

      final userId = user.uid;

      final collectorDoc = await FirebaseFirestore.instance
          .collection('collector')
          .doc(userId)
          .get();

      if (collectorDoc.exists) {
        final userModel = UserModel.fromFirestore(collectorDoc.data()!, userId);

        if (widget.coletaId != null) {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => ColetorNotificacaoScreen(
                coletaId: widget.coletaId!,
                user: userModel,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => CollectorDashboard(user: userModel),
            ),
          );
        }

        widget.onLoginSuccess?.call();
        return;
      }

      final requestorDoc = await FirebaseFirestore.instance
          .collection('requestor')
          .doc(userId)
          .get();

      if (requestorDoc.exists) {
        final userModel = UserModel.fromFirestore(requestorDoc.data()!, userId);

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => RequestorDashboard(user: userModel),
          ),
        );

        widget.onLoginSuccess?.call();
        return;
      }

      throw Exception('Usuário não encontrado em nenhuma coleção.');
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
        case 'email-nao-verificado':
          errorMessage = e.message!;
          break;
        default:
          errorMessage = 'Erro inesperado. Tente novamente.';
          break;
      }

      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: errorMessage,
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Erro inesperado. Tente novamente.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forgotPassword() async {
    final TextEditingController emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Redefinir Senha"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Digite seu e-mail e enviaremos um link para redefinição de senha.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "E-mail",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessengerHelper.showWarning(
                  context: context,
                  message: "Por favor, insira um e-mail válido.",
                );
                return;
              }

              try {
                await _auth.sendPasswordResetEmail(
                    email: emailController.text.trim());
                // ignore: use_build_context_synchronously
                Navigator.pop(context);

                ScaffoldMessengerHelper.showSuccess(
                  // ignore: use_build_context_synchronously
                  context: context,
                  message:
                      "E-mail de redefinição enviado! Verifique sua caixa de entrada.",
                );
              } on FirebaseAuthException catch (e) {
                String errorMessage;
                switch (e.code) {
                  case 'user-not-found':
                    errorMessage = "Nenhuma conta encontrada com esse e-mail.";
                    break;
                  case 'invalid-email':
                    errorMessage = "Formato de e-mail inválido.";
                    break;
                  default:
                    errorMessage = "Erro ao enviar e-mail. Tente novamente.";
                    break;
                }

                ScaffoldMessengerHelper.showError(
                  // ignore: use_build_context_synchronously
                  context: context,
                  message: errorMessage,
                );
              }
            },
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
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
                  height: 400,
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
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text(
                    "Esqueceu a senha?",
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
