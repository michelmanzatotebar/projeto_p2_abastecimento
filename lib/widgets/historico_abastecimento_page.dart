import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeto_abastecimento_michel/widgets/adicionar_veiculo_page.dart';
import 'package:projeto_abastecimento_michel/widgets/drawer_menu.dart';
import 'adicionar_abastecimento_page.dart';

class HistoricoAbastecimentosPage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _converterParaFormatoOrdenavel(String data) {
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

  String _formatarData(String data) {
    try {
      if (data.contains('/')) {
        List<String> partes = data.split('/');
        if (partes.length == 3) {
          if (partes[0].length == 4) { // Se começa com ano (YYYY)
            return "${partes[2]}/${partes[1]}/${partes[0]}";
          }
          return data;
        }
      }
      DateTime dateTime = DateTime.parse(data);
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
    } catch (e) {
      print("Erro ao formatar data: $e");
      return data;
    }
  }

  Future<void> _excluirAbastecimento(BuildContext context, String abastecimentoId) async {
    try {
      await _firestore.collection('abastecimentos').doc(abastecimentoId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abastecimento excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao excluir abastecimento: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir abastecimento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmarExclusao(BuildContext context, String abastecimentoId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Deseja realmente excluir este abastecimento?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _excluirAbastecimento(context, abastecimentoId);
              },
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Abastecimentos'),
      ),
      drawer: DrawerMenu(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('abastecimentos')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar histórico'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_gas_station, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum abastecimento registrado',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
          docs.sort((a, b) {
            String dataA = _converterParaFormatoOrdenavel(a['data'] as String);
            String dataB = _converterParaFormatoOrdenavel(b['data'] as String);
            return dataB.compareTo(dataA);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('veiculos').doc(data['veiculoId']).get(),
                builder: (context, veiculoSnapshot) {
                  String veiculoInfo = 'Veículo não encontrado';
                  bool veiculoExiste = false;

                  if (veiculoSnapshot.hasData && veiculoSnapshot.data!.exists) {
                    final veiculoData = veiculoSnapshot.data!.data() as Map<String, dynamic>;
                    veiculoInfo = '${veiculoData['nome']} - ${veiculoData['placa']}';
                    veiculoExiste = true;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  veiculoInfo,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: veiculoExiste ? Colors.black : Colors.red,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmarExclusao(context, doc.id),
                              ),
                            ],
                          ),
                          if (!veiculoExiste)
                            const Text(
                              'Veículo foi excluído',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Data: ${_formatarData(data['data'])}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Litros: ${data['litros'].toString()}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Quilometragem: ${data['quilometragem'].toString()} km',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogSelecaoVeiculo(context),
        label: const Text('Novo Abastecimento'),
        icon: const Icon(Icons.local_gas_station),
      ),
    );
  }

  void _mostrarDialogSelecaoVeiculo(BuildContext context) async {
    try {
      final veiculosSnapshot = await _firestore
          .collection('veiculos')
          .where('userId', isEqualTo: user?.uid)
          .get();

      if (!veiculosSnapshot.docs.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Você precisa cadastrar um veículo primeiro'),
              action: SnackBarAction(
                label: 'Cadastrar',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdicionarVeiculoPage(),
                    ),
                  );
                },
              ),
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        final result = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Selecione o veículo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: veiculosSnapshot.docs.map((doc) {
                    final data = doc.data();
                    return ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text('${data['nome']} - ${data['placa']}'),
                      onTap: () {
                        Navigator.pop(context, doc.id);
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );

        if (result != null && context.mounted) {
          _navegarParaAdicionarAbastecimento(context, result);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar veículos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navegarParaAdicionarAbastecimento(BuildContext context, String veiculoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('abastecimentos')
          .where('veiculoId', isEqualTo: veiculoId)
          .get();

      double? ultimaQuilometragem;

      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> abastecimentos = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        abastecimentos.sort((a, b) {
          String dataA = _converterParaFormatoOrdenavel(a['data'] as String);
          String dataB = _converterParaFormatoOrdenavel(b['data'] as String);
          return dataB.compareTo(dataA);
        });

        if (abastecimentos.isNotEmpty) {
          ultimaQuilometragem = double.parse(abastecimentos[0]['quilometragem'].toString());
        }
      }

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdicionarAbastecimentoPage(
              veiculoId: veiculoId,
              ultimaQuilometragem: ultimaQuilometragem,
            ),
          ),
        );
      }
    } catch (e) {
      print('Erro ao navegar: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir tela de abastecimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}