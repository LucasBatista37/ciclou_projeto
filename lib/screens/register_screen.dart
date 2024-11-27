import 'package:ciclou_projeto/screens/Collector/collector_dashboard.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_dashboard.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:ciclou_projeto/services/firebase_service.dart'; // Serviço do Firebase que criamos

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _selectedUserType = 'Solicitante';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _registerUser() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não correspondem.')),
      );
      return;
    }

    // Registrar usuário no Firebase
    final user = await FirebaseService.registerWithEmail(email, password, name, _selectedUserType);

    if (user != null) {
      // Redirecionar com base no tipo de usuário
      if (_selectedUserType == 'Solicitante') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RequestorDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CollectorDashboard()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao criar conta. Tente novamente.')),
      );
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
                Image.asset(
                  'assets/ciclou.png',
                  height: 300,
                ),
                const SizedBox(height: 16),
                _buildTextField('Nome', false, _nameController),
                const SizedBox(height: 16),
                _buildTextField('Email', false, _emailController),
                const SizedBox(height: 16),
                _buildTextField('Senha', true, _passwordController, isVisible: _isPasswordVisible),
                const SizedBox(height: 16),
                _buildTextField('Confirmar Senha', true, _confirmPasswordController, isVisible: _isConfirmPasswordVisible),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: ['Solicitante', 'Coletor'].map((String userType) {
                    return DropdownMenuItem<String>(
                      value: userType,
                      child: Text(userType),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUserType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Center(
                    child: Text(
                      'Criar Conta',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Já tem uma conta? Entrar',
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

  Widget _buildTextField(String hint, bool isPassword, TextEditingController controller, {bool isVisible = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !isVisible : false,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    if (hint == 'Senha') {
                      _isPasswordVisible = !_isPasswordVisible;
                    } else if (hint == 'Confirmar Senha') {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    }
                  });
                },
              )
            : null,
      ),
    );
  }
}
