class UserModel {
  final String userId;
  final String responsible;
  final String email;
  final String photoUrl;
  final String? establishmentType;
  final String pixKey;
  late final String address;
  late final int numero; // Removido o uso de `late`
  // ignore: non_constant_identifier_names
  final bool IsNet;
  final double precoFixoOleo;
  final String cnpj;
  final String regiao;

  UserModel({
    required this.userId,
    required this.responsible,
    required this.email,
    required this.photoUrl,
    this.establishmentType,
    this.pixKey = 'Pix não informado',
    this.address = 'Endereço não informado',
    this.numero = 0, 
    // ignore: non_constant_identifier_names
    this.IsNet = false,
    this.precoFixoOleo = 0.0,
    this.cnpj = 'CNPJ não informado',
    this.regiao = 'Região não informada',
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      userId: id,
      responsible: data['responsible'] ?? 'Usuário',
      email: data['email'] ?? 'Email não disponível',
      photoUrl: data['photoUrl'] ?? '',
      establishmentType: data['establishmentType'],
      pixKey: data['pixKey'] ?? 'Pix não informado',
      address: data['address'] ?? 'Endereço não informado',
      numero: data['numero'] ?? 0, 
      IsNet: data['IsNet'] ?? false,
      precoFixoOleo: (data['precoFixoOleo'] is String)
          ? double.tryParse(data['precoFixoOleo']) ?? 0.0
          : (data['precoFixoOleo'] is num)
              ? (data['precoFixoOleo'] as num).toDouble()
              : 0.0,
      cnpj: data['cnpj'] ?? 'CNPJ não informado',
      regiao: data['regiao'] ?? 'Região não informada',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'responsible': responsible,
      'email': email,
      'photoUrl': photoUrl,
      'establishmentType': establishmentType,
      'pixKey': pixKey,
      'address': address,
      'numero': numero,
      'IsNet': IsNet,
      'precoFixoOleo': precoFixoOleo.toString(),
      'cnpj': cnpj,
      'regiao': regiao,
    };
  }
}
