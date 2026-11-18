import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'sessao.dart';

class CartoesScreen extends StatefulWidget {
  const CartoesScreen({super.key});

  @override
  State<CartoesScreen> createState() => _CartoesScreenState();
}

class _CartoesScreenState extends State<CartoesScreen> {
  List<Map<String, dynamic>> _cartoes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarCartoes();
  }

  // ── Converte cor hex do banco para Color do Flutter ────────────────────────
  Color _hexParaCor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  // ── Carrega cartões do banco ───────────────────────────────────────────────
  Future<void> _carregarCartoes() async {
    setState(() => _carregando = true);
    try {
      final lista = await DatabaseHelper.instance
          .listarCartoes(Sessao.instance.usuarioId);

      // Converte os campos do banco para tipos Dart
      final convertido = lista.map((c) {
        final m = Map<String, dynamic>.from(c);
        m['bloqueado'] = c['bloqueado'] == 1;
        m['cor']       = _hexParaCor(c['cor_hex'] as String);
        return m;
      }).toList();

      if (mounted) setState(() { _cartoes = convertido; _carregando = false; });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ── Alterna bloqueio e persiste no banco ───────────────────────────────────
  Future<void> _toggleBloqueio(int index) async {
    final cartao      = _cartoes[index];
    final novoBloqueio = !(cartao['bloqueado'] as bool);

    await DatabaseHelper.instance.toggleBloqueioCartao(
      cartao['id'] as int,
      novoBloqueio,
    );

    setState(() {
      _cartoes[index] = Map<String, dynamic>.from(cartao)
        ..['bloqueado'] = novoBloqueio;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Cartões'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _cartoes.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum cartão encontrado',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _cartoes.length,
                  itemBuilder: (context, index) {
                    final cartao = _cartoes[index];
                    final bloqueado = cartao['bloqueado'] as bool;
                    final cor       = cartao['cor'] as Color;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          // Visual do cartão
                          Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              color: bloqueado ? Colors.grey : cor,
                              borderRadius:
                                  BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cartao['nome'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (bloqueado)
                                      const Icon(Icons.lock,
                                          color: Colors.white),
                                  ],
                                ),
                                Text(
                                  cartao['numero'] as String,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Validade: ${cartao['validade']}',
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                    const Text(
                                      'VISA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Limite e fatura
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .cardColor,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Limite',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'R\$ ${(cartao['limite'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .cardColor,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Fatura atual',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'R\$ ${(cartao['fatura'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Botão bloquear / desbloquear
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _toggleBloqueio(index),
                              icon: Icon(
                                bloqueado
                                    ? Icons.lock_open
                                    : Icons.lock,
                                color: bloqueado
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              label: Text(
                                bloqueado
                                    ? 'Desbloquear cartão'
                                    : 'Bloquear cartão',
                                style: TextStyle(
                                  color: bloqueado
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                side: BorderSide(
                                  color: bloqueado
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
