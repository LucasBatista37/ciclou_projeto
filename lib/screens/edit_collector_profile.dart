import 'dart:io';
import 'package:ciclou_projeto/components/scaffold_mensager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditCollectorProfile extends StatefulWidget {
  const EditCollectorProfile({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditCollectorProfileState createState() => _EditCollectorProfileState();
}

class _EditCollectorProfileState extends State<EditCollectorProfile> {
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
  XFile? _profileImage;
  bool _isLoading = false;
  String? _profileUrl;

  final cnpjMask = MaskTextInputFormatter(mask: "##.###.###/####-##");
  final phoneMask = MaskTextInputFormatter(mask: "(##) #####-####");

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('collector')
            .doc(uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _businessNameController.text = data['businessName'] ?? '';
            _cnpjController.text = data['cnpj'] ?? '';
            _addressController.text = data['address'] ?? '';
            _responsibleController.text = data['responsible'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _licenseNumberController.text = data['licenseNumber'] ?? '';
            _licenseExpiryController.text = data['licenseExpiry'] ?? '';
            _profileUrl = data['photoUrl'];
          });
        }
      } catch (e) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro ao carregar dados.',
        );
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseFirestore.instance
            .collection('collector')
            .doc(uid)
            .update({
          'businessName': _businessNameController.text.trim(),
          'cnpj': _cnpjController.text.trim(),
          'address': _addressController.text.trim(),
          'responsible': _responsibleController.text.trim(),
          'phone': _phoneController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'licenseExpiry': _licenseExpiryController.text.trim(),
          'photoUrl': _profileImage?.path,
        });
        ScaffoldMessengerHelper.showSuccess(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Dados salvos com sucesso!',
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro ao salvar dados.',
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Usuário não autenticado!',
      );
    }
  }

  Future<void> _updatePhotoUrl(String photoPath) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('collector_photos')
            .child('$uid.jpg');

        final uploadTask = await storageRef.putFile(File(photoPath));
        final photoUrl = await uploadTask.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('collector')
            .doc(uid)
            .update({'photoUrl': photoUrl});

        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Foto de perfil atualizada com sucesso!',
        );
      } catch (e) {
        ScaffoldMessengerHelper.showError(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Erro ao atualizar foto.',
        );
      }
    } else {
      ScaffoldMessengerHelper.showError(
        context: context,
        message: 'Usuário não autenticado.',
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });

      await _updatePhotoUrl(pickedFile.path);
    } else {
      ScaffoldMessengerHelper.showWarning(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Nenhuma imagem selecionada.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _profileImage != null
                              ? FileImage(File(_profileImage!
                                  .path))
                              : (_profileUrl != null
                                  ? NetworkImage(
                                      _profileUrl!) 
                                  : null),
                          child: (_profileImage == null && _profileUrl == null)
                              ? Text(
                                  _responsibleController.text.isNotEmpty
                                      ? _responsibleController.text[0]
                                          .toUpperCase()
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Responsável',
                    controller: _responsibleController,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo obrigatório'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Telefone',
                    controller: _phoneController,
                    inputFormatters: [phoneMask],
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo obrigatório'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Endereço',
                    controller: _addressController,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo obrigatório'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Razão Social',
                    controller: _businessNameController,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'CNPJ',
                    controller: _cnpjController,
                    inputFormatters: [cnpjMask],
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo obrigatório'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Número da Licença',
                    controller: _licenseNumberController,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Data de Expiração da Licença',
                    controller: _licenseExpiryController,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveUserData,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text(
                      'Salvar Alterações',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
