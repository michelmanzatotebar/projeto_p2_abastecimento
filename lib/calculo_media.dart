import 'package:cloud_firestore/cloud_firestore.dart';

class CalculoMedia {
  static String _converterParaFormatoOrdenavel(String data) {
    try {
      List<String> partes = data.split('/');
      if (partes.length == 3) {
        return "${partes[2]}/${partes[1]}/${partes[0]}";
      }
      return data;
    } catch (e) {
      print("Erro ao converter data: $e");
      return data;
    }
  }

  static Future<double> calcularUltimaMedia(String veiculoId) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final abastecimentosQuery = await _firestore
          .collection('abastecimentos')
          .where('veiculoId', isEqualTo: veiculoId)
          .get();

      if (abastecimentosQuery.docs.length < 2) return 0.0;

      // Converter e ordenar todos os abastecimentos
      List<Map<String, dynamic>> abastecimentos = abastecimentosQuery.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Ordenar por data
      abastecimentos.sort((a, b) {
        String dataA = _converterParaFormatoOrdenavel(a['data'] as String);
        String dataB = _converterParaFormatoOrdenavel(b['data'] as String);
        return dataB.compareTo(dataA);
      });

      // Pegar os dois mais recentes
      final ultimoAbastecimento = abastecimentos[0];
      final penultimoAbastecimento = abastecimentos[1];

      final quilometragemAtual = double.parse(ultimoAbastecimento['quilometragem'].toString());
      final quilometragemAnterior = double.parse(penultimoAbastecimento['quilometragem'].toString());
      final litros = double.parse(ultimoAbastecimento['litros'].toString());

      if (quilometragemAtual <= quilometragemAnterior) return 0.0;
      return (quilometragemAtual - quilometragemAnterior) / litros;
    } catch (e) {
      print('Erro ao calcular média: $e');
      return 0.0;
    }
  }

  static Future<List<double>> calcularMedias(String veiculoId) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final abastecimentosQuery = await _firestore
          .collection('abastecimentos')
          .where('veiculoId', isEqualTo: veiculoId)
          .get();

      if (abastecimentosQuery.docs.length < 2) return [0.0, 0.0];

      // Converter e ordenar todos os abastecimentos
      List<Map<String, dynamic>> abastecimentos = abastecimentosQuery.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Ordenar por data
      abastecimentos.sort((a, b) {
        String dataA = _converterParaFormatoOrdenavel(a['data'] as String);
        String dataB = _converterParaFormatoOrdenavel(b['data'] as String);
        return dataB.compareTo(dataA);
      });

      // Calcular última média
      final quilometragemAtual = double.parse(abastecimentos[0]['quilometragem'].toString());
      final quilometragemAnterior = double.parse(abastecimentos[1]['quilometragem'].toString());
      final litrosUltimo = double.parse(abastecimentos[0]['litros'].toString());

      double ultimaMedia = (quilometragemAtual > quilometragemAnterior)
          ? (quilometragemAtual - quilometragemAnterior) / litrosUltimo
          : 0.0;

      // Calcular média geral
      double quilometragemTotal = 0;
      double litrosTotal = 0;

      for (int i = 0; i < abastecimentos.length - 1; i++) {
        final quiloAtual = double.parse(abastecimentos[i]['quilometragem'].toString());
        final quiloAnterior = double.parse(abastecimentos[i + 1]['quilometragem'].toString());

        if (quiloAtual > quiloAnterior) {
          quilometragemTotal += (quiloAtual - quiloAnterior);
          litrosTotal += double.parse(abastecimentos[i]['litros'].toString());
        }
      }

      double mediaGeral = litrosTotal > 0 ? quilometragemTotal / litrosTotal : 0.0;

      return [ultimaMedia, mediaGeral];
    } catch (e) {
      print('Erro ao calcular médias: $e');
      return [0.0, 0.0];
    }
  }
}