import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeto_abastecimento_michel/models/abastecimento.dart';
import 'package:projeto_abastecimento_michel/widgets/drawer_menu.dart';

class AdicionarAbastecimentoPage extends StatefulWidget {
  final String veiculoId;
  final double? ultimaQuilometragem;

  const AdicionarAbastecimentoPage({
    Key? key,
    required this.veiculoId,
    this.ultimaQuilometragem,
  }) : super(key: key);

  @override
  _AdicionarAbastecimentoPageState createState() => _AdicionarAbastecimentoPageState();
}

class _AdicionarAbastecimentoPageState extends State<AdicionarAbastecimentoPage> {
  final _formKey = GlobalKey<FormState>();
  final _litrosController = TextEditingController();
  final _quilometragemController = TextEditingController();
  final _dataController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _litrosController.dispose();
    _quilometragemController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String date) {
    try {
      List<String> parts = date.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Erro ao converter data: $e');
    }
    return null;
  }

  Future<void> _salvarAbastecimento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não está logado');

      final litros = double.parse(_litrosController.text.replaceAll(',', '.'));
      final quilometragem = double.parse(_quilometragemController.text.replaceAll(',', '.'));

      final dataAbastecimento = _parseDate(_dataController.text);
      if (dataAbastecimento == null) throw Exception('Data inválida');

      if (widget.ultimaQuilometragem != null && quilometragem <= widget.ultimaQuilometragem!) {
        throw Exception('A quilometragem deve ser maior que a última registrada (${widget.ultimaQuilometragem!.toStringAsFixed(1)} km)');
      }

      final abastecimento = Abastecimento(
        veiculoId: widget.veiculoId,
        litros: litros,
        quilometragem: quilometragem,
        data: dataAbastecimento,
        userId: user.uid,
      );

      await FirebaseFirestore.instance
          .collection('abastecimentos')
          .add(abastecimento.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abastecimento registrado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar abastecimento: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Abastecimento'),
      ),
      drawer: DrawerMenu(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _litrosController,
                        decoration: InputDecoration(
                          labelText: 'Quantidade de Litros',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_gas_station),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a quantidade de litros';
                          }
                          try {
                            double.parse(value.replaceAll(',', '.'));
                          } catch (e) {
                            return 'Por favor, insira um número válido';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _quilometragemController,
                        decoration: InputDecoration(
                          labelText: 'Quilometragem Atual',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.speed),
                          helperText: widget.ultimaQuilometragem != null
                              ? 'Última quilometragem: ${widget.ultimaQuilometragem!.toStringAsFixed(1)} km'
                              : null,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a quilometragem atual';
                          }
                          try {
                            final km = double.parse(value.replaceAll(',', '.'));
                            if (widget.ultimaQuilometragem != null && km <= widget.ultimaQuilometragem!) {
                              return 'A quilometragem deve ser maior que a última registrada';
                            }
                          } catch (e) {
                            return 'Por favor, insira um número válido';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _dataController,
                        decoration: InputDecoration(
                          labelText: 'Data do Abastecimento (xx/yy/aaaa)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                          hintText: 'Ex: 01/01/2024',
                        ),
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a data';
                          }

                          RegExp dateFormat = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                          if (!dateFormat.hasMatch(value)) {
                            return 'Use o formato: xx/yy/zzzz';
                          }

                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _salvarAbastecimento,
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'Registrar Abastecimento',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}