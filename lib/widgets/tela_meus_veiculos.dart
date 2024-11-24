import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeto_abastecimento_michel/calculo_media.dart';
import 'package:projeto_abastecimento_michel/widgets/drawer_menu.dart';
import 'package:projeto_abastecimento_michel/models/veiculo.dart';
import 'package:projeto_abastecimento_michel/widgets/detalhes_veiculo_page.dart';

class TelaMeusVeiculos extends StatefulWidget {
  @override
  _TelaMeusVeiculosState createState() => _TelaMeusVeiculosState();
}

class _TelaMeusVeiculosState extends State<TelaMeusVeiculos> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _editVeiculo(Veiculo veiculo) async {
    final TextEditingController nomeController = TextEditingController(text: veiculo.nome);
    final TextEditingController modeloController = TextEditingController(text: veiculo.modelo);
    final TextEditingController anoController = TextEditingController(text: veiculo.ano);
    final TextEditingController placaController = TextEditingController(text: veiculo.placa);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Veículo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Veículo',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: modeloController,
                decoration: InputDecoration(
                  labelText: 'Modelo',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: anoController,
                decoration: InputDecoration(
                  labelText: 'Ano',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: placaController,
                decoration: InputDecoration(
                  labelText: 'Placa',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('veiculos').doc(veiculo.id).update({
                  'nome': nomeController.text.trim(),
                  'modelo': modeloController.text.trim(),
                  'ano': anoController.text.trim(),
                  'placa': placaController.text.trim().toUpperCase(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Veículo atualizado com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao atualizar veículo: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVeiculo(String veiculoId) async {
    try {
      final abastecimentosQuery = await _firestore
          .collection('abastecimentos')
          .where('veiculoId', isEqualTo: veiculoId)
          .get();

      final batch = _firestore.batch();
      for (var doc in abastecimentosQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await _firestore.collection('veiculos').doc(veiculoId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veículo e seus abastecimentos excluídos com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao excluir veículo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir veículo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Veículos'),
      ),
      drawer: DrawerMenu(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('veiculos')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar veículos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum veículo cadastrado',
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
            padding: EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final veiculo = Veiculo.fromMap(doc.data() as Map<String, dynamic>, doc.id);

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.directions_car, color: Colors.white),
                      ),
                      title: Text(
                        veiculo.nome,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Modelo: ${veiculo.modelo}'),
                          Text('Ano: ${veiculo.ano}'),
                          Text('Placa: ${veiculo.placa}'),
                          FutureBuilder<double>(
                            future: CalculoMedia.calcularUltimaMedia(veiculo.id!),
                            builder: (context, mediaSnapshot) {
                              if (mediaSnapshot.connectionState == ConnectionState.waiting) {
                                return Text('Calculando média...');
                              }
                              double media = mediaSnapshot.data ?? 0.0;
                              return Text(
                                media > 0
                                    ? 'Última média: ${media.toStringAsFixed(1)} km/L'
                                    : 'Sem média',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.info, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetalhesVeiculoPage(veiculo: veiculo),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editVeiculo(veiculo),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Confirmar exclusão'),
                                  content: Text('Deseja realmente excluir este veículo e todos os seus abastecimentos?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteVeiculo(veiculo.id!);
                                      },
                                      child: Text(
                                        'Excluir',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}