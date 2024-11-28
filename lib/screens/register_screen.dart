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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  bool _isLoading = false;

  bool _isValidCpfCnpj(String cpfCnpj) {
    if (cpfCnpj.length == 11) {
      return RegExp(r'^\d{11}$').hasMatch(cpfCnpj); 
    } else if (cpfCnpj.length == 14) {
      return RegExp(r'^\d{14}$').hasMatch(cpfCnpj); 
    }
    return false;
  }

  void _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user?.uid;

      if (userId != null) {
        String collectionName =
            _selectedUserType == 'Solicitante' ? 'requestor' : 'collector';

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(userId)
            .set({
          'name': _nameController.text.trim(),
          'cpfCnpj': _cpfCnpjController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'neighborhood': _neighborhoodController.text.trim(),
          'state': _stateController.text.trim(),
          'userType': _selectedUserType,
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _selectedUserType == 'Solicitante'
                ? const RequestorDashboard()
                : const CollectorDashboard(),
          ),
        );
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/ciclou.png',
                    height: 300,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Nome',
                    _nameController,
                    (value) =>
                        value!.isEmpty ? 'Por favor, insira seu nome.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'CPF / CNPJ',
                    _cpfCnpjController,
                    (value) {
                      if (value!.isEmpty)
                        return 'Por favor, insira o CPF/CNPJ.';
                      if (!_isValidCpfCnpj(value)) {
                        return 'CPF ou CNPJ inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Email',
                    _emailController,
                    (value) {
                      if (value!.isEmpty) return 'Por favor, insira o e-mail.';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                        return 'E-mail inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Telefone',
                    _phoneController,
                    (value) =>
                        value!.isEmpty ? 'Por favor, insira o telefone.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Endereço',
                    _addressController,
                    (value) =>
                        value!.isEmpty ? 'Por favor, insira o endereço.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Cidade',
                    _cityController,
                    (value) =>
                        value!.isEmpty ? 'Por favor, insira a cidade.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Bairro',
                    _neighborhoodController,
                    (value) =>
                        value!.isEmpty ? 'Por favor, insira o bairro.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Estado',
                    _stateController,
                    (value) =>
                        value!.isEmpty ? 'Por favor, insira o estado.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordTextField('Senha', _passwordController, true),
                  const SizedBox(height: 16),
                  _buildPasswordTextField(
                      'Confirmar Senha', _confirmPasswordController, false),
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
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
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
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
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
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordTextField(
      String hint, TextEditingController controller, bool isPasswordField) {
    return TextFormField(
      controller: controller,
      obscureText:
          isPasswordField ? !_isPasswordVisible : !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordField
                ? (_isPasswordVisible ? Icons.visibility : Icons.visibility_off)
                : (_isConfirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off),
          ),
          onPressed: () {
            setState(() {
              if (isPasswordField) {
                _isPasswordVisible = !_isPasswordVisible;
              } else {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              }
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, insira a $hint.';
        }
        if (isPasswordField && value.length < 6) {
          return 'A senha deve ter pelo menos 6 caracteres.';
        }
        if (!isPasswordField && value != _passwordController.text.trim()) {
          return 'As senhas não correspondem.';
        }
        return null;
      },
    );
  }
}
