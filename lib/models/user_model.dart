class UserModel {
  final String userId;
  final String responsible;
  final String email;
  final String photoUrl;
  final String? establishmentType;

  UserModel({
    required this.userId,
    required this.responsible,
    required this.email,
    required this.photoUrl,
    this.establishmentType,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      userId: id,
      responsible: data['responsible'] ?? 'Usuário',
      email: data['email'] ?? 'Email não disponível',
      photoUrl: data['photoUrl'] ?? '',
      establishmentType: data['establishmentType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'responsible': responsible,
      'email': email,
      'photoUrl': photoUrl,
      'establishmentType': establishmentType,
    };
  }
}
