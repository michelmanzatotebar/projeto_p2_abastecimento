class Abastecimento {
  String? id;
  String veiculoId;
  double litros;
  double quilometragem;
  DateTime data;
  String userId;

  Abastecimento({
    this.id,
    required this.veiculoId,
    required this.litros,
    required this.quilometragem,
    required this.data,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'veiculoId': veiculoId,
      'litros': litros,
      'quilometragem': quilometragem,
      'data': data.toIso8601String(),
      'userId': userId,
    };
  }

  factory Abastecimento.fromMap(Map<String, dynamic> map, String documentId) {
    return Abastecimento(
      id: documentId,
      veiculoId: map['veiculoId'] ?? '',
      litros: (map['litros'] ?? 0).toDouble(),
      quilometragem: (map['quilometragem'] ?? 0).toDouble(),
      data: DateTime.parse(map['data']),
      userId: map['userId'] ?? '',
    );
  }
}