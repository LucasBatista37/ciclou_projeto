class UserModel {
  final String userId;
  final String responsible;
  final String email;

  UserModel({
    required this.userId,
    required this.responsible,
    required this.email,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      userId: id,
      responsible: data['responsible'] ?? 'Usuário',
      email: data['email'] ?? 'Email não disponível',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'responsible': responsible,
      'email': email,
    };
  }
}
