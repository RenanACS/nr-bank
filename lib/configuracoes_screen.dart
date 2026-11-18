import 'package:flutter/material.dart';
import 'main.dart';
import 'sessao.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool notificacoes = true;

  bool get temaEscuro => temaApp.value == ThemeMode.dark;

  void _toggleTema(bool valor) {
    temaApp.value = valor ? ThemeMode.dark : ThemeMode.light;
    setState(() {});
  }

  void _confirmarSaida(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Sessao.instance.limpar(); // limpa a sessão
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String titulo,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(titulo,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Seção conta
          const Text('Conta',
              style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.person,
                  titulo: 'Dados pessoais',
                  iconColor: const Color(0xFF2563EB),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade em breve!')),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(
                  icon: Icons.lock,
                  titulo: 'Alterar senha',
                  iconColor: const Color(0xFF2563EB),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade em breve!')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção preferências
          const Text('Preferências',
              style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.notifications,
                  titulo: 'Notificações',
                  iconColor: const Color(0xFF2563EB),
                  trailing: Switch(
                    value: notificacoes,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) => setState(() => notificacoes = val),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildTile(
                  icon: Icons.dark_mode,
                  titulo: 'Tema escuro',
                  iconColor: const Color(0xFF2563EB),
                  trailing: Switch(
                    value: temaEscuro,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: _toggleTema,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção sair
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildTile(
              icon: Icons.exit_to_app,
              titulo: 'Sair da conta',
              iconColor: Colors.red,
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () => _confirmarSaida(context),
            ),
          ),
        ],
      ),
    );
  }
}