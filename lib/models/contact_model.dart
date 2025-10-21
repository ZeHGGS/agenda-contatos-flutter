class Contact {
  int? id;
  String nome;
  String? sobrenome;
  String? telefone;
  String? email;
  String? dataNascimento;
  bool isFavorite;

  Contact({
    this.id,
    required this.nome,
    this.sobrenome,
    this.telefone,
    this.email,
    this.dataNascimento,
    this.isFavorite = false,
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      nome: map['nome'],
      sobrenome: map['sobrenome'],
      telefone: map['telefone'],
      email: map['email'],
      dataNascimento: map['dataNascimento'],
      isFavorite: map['isFavorite'] == 1, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'sobrenome': sobrenome,
      'telefone': telefone,
      'email': email,
      'dataNascimento': dataNascimento,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }
}