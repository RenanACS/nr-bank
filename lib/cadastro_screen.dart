import 'package:flutter/material.dart';
import 'database_helper.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeCtrl           = TextEditingController();
  final _cpfCtrl            = TextEditingController();
  final _emailCtrl          = TextEditingController();
  final _senhaCtrl          = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();
  final _formKey            = GlobalKey<FormState>();
  bool _senhaVisivel        = false;
  bool _confirmarSenhaVisivel = false;
  bool _carregando          = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarSenhaCtrl.dispose();
    super.dispose();
  }

  // ── Gera número de conta único baseado no timestamp ────────────────────────
  String _gerarNumeroConta() {
    final n = DateTime.now().millisecondsSinceEpoch % 999999;
    return '${n.toString().padLeft(6, '0')}-${(n % 9) + 1}';
  }

  // ── Salva usuário, conta e cartões padrão no banco ─────────────────────────
  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      // 1. Insere o usuário
      final usuarioId = await DatabaseHelper.instance.inserirUsuario(
        nome:  _nomeCtrl.text.trim(),
        cpf:   _cpfCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        senha: _senhaCtrl.text,
      );

      // 2. Cria a conta corrente com saldo inicial de boas-vindas
      await DatabaseHelper.instance.criarConta(
        usuarioId:    usuarioId,
        numeroConta:  _gerarNumeroConta(),
        saldoInicial: 1000.0, // R$ 1.000,00 de boas-vindas
      );

      // 3. Insere os dois cartões padrão
      await DatabaseHelper.instance.inserirCartao(
        usuarioId: usuarioId,
        nome:      'NR BanK Black',
        numero:    '**** **** **** 1234',
        validade:  '12/28',
        limite:    10000.0,
        fatura:    0.0,
        corHex:    '#1E293B',
      );
      await DatabaseHelper.instance.inserirCartao(
        usuarioId: usuarioId,
        nome:      'NR BanK Gold',
        numero:    '**** **** **** 5678',
        validade:  '08/27',
        limite:    5000.0,
        fatura:    0.0,
        corHex:    '#2563EB',
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;

      String msg = 'Erro ao cadastrar. Tente novamente.';
      if (e.toString().contains('UNIQUE')) {
        msg = 'CPF ou e-mail já cadastrado.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        automaticallyImplyLeading: false,
        title: const Text('NR BanK', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Criar conta',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preencha seus dados para começar',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
              ),
              const SizedBox(height: 32),

              _buildCampo(
                controller: _nomeCtrl,
                hint: 'Nome completo',
                icone: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
              ),
              const SizedBox(height: 16),

              _buildCampo(
                controller: _cpfCtrl,
                hint: 'CPF',
                icone: Icons.badge_outlined,
                teclado: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe seu CPF';
                  if (v.replaceAll(RegExp(r'\D'), '').length != 11) {
                    return 'CPF inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildCampo(
                controller: _emailCtrl,
                hint: 'E-mail',
                icone: Icons.email_outlined,
                teclado: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe seu e-mail';
                  if (!v.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildCampoSenha(
                controller: _senhaCtrl,
                hint: 'Senha',
                visivel: _senhaVisivel,
                onToggle: () =>
                    setState(() => _senhaVisivel = !_senhaVisivel),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe uma senha';
                  if (v.length < 6) return 'Mínimo de 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildCampoSenha(
                controller: _confirmarSenhaCtrl,
                hint: 'Confirmar senha',
                visivel: _confirmarSenhaVisivel,
                onToggle: () => setState(
                    () => _confirmarSenhaVisivel = !_confirmarSenhaVisivel),
                validator: (v) {
                  if (v != _senhaCtrl.text) return 'As senhas não coincidem';
                  return null;
                },
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _carregando ? null : _cadastrar,
                  child: _carregando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Cadastrar',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Já tem uma conta?',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Já tenho uma conta',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers de campo ───────────────────────────────────────────────────────

  Widget _buildCampo({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icone, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444)),
      ),
    );
  }

  Widget _buildCampoSenha({
    required TextEditingController controller,
    required String hint,
    required bool visivel,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visivel,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon:
            const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
        suffixIcon: IconButton(
          icon: Icon(
            visivel ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF94A3B8),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444)),
      ),
    );
  }
}
