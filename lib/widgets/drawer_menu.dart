import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_abastecimento_michel/telaPrincipal.dart';
import 'package:projeto_abastecimento_michel/login.dart';
import 'package:projeto_abastecimento_michel/widgets/perfil_usuario.dart';
import 'package:projeto_abastecimento_michel/widgets/tela_meus_veiculos.dart';
import 'adicionar_veiculo_page.dart';
import 'historico_abastecimento_page.dart';

class DrawerMenu extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DrawerMenu({Key? key}) : super(key: key);

  Future<String?> _getNomeUsuario() async {
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('usuarios').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['nomeCompleto'] as String?;
      }
    } catch (e) {
      print('Erro ao buscar nome do usuário: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          FutureBuilder<String?>(
            future: _getNomeUsuario(),
            builder: (context, snapshot) {
              return UserAccountsDrawerHeader(
                accountName: Text(
                  snapshot.data ?? user?.displayName ?? 'Usuário',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: user?.photoURL != null
                      ? ClipOval(
                    child: Image.network(
                      user!.photoURL!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person, size: 40, color: Colors.blue);
                      },
                    ),
                  )
                      : Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
              );
            },
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyApp(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.directions_car,
                  title: 'Meus Veículos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TelaMeusVeiculos(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.add_circle,
                  title: 'Adicionar Veículo',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdicionarVeiculoPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'Histórico de Abastecimentos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoricoAbastecimentosPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'Perfil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PerfilUsuarioPage(),
                      ),
                    ).then((_) {
                      // Força a reconstrução do Drawer para atualizar o nome do usuário
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DrawerMenu(),
                          ),
                        );
                      }
                    });
                  },
                ),
                Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.exit_to_app,
                  title: 'Logout',
                  onTap: () => _confirmarLogout(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Versão 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Logout'),
          content: Text('Tem certeza que deseja sair do aplicativo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fecha o diálogo
                _logout(context);
              },
              child: Text(
                'Sair',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}