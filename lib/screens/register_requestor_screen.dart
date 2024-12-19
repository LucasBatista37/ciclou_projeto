import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'register_collector_screen.dart';
import 'login_screen.dart';

class RegisterRequestorScreen extends StatefulWidget {
  const RegisterRequestorScreen({super.key});

  @override
  _RegisterRequestorScreenState createState() =>
      _RegisterRequestorScreenState();
}

class _RegisterRequestorScreenState extends State<RegisterRequestorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _responsibleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedEstablishmentType;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  bool _isValidCnpj(String cnpj) {
    return RegExp(r'^\d{14}$').hasMatch(cnpj);
  }

  Future<void> _registerRequestor() async {
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
        await FirebaseFirestore.instance
            .collection('requestor')
            .doc(userId)
            .set({
          'businessName': _businessNameController.text.trim(),
          'cnpj': _cnpjController.text.trim(),
          'address': _addressController.text.trim(),
          'responsible': _responsibleController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'userType': 'Solicitante',
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'establishmentType': _selectedEstablishmentType,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitante registrado com sucesso!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage = 'O e-mail já está em uso.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'A senha é muito fraca.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'E-mail inválido.';
      } else {
        errorMessage = 'Erro: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                    height: 400,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Razão Social',
                    _businessNameController,
                    (value) => value!.isEmpty
                        ? 'Por favor, insira a razão social.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'CNPJ',
                    _cnpjController,
                    (value) {
                      if (value!.isEmpty) return 'Por favor, insira o CNPJ.';
                      if (!_isValidCnpj(value)) {
                        return 'CNPJ inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Endereço, Cidade e Estado',
                    _addressController,
                    (value) =>
                        value!.isEmpty ? 'Por favor, insira o endereço.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Responsável',
                    _responsibleController,
                    (value) => value!.isEmpty
                        ? 'Por favor, insira o nome do responsável.'
                        : null,
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
                  _buildPasswordTextField('Senha', _passwordController, true),
                  const SizedBox(height: 16),
                  _buildPasswordTextField(
                      'Confirmar Senha', _confirmPasswordController, false),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _registerRequestor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: const Center(
                            child: Text(
                              'Registrar Solicitante',
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
                  const Text("Ou"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const RegisterCollectorScreen()),
                      );
                    },
                    child: const Text(
                      'Registrar como Coletor',
                      style: TextStyle(fontSize: 16, color: Colors.blue),
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

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedEstablishmentType,
      onChanged: (value) {
        setState(() {
          _selectedEstablishmentType = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Selecione o tipo de estabelecimento',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: (value) => value == null
          ? 'Por favor, selecione o tipo de estabelecimento.'
          : null,
      items: const [
        DropdownMenuItem(
          value: 'Restaurante',
          child: Text('Restaurante'),
        ),
        DropdownMenuItem(
          value: 'Hotel',
          child: Text('Hotel'),
        ),
        DropdownMenuItem(
          value: 'Condomínio',
          child: Text('Condomínio'),
        ),
      ],
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
