import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:ciclou_projeto/screens/register_requestor_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
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
  final TextEditingController _birthDateController = TextEditingController();

  final FocusNode _addressFocusNode = FocusNode();

  bool _isAddressValid = false;
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
    if (!_formKey.currentState!.validate() || !_isAddressValid) {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: "Por favor, selecione um endereço válido das sugestões.",
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

                  _buildAutocompleteAddressField(),
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

                  // Botão de envio
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _registerCollector,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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

  Widget _buildAutocompleteAddressField() {
    final googleApiKey = dotenv.env['GOOGLE_API_KEY'];

    // Verifica se a chave está disponível
    if (googleApiKey == null || googleApiKey.isEmpty) {
      throw Exception('Google API key is not set or empty in the .env file');
    }

    _addressController.addListener(() {
      setState(() {
        _isAddressValid = false;
      });
    });

    return GooglePlaceAutoCompleteTextField(
      textEditingController: _addressController,
      focusNode: _addressFocusNode,
      googleAPIKey: googleApiKey, // Usa a chave validada
      inputDecoration: InputDecoration(
        hintText: "Endereço completo",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      countries: ["br"],
      isLatLngRequired: false,
      getPlaceDetailWithLatLng: (prediction) {},
      itemClick: (prediction) {
        _addressController.text = prediction.description!;
        _addressController.selection = TextSelection.fromPosition(
          TextPosition(offset: prediction.description!.length),
        );

        setState(() {
          _isAddressValid = true;
        });

        FocusScope.of(context).requestFocus(FocusNode());
      },
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
