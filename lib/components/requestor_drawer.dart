import 'dart:io';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:ciclou_projeto/screens/Requestor/certificates_screen.dart';
import 'package:ciclou_projeto/screens/configuration_screen.dart';
import 'package:ciclou_projeto/screens/edit_requestor_profile.dart';
import 'package:flutter/material.dart';

class RequestorDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? profileImageUrl;
  final UserModel user;

  final VoidCallback onEditProfile;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const RequestorDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    this.profileImageUrl,
    required this.user,
    required this.onEditProfile,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(
            icon: Icons.settings,
            text: 'Configurações',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PerfilConfiguracoesScreen(
                    user: user,
                  ),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.edit,
            text: 'Editar Perfil',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditRequestorProfile(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.card_membership_rounded,
            text: 'Certificados',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CertificatesScreen(user: user),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Sair',
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Colors.green,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profileImageUrl == null || profileImageUrl!.isEmpty)
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            )
          else
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _getProfileImage(profileImageUrl),
            ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          Flexible(
            child: Text(
              userEmail,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      onTap: onTap,
    );
  }

  ImageProvider _getProfileImage(String? profileImageUrl) {
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      return const AssetImage('assets/images/default_profile.jpg');
    } else {
      try {
        if (File(profileImageUrl).existsSync()) {
          return FileImage(File(profileImageUrl));
        }
      } catch (e) {
        // Ignorar erros ao carregar a imagem local
      }
      return NetworkImage(profileImageUrl);
    }
  }
}
