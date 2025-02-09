import 'dart:convert';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/screens/register_requestor_screen.dart';
import 'package:ciclou_projeto/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'login_screen.dart';

class RegisterCollectorScreen extends StatefulWidget {
  const RegisterCollectorScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterCollectorScreenState createState() =>
      _RegisterCollectorScreenState();
}

class _RegisterCollectorScreenState extends State<RegisterCollectorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _responsibleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _licenseExpiryController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  bool _isRegionEditable = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final cnpjMaskFormatter = MaskTextInputFormatter(mask: "##.###.###/####-##");
  final phoneMaskFormatter = MaskTextInputFormatter(mask: "(##) #####-####");
  final dateMaskFormatter = MaskTextInputFormatter(mask: "##/##/####");

  bool _isValidCnpj(String cnpj) {
    return RegExp(r'\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}').hasMatch(cnpj);
  }

  Future<void> _registerCollector() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: "Por favor, preencha todos os campos obrigatórios.",
      );
      return;
    }

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
            .collection('collector')
            .doc(userId)
            .set({
          'businessName': _businessNameController.text.trim(),
          'cnpj': _cnpjController.text.trim(),
          'address': _addressController.text.trim(),
          'responsible': _responsibleController.text.trim(),
          'phone': _phoneController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'licenseExpiry': _licenseExpiryController.text.trim(),
          'birthDate': _birthDateController.text.trim(),
          'email': _emailController.text.trim(),
          'userType': 'Coletor',
          'photoUrl': null,
          'amountOil': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'ibama': null,
          'licenseOperation': null,
          'operatingPermit': null,
          'avcb': null,
          'IsNet': false,
          'numero': int.tryParse(_numberController.text.trim()) ?? 0,
          'regiao': _regionController.text.trim(),
        });

        ScaffoldMessengerHelper.showSuccess(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Coletor registrado com sucesso!',
        );

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Tratamento de erros do Firebase Authentication
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'Este e-mail já está em uso. Por favor, use outro ou faça login.';
          break;
        case 'weak-password':
          errorMessage = 'A senha é muito fraca. Utilize uma senha mais forte.';
          break;
        case 'invalid-email':
          errorMessage = 'E-mail inválido. Verifique e tente novamente.';
          break;
        default:
          errorMessage =
              'Ocorreu um erro inesperado. Tente novamente mais tarde.';
          break;
      }

      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message: errorMessage,
      );
    } catch (e) {
      // Tratamento de erros inesperados
      ScaffoldMessengerHelper.showError(
        // ignore: use_build_context_synchronously
        context: context,
        message:
            'Erro inesperado ao registrar o coletor. Por favor, tente novamente.',
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                        'Você está se cadastrando como um coletor.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                      'Registrar como Solicitante',
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 32),
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
                    inputFormatters: [cnpjMaskFormatter],
                  ),
                  const SizedBox(height: 16),
                  _buildAddressField(),
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
                    'Data de Nascimento',
                    _birthDateController,
                    (value) => value!.isEmpty
                        ? 'Por favor, insira a data de nascimento.'
                        : null,
                    inputFormatters: [dateMaskFormatter],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Telefone',
                    _phoneController,
                    (value) =>
                        value!.isEmpty ? 'Por favor, insira o telefone.' : null,
                    inputFormatters: [phoneMaskFormatter],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Número da Licença de Operação',
                    _licenseNumberController,
                    (value) => value!.isEmpty
                        ? 'Por favor, insira o número da licença.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Data de Vencimento da Licença',
                    _licenseExpiryController,
                    (value) => value!.isEmpty
                        ? 'Por favor, insira a data de vencimento.'
                        : null,
                    inputFormatters: [dateMaskFormatter],
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
                          onPressed: _registerCollector,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: const Center(
                            child: Text(
                              'Registrar Coletor',
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

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            hintText: "Exemplo: 12345-678",
            labelText: "CEP",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          inputFormatters: [
            MaskTextInputFormatter(mask: '#####-###'),
          ],
          onChanged: (value) {
            if (value.length == 9) {
              _fetchAddressFromCep(value);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira o CEP.';
            }
            if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(value)) {
              return 'CEP inválido. Use o formato 12345-678.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: "Exemplo: Rua das Flores",
            labelText: "Logradouro (Rua)",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira o logradouro.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              flex: 3,
              child: TextFormField(
                controller: _neighborhoodController,
                readOnly: !_isRegionEditable,
                decoration: InputDecoration(
                  hintText: "Exemplo: Centro",
                  labelText: "Bairro",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  if (_isRegionEditable) {
                    setState(() {
                      final cidade = _city;
                      final estado = _state;
                      _regionController.text = "$value, $cidade - $estado";
                    });
                  }
                },
                validator: (value) {
                  if (!_isRegionEditable) {
                    return null;
                  }
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o bairro.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              flex: 2,
              child: TextFormField(
                controller: _numberController,
                decoration: InputDecoration(
                  hintText: "Exemplo: 123",
                  labelText: "Número",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o número.';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Número inválido. Use apenas dígitos.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _regionController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: "Exemplo: Centro, São Paulo - SP",
            labelText: "Região",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira a região.';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _city = "";
  String _state = "";

  Future<void> _fetchAddressFromCep(String cep) async {
    final url = 'https://viacep.com.br/ws/$cep/json/';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('erro')) {
          _showErrorSnackBar('CEP inválido ou não encontrado.');
          return;
        }

        setState(() {
          final logradouro = data["logradouro"] ?? '';
          final bairro = data["bairro"];
          _city = data["localidade"] ?? '';
          _state = data["uf"] ?? '';

          _addressController.text = logradouro;
          _neighborhoodController.text = bairro ?? '';
          _regionController.text =
              "${bairro ?? 'Bairro não especificado'}, $_city - $_state";

          _isRegionEditable = bairro == null || bairro.isEmpty;
        });
      } else {
        _showErrorSnackBar('Erro ao buscar informações do CEP.');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao conectar-se ao serviço de CEP.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    String? Function(String?) validator, {
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: inputFormatters,
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
