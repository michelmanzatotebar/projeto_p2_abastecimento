import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeto_abastecimento_michel/models/abastecimento.dart';
import 'package:projeto_abastecimento_michel/models/veiculo.dart';
import 'package:projeto_abastecimento_michel/widgets/adicionar_veiculo_page.dart';
import 'package:projeto_abastecimento_michel/widgets/drawer_menu.dart';
import 'adicionar_abastecimento_page.dart';

class HistoricoAbastecimentosPage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatarData(String data) {
    try {
      if (data.contains('/')) {
        return data;
      }
      final DateTime dateTime = DateTime.parse(data);
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
    } catch (e) {
      print('Erro ao formatar data: $e');
      return data;
    }
  }

  Future<void> _excluirAbastecimento(BuildContext context, String abastecimentoId) async {
    try {
      await _firestore.collection('abastecimentos').doc(abastecimentoId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
          title: Text('Confirmar Exclusão'),
          content: Text('Deseja realmente excluir este abastecimento?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _excluirAbastecimento(context, abastecimentoId);
              },
              child: Text(
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
        title: Text('Histórico de Abastecimentos'),
      ),
      drawer: DrawerMenu(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('abastecimentos')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar histórico'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_gas_station, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
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

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
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
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(16),
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
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmarExclusao(context, doc.id),
                              ),
                            ],
                          ),
                          if (!veiculoExiste)
                            Text(
                              'Veículo foi excluído',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          SizedBox(height: 8),
                          Text(
                            'Data: ${_formatarData(data['data'])}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Litros: ${data['litros'].toString()}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Quilometragem: ${data['quilometragem'].toString()} km',
                            style: TextStyle(fontSize: 16),
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
        label: Text('Novo Abastecimento'),
        icon: Icon(Icons.local_gas_station),
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
              content: Text('Você precisa cadastrar um veículo primeiro'),
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
              title: Text('Selecione o veículo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: veiculosSnapshot.docs.map((doc) {
                    final data = doc.data();
                    return ListTile(
                      leading: Icon(Icons.directions_car),
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
                  child: Text('Cancelar'),
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
      final ultimoAbastecimento = await _firestore
          .collection('abastecimentos')
          .where('veiculoId', isEqualTo: veiculoId)
          .orderBy('data', descending: true)
          .limit(1)
          .get();

      double? ultimaQuilometragem;
      if (ultimoAbastecimento.docs.isNotEmpty) {
        ultimaQuilometragem = (ultimoAbastecimento.docs.first.data()['quilometragem'] ?? 0).toDouble();
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