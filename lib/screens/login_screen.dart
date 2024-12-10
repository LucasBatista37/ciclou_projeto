import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_dashboard.dart';
import 'package:ciclou_projeto/screens/Collector/collector_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_requestor_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print("Tentando login com email: ${_emailController.text}");

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user?.uid;

      if (userId != null) {
        print("Login bem-sucedido, UID do usuário: $userId");

        final userDoc = await FirebaseFirestore.instance
            .collection('requestor')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final user = UserModel.fromFirestore(userDoc.data()!, userId);
          print("Usuário encontrado em 'requestor':");
          print("  Nome: ${user.responsible}");
          print("  Email: ${user.email}");
          print("  UserID: ${user.userId}");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RequestorDashboard(user: user),
            ),
          );
          return;
        }

        final collectorDoc = await FirebaseFirestore.instance
            .collection('collector')
            .doc(userId)
            .get();

        if (collectorDoc.exists) {
          final user = UserModel.fromFirestore(collectorDoc.data()!, userId);
          print("Usuário encontrado em 'collector':");
          print("  Nome: ${user.responsible}");
          print("  Email: ${user.email}");
          print("  UserID: ${user.userId}");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CollectorDashboard(user: user),
            ),
          );
          return;
        }

        throw Exception('Usuário não encontrado em nenhuma coleção.');
      } else {
        print("Erro: UID do usuário é nulo.");
      }
    } catch (e) {
      print("Erro durante o login: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer login: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
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
                  height: 300,
                ),
                const SizedBox(height: 16),
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
                          builder: (context) =>
                              const RegisterRequestorScreen()),
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