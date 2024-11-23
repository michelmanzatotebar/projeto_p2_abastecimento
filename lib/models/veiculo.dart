class Veiculo {
  String? id;
  String nome;
  String modelo;
  String ano;
  String placa;
  String userId;

  Veiculo({
    this.id,
    required this.nome,
    required this.modelo,
    required this.ano,
    required this.placa,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'modelo': modelo,
      'ano': ano,
      'placa': placa,
      'userId': userId,
    };
  }

  factory Veiculo.fromMap(Map<String, dynamic> map, String documentId) {
    return Veiculo(
      id: documentId,
      nome: map['nome'] ?? '',
      modelo: map['modelo'] ?? '',
      ano: map['ano'] ?? '',
      placa: map['placa'] ?? '',
      userId: map['userId'] ?? '',
    );
  }
}