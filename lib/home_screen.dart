import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';
import 'sessao.dart';
import 'cartoes_screen.dart';
import 'configuracoes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _fotoPerfil;
  final _picker = ImagePicker();
  bool _saldoVisivel  = true;
  int  _abaSelecionada = 0;

  // Dados vindos do banco
  double _saldo = 0.0;
  List<Map<String, dynamic>> _transacoes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // ── Carrega saldo e transações do banco ────────────────────────────────────
  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final conta = await DatabaseHelper.instance
          .buscarConta(Sessao.instance.usuarioId);
      final novoSaldo =
          ((conta?['saldo'] as num?) ?? 0).toDouble();
      Sessao.instance.saldo = novoSaldo;

      final transacoes = await DatabaseHelper.instance
          .listarTransacoes(Sessao.instance.contaId, limite: 20);

      if (mounted) {
        setState(() {
          _saldo     = novoSaldo;
          _transacoes = transacoes;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ── Formata double como moeda BRL ──────────────────────────────────────────
  String _moeda(double valor) {
    final parts = valor.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  // ── Formata datetime do SQLite para exibição ───────────────────────────────
  String _formatarData(String dataHora) {
    try {
      final dt   = DateTime.parse(dataHora.replaceAll(' ', 'T'));
      final hoje = DateTime.now();
      final hora =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (dt.year == hoje.year &&
          dt.month == hoje.month &&
          dt.day == hoje.day) {
        return 'Hoje • $hora';
      }
      final ontem = hoje.subtract(const Duration(days: 1));
      if (dt.year == ontem.year &&
          dt.month == ontem.month &&
          dt.day == ontem.day) {
        return 'Ontem • $hora';
      }
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} • $hora';
    } catch (_) {
      return dataHora;
    }
  }

  String _tituloTransacao(Map<String, dynamic> t) {
    final tipo    = t['tipo']    as String;
    final direcao = t['direcao'] as String;
    if (tipo == 'pix')          return direcao == 'entrada' ? 'PIX recebido'            : 'PIX enviado';
    if (tipo == 'transferencia') return direcao == 'entrada' ? 'Transferência recebida' : 'Transferência enviada';
    if (tipo == 'boleto')       return 'Pagamento boleto';
    return tipo;
  }

  IconData _iconeTransacao(Map<String, dynamic> t) {
    final tipo    = t['tipo']    as String;
    final direcao = t['direcao'] as String;
    if (tipo == 'pix')           return direcao == 'entrada' ? Icons.arrow_downward : Icons.pix;
    if (tipo == 'transferencia') return Icons.swap_horiz;
    if (tipo == 'boleto')        return Icons.arrow_upward;
    return Icons.attach_money;
  }

  // ── Foto de perfil ─────────────────────────────────────────────────────────
  Future<void> _selecionarFoto(ImageSource source) async {
    final foto = await _picker.pickImage(source: source, imageQuality: 80);
    if (foto != null) setState(() => _fotoPerfil = foto);
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Foto de perfil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(ctx);
                _selecionarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: Color(0xFF2563EB)),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _selecionarFoto(ImageSource.gallery);
              },
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Color(0xFFEF4444)),
              title: const Text(
                'Sair da conta',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmarLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'NR BanK',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _mostrarOpcoesFoto,
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                backgroundImage: _fotoPerfil != null
                    ? FileImage(File(_fotoPerfil!.path))
                    : null,
                child: _fotoPerfil == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Saudação com nome real
              Text(
                'Olá, ${Sessao.instance.nomeUsuario.split(' ').first}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bem-vindo(a) ao NR BanK',
                style:
                    TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Card de saldo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saldo disponível',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () => setState(
                              () => _saldoVisivel = !_saldoVisivel),
                          child: Icon(
                            _saldoVisivel
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Saldo real do banco
                    _carregando
                        ? const SizedBox(
                            height: 34,
                            width: 34,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _saldoVisivel ? _moeda(_saldo) : '••••••••',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _actionButton(
                            context, Icons.pix, 'Pix', '/pix'),
                        _actionButton(context, Icons.view_week,
                            'Boleto', '/boleto'),
                        _actionButton(context, Icons.send,
                            'Transferir', '/transferencia'),
                        _actionButton(context, Icons.currency_exchange,
                            'Cotação', '/cotacao'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // Título movimentações
              Text(
                'Últimas movimentações',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Lista de transações reais
              if (_carregando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_transacoes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nenhuma movimentação ainda',
                      style: TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 15),
                    ),
                  ),
                )
              else
                ...(_transacoes.map((t) {
                  final direcao = t['direcao'] as String;
                  final valor   = (t['valor'] as num).toDouble();
                  final cor     = direcao == 'entrada'
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444);
                  final prefixo = direcao == 'entrada' ? '+' : '-';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _transactionCard(
                      context,
                      _tituloTransacao(t),
                      _formatarData(t['data_hora'] as String),
                      '$prefixo ${_moeda(valor)}',
                      _iconeTransacao(t),
                      cor,
                    ),
                  );
                })),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        currentIndex: _abaSelecionada,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CartoesScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ConfiguracoesScreen()),
            );
          } else {
            setState(() => _abaSelecionada = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.credit_card), label: 'Cartões'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Config.'),
        ],
      ),
    );
  }

  // ── Botão de ação (Pix, Boleto, Transferir, Cotação) ──────────────────────
  Widget _actionButton(
      BuildContext context, IconData icon, String text, String? rota) {
    return GestureDetector(
      onTap: rota == null
          ? null
          : () {
              if (rota == '/transferencia' ||
                  rota == '/pix' ||
                  rota == '/boleto') {
                Navigator.pushNamed(
                  context,
                  rota,
                  arguments: _saldo, // saldo real da sessão
                ).then((_) => _carregarDados()); // recarrega ao voltar
              } else {
                Navigator.pushNamed(context, rota);
              }
            },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card de transação ──────────────────────────────────────────────────────
  Widget _transactionCard(
    BuildContext context,
    String title,
    String date,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  date,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
