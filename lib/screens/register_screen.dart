import 'package:ciclou_projeto/screens/Collector/collector_dashboard.dart';
import 'package:ciclou_projeto/screens/Requestor/requestor_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

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
  final TextEditingController _cpfCnpjController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  void _registerUser() async {
    final String name = _nameController.text.trim();
    final String cpfCnpj = _cpfCnpjController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String phone = _phoneController.text.trim();
    final String address = _addressController.text.trim();
    final String city = _cityController.text.trim();
    final String neighborhood = _neighborhoodController.text.trim();
    final String state = _stateController.text.trim();

    if (name.isEmpty ||
        cpfCnpj.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        phone.isEmpty ||
        address.isEmpty ||
        city.isEmpty ||
        neighborhood.isEmpty ||
        state.isEmpty) {
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

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user?.uid;

      if (userId != null) {
        String collectionName =
            _selectedUserType == 'Solicitante' ? 'requestor' : 'collector';

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(userId)
            .set({
          'name': name,
          'cpfCnpj': cpfCnpj,
          'email': email,
          'phone': phone,
          'address': address,
          'city': city,
          'neighborhood': neighborhood,
          'state': state,
          'userType': _selectedUserType,
          'createdAt': FieldValue.serverTimestamp(),
        });

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
      }
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O e-mail já está em uso.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar: ${e.toString()}')),
        );
      }
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
                _buildTextField('CPF / CNPJ', false, _cpfCnpjController),
                const SizedBox(height: 16),
                _buildTextField('Email', false, _emailController),
                const SizedBox(height: 16),
                _buildTextField('Telefone', false, _phoneController),
                const SizedBox(height: 16),
                _buildTextField('Endereço', false, _addressController),
                const SizedBox(height: 16),
                _buildTextField('Cidade', false, _cityController),
                const SizedBox(height: 16),
                _buildTextField('Bairro', false, _neighborhoodController),
                const SizedBox(height: 16),
                _buildTextField('Estado', false, _stateController),
                const SizedBox(height: 16),
                _buildTextField('Senha', true, _passwordController,
                    isVisible: _isPasswordVisible),
                const SizedBox(height: 16),
                _buildTextField(
                    'Confirmar Senha', true, _confirmPasswordController,
                    isVisible: _isConfirmPasswordVisible),
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
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
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

  Widget _buildTextField(
      String hint, bool isPassword, TextEditingController controller,
      {bool isVisible = false}) {
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