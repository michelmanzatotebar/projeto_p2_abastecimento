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
    String dataFormatada = "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";

    return {
      'veiculoId': veiculoId,
      'litros': litros,
      'quilometragem': quilometragem,
      'data': dataFormatada,
      'userId': userId,
    };
  }

  factory Abastecimento.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseData(String data) {
      try {
        if (data.contains('T')) {
          return DateTime.parse(data);
        }

        List<String> partes = data.split('/');
        if (partes.length == 3) {
          return DateTime(
            int.parse(partes[2]), // ano
            int.parse(partes[1]), // mês
            int.parse(partes[0]), // dia
          );
        }
        return DateTime.now();
      } catch (e) {
        print('Erro ao converter data: $e');
        return DateTime.now();
      }
    }

    return Abastecimento(
      id: documentId,
      veiculoId: map['veiculoId'] ?? '',
      litros: (map['litros'] ?? 0).toDouble(),
      quilometragem: (map['quilometragem'] ?? 0).toDouble(),
      data: parseData(map['data']),
      userId: map['userId'] ?? '',
    );
  }
}