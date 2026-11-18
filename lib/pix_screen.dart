import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';
import 'sessao.dart';

class PixScreen extends StatefulWidget {
  final double saldo;
  const PixScreen({super.key, required this.saldo});

  @override
  State<PixScreen> createState() => _PixScreenState();
}

class _PixScreenState extends State<PixScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _chaveCtrl     = TextEditingController();
  final _valorCtrl     = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _picker        = ImagePicker();

  bool _processando  = false;
  bool _saldoVisivel = true;

  String _tipoChave = 'CPF';
  final List<String> _tiposChave = [
    'CPF',
    'CNPJ',
    'E-mail',
    'Telefone',
    'Aleatória'
  ];

  static const Color azul        = Color(0xFF2563EB);
  static const Color textoSecond = Color(0xFF94A3B8);
  static const Color verde       = Color(0xFF22C55E);
  static const Color vermelho    = Color(0xFFEF4444);

  @override
  void dispose() {
    _chaveCtrl.dispose();
    _valorCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _escanearQrCode() async {
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
                color: textoSecond,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Escanear QR Code Pix',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: azul),
              title: const Text('Usar câmera'),
              onTap: () async {
                Navigator.pop(ctx);
                final foto = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 90);
                if (foto != null && mounted) _preencherDadosQr();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: azul),
              title: const Text('Escolher da galeria'),
              onTap: () async {
                Navigator.pop(ctx);
                final foto = await _picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 90);
                if (foto != null && mounted) _preencherDadosQr();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _preencherDadosQr() {
    setState(() {
      _tipoChave = 'Aleatória';
      _chaveCtrl.text = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      _valorCtrl.text = '50.00';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code lido com sucesso!'),
        backgroundColor: verde,
      ),
    );
  }

  Future<void> _confirmarPix() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar Pix?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaResumo('Tipo de chave', _tipoChave),
            const SizedBox(height: 8),
            _linhaResumo('Chave', _chaveCtrl.text),
            const SizedBox(height: 8),
            _linhaResumo(
              'Valor',
              'R\$ ${double.parse(_valorCtrl.text.replaceAll(',', '.')).toStringAsFixed(2)}',
            ),
            if (_descricaoCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _linhaResumo('Descrição', _descricaoCtrl.text),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: textoSecond)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: azul,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _processando = true);
    await Future.delayed(const Duration(seconds: 2));

    final valor     = double.parse(_valorCtrl.text.replaceAll(',', '.'));
    final chave     = _chaveCtrl.text;
    final descricao = _descricaoCtrl.text;

    // ── Registra a transação no banco e atualiza o saldo ──────────────────
    if (Sessao.instance.contaId != 0) {
      await DatabaseHelper.instance.registrarTransacao(
        contaId:     Sessao.instance.contaId,
        tipo:        'pix',
        valor:       valor,
        direcao:     'saida',
        descricao:   descricao.isNotEmpty ? descricao : null,
        destinatario: '$_tipoChave: $chave',
      );
      Sessao.instance.saldo -= valor;
    }

    setState(() => _processando = false);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: verde, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text('Pix enviado!',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaResumo('Tipo de chave', _tipoChave),
            const SizedBox(height: 8),
            _linhaResumo('Chave', chave),
            const SizedBox(height: 8),
            _linhaResumo('Valor', 'R\$ ${valor.toStringAsFixed(2)}'),
            if (descricao.isNotEmpty) ...[
              const SizedBox(height: 8),
              _linhaResumo('Descrição', descricao),
            ],
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () =>
                _compartilharComprovante(chave, valor, descricao),
            icon: const Icon(Icons.share, color: azul),
            label: const Text('Compartilhar',
                style: TextStyle(color: azul)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: azul),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: azul,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, {'sucesso': true, 'valor': valor});
  }

  void _compartilharComprovante(
      String chave, double valor, String descricao) {
    final agora = DateTime.now();
    final data =
        '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year} '
        '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

    final texto = 'Comprovante de Pix - NR BanK\n'
        'Tipo de chave: $_tipoChave\n'
        'Chave: $chave\n'
        'Valor: R\$ ${valor.toStringAsFixed(2)}\n'
        '${descricao.isNotEmpty ? 'Descrição: $descricao\n' : ''}'
        'Data: $data';

    SharePlus.instance.share(ShareParams(text: texto));
  }

  Widget _linhaResumo(String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style:
                const TextStyle(color: textoSecond, fontSize: 14)),
        Expanded(
          child: Text(valor,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final bgCard =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pix',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20)),
        iconTheme: const IconThemeData(
            color: Color.fromRGBO(255, 255, 255, 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Card saldo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                        color: Color.fromARGB(31, 245, 243, 243),
                        blurRadius: 12,
                        offset: Offset(0, 6))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Saldo disponível',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16)),
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
                    Text(
                      _saldoVisivel
                          ? 'R\$ ${widget.saldo.toStringAsFixed(2)}'
                          : 'R\$ ••••••',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _escanearQrCode,
                  icon: const Icon(Icons.qr_code_scanner,
                      color: azul),
                  label: const Text('Escanear QR Code Pix',
                      style: TextStyle(
                          color: azul,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: azul, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ou digite a chave',
                        style: TextStyle(
                            color: textoSecond, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),

              const SizedBox(height: 20),

              _labelCampo('TIPO DE CHAVE PIX'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tipoChave,
                    isExpanded: true,
                    dropdownColor:
                        isDark ? const Color(0xFF1E293B) : Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: textoSecond),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15),
                    items: _tiposChave
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _tipoChave = v);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _labelCampo('CHAVE PIX'),
              const SizedBox(height: 8),
              _buildInput(
                bgCard: bgCard,
                isDark: isDark,
                controller: _chaveCtrl,
                hint: _tipoChave == 'E-mail'
                    ? 'exemplo@email.com'
                    : _tipoChave == 'Telefone'
                        ? '+55 (00) 00000-0000'
                        : _tipoChave == 'Aleatória'
                            ? 'Cole a chave aleatória'
                            : _tipoChave,
                icone: Icons.vpn_key_outlined,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Informe a chave Pix'
                    : null,
              ),

              const SizedBox(height: 20),

              _labelCampo('VALOR (R\$)'),
              const SizedBox(height: 8),
              _buildInput(
                bgCard: bgCard,
                isDark: isDark,
                controller: _valorCtrl,
                hint: '0,00',
                icone: Icons.attach_money,
                tipoTeclado: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Informe o valor';
                  final valor =
                      double.tryParse(v.replaceAll(',', '.')) ?? 0;
                  if (valor <= 0)
                    return 'Valor deve ser maior que zero';
                  if (valor > widget.saldo) return 'Saldo insuficiente';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _labelCampo('DESCRIÇÃO (opcional)'),
              const SizedBox(height: 8),
              _buildInput(
                bgCard: bgCard,
                isDark: isDark,
                controller: _descricaoCtrl,
                hint: 'Ex: Aluguel, jantar...',
                icone: Icons.notes,
                maxLength: 80,
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processando ? null : _confirmarPix,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azul,
                    disabledBackgroundColor: bgCard,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _processando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Enviar Pix',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: textoSecond),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(
                          color: textoSecond, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelCampo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: textoSecond,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInput({
    required Color bgCard,
    required bool isDark,
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    TextInputType? tipoTeclado,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      style:
          TextStyle(color: isDark ? Colors.white : Colors.black),
      keyboardType: tipoTeclado,
      validator: validator,
      maxLength: maxLength,
      buildCounter: maxLength != null
          ? (_, {required currentLength, required isFocused, maxLength}) =>
              Text('$currentLength/$maxLength',
                  style: const TextStyle(
                      color: textoSecond, fontSize: 11))
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textoSecond),
        prefixIcon: Icon(icone, color: textoSecond, size: 20),
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: azul, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: vermelho),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: vermelho, width: 2),
        ),
      ),
    );
  }
}
