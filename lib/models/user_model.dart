class UserModel {
  final String userId;
  final String responsible;
  final String email;
  final String photoUrl;
  final String? establishmentType;
  final String pixKey; // Agora o pixKey é obrigatório

  UserModel({
    required this.userId,
    required this.responsible,
    required this.email,
    required this.photoUrl,
    this.establishmentType,
    this.pixKey = 'Pix não informado', // Valor padrão
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      userId: id,
      responsible: data['responsible'] ?? 'Usuário',
      email: data['email'] ?? 'Email não disponível',
      photoUrl: data['photoUrl'] ?? '',
      establishmentType: data['establishmentType'],
      pixKey: data['pixKey'] ?? 'Pix não informado', // Valor padrão ao criar
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'responsible': responsible,
      'email': email,
      'photoUrl': photoUrl,
      'establishmentType': establishmentType,
      'pixKey': pixKey, // Sempre salva a chave Pix
    };
  }
}
