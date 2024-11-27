import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Função para registrar usuário
  static Future<User?> registerWithEmail(String email, String password, String name, String userType) async {
    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Salvar dados do usuário no Firestore
      await firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'email': email,
        'userType': userType, // "Solicitante" ou "Coletor"
        'createdAt': DateTime.now(),
      });

      return userCredential.user;
    } catch (e) {
      print("Erro ao registrar: $e");
      return null;
    }
  }

  // Função para login
  static Future<User?> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Erro ao fazer login: $e");
      return null;
    }
  }

  // Verificar usuário logado
  static User? getCurrentUser() {
    return auth.currentUser;
  }

  // Logout
  static Future<void> logout() async {
    await auth.signOut();
  }
}
