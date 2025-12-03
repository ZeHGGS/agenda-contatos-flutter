class Contact {
  int? id;
  String nome;
  String? sobrenome;
  String? telefone;
  String? email;
  String? dataNascimento;
  bool isFavorite;

  String? cep;
  String? endereco;
  String? bairro;
  String? cidade;
  String? estado;

  Contact({
    this.id,
    required this.nome,
    this.sobrenome,
    this.telefone,
    this.email,
    this.dataNascimento,
    this.isFavorite = false,
    this.cep,
    this.endereco,
    this.bairro,
    this.cidade,
    this.estado,
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
      cep: map['cep'],
      endereco: map['endereco'],
      bairro: map['bairro'],
      cidade: map['cidade'],
      estado: map['estado'],
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
      'cep': cep,
      'endereco': endereco,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
    };
  }
}