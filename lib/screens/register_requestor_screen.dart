import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _responsibleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  String? _selectedEstablishmentType;
  String _selectedDocumentType = 'CNPJ';

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final _cpfMask = MaskTextInputFormatter(mask: '###.###.###-##');
  final _cnpjMask = MaskTextInputFormatter(mask: '##.###.###/####-##');
  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####');
  final _dateMask = MaskTextInputFormatter(mask: '##/##/####');

  bool _isValidDocument(String document) {
    final cleanedDocument = document.replaceAll(RegExp(r'\D'), '');
    if (_selectedDocumentType == 'CNPJ') {
      return RegExp(r'^\d{14}$').hasMatch(cleanedDocument);
    } else if (_selectedDocumentType == 'CPF') {
      return _validateCPF(cleanedDocument);
    }
    return false;
  }

  bool _validateCPF(String cpf) {
    final cleanedCPF = cpf.replaceAll(RegExp(r'\D'), '');

    if (cleanedCPF.length != 11) return false;

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cleanedCPF[i]) * (10 - i);
    }
    int firstVerifier = (sum * 10) % 11;
    if (firstVerifier == 10) firstVerifier = 0;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cleanedCPF[i]) * (11 - i);
    }
    int secondVerifier = (sum * 10) % 11;
    if (secondVerifier == 10) secondVerifier = 0;

    return firstVerifier == int.parse(cleanedCPF[9]) &&
        secondVerifier == int.parse(cleanedCPF[10]);
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
          'documentType': _selectedDocumentType,
          'document': _documentController.text.trim(),
          'address': _addressController.text.trim(),
          'responsible': _responsibleController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'birthDate': _birthDateController.text.trim(),
          'userType': 'Solicitante',
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'establishmentType': _selectedEstablishmentType,
          'IsNet': false,
        });

        ScaffoldMessengerHelper.showSuccess(
          context: context,
          message: 'Solicitante registrado com sucesso!',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'Este e-mail já está em uso. Por favor, use outro ou faça login.';
          break;
        case 'weak-password':
          errorMessage = 'A senha é muito fraca. Escolha uma senha mais forte.';
          break;
        case 'invalid-email':
          errorMessage =
              'E-mail inválido. Verifique o formato e tente novamente.';
          break;
        default:
          errorMessage =
              'Ocorreu um erro inesperado ao criar a conta. Tente novamente.';
          break;
      }

      ScaffoldMessengerHelper.showError(
        context: context,
        message: errorMessage,
      );
    } catch (e) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Erro inesperado ao registrar solicitante. Por favor, tente novamente.',
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
                      'Você está se cadastrando como um solicitante.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
                _buildDocumentDropdownField(),
                const SizedBox(height: 16),
                _buildTextField(
                  _selectedDocumentType,
                  _documentController,
                  (value) {
                    if (value!.isEmpty) {
                      return 'Por favor, insira o $_selectedDocumentType.';
                    }
                    if (!_isValidDocument(value)) {
                      return '$_selectedDocumentType inválido.';
                    }
                    return null;
                  },
                  inputFormatters: [
                    _selectedDocumentType == 'CNPJ' ? _cnpjMask : _cpfMask,
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Data de Nascimento',
                  _birthDateController,
                  (value) => value!.isEmpty
                      ? 'Por favor, insira a data de nascimento.'
                      : null,
                  inputFormatters: [_dateMask],
                ),
                const SizedBox(height: 16),
                _buildDropdownField(),
                const SizedBox(height: 16),
                _buildTextField(
                  'Endereço',
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
                  inputFormatters: [_phoneMask],
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
    ));
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    String? Function(String?) validator, {
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: validator,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildDocumentDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedDocumentType,
      onChanged: (value) {
        setState(() {
          _selectedDocumentType = value!;
        });
      },
      decoration: InputDecoration(
        hintText: 'Tipo de Documento',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'CNPJ',
          child: Text('CNPJ'),
        ),
        DropdownMenuItem(
          value: 'CPF',
          child: Text('CPF'),
        ),
      ],
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
        DropdownMenuItem(
          value: 'Escola',
          child: Text('Escola'),
        ),
        DropdownMenuItem(
          value: 'Residência',
          child: Text('Residência'),
        ),
        DropdownMenuItem(
          value: 'Loja',
          child: Text('Loja'),
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
