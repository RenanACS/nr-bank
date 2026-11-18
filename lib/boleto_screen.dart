import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';
import 'sessao.dart';

class BoletoScreen extends StatefulWidget {
  final double saldo;
  const BoletoScreen({super.key, required this.saldo});

  @override
  State<BoletoScreen> createState() => _BoletoScreenState();
}

class _BoletoScreenState extends State<BoletoScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _codigoCtrl     = TextEditingController();
  final _descricaoCtrl  = TextEditingController();
  final _valorCtrl      = TextEditingController();

  bool _processando  = false;
  bool _saldoVisivel = true;
  double? _valorBoleto;

  final _picker = ImagePicker();

  static const Color azul        = Color(0xFF2563EB);
  static const Color verde       = Color(0xFF22C55E);
  static const Color vermelho    = Color(0xFFEF4444);
  static const Color textoSecond = Color(0xFF94A3B8);

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _escanearBoleto() async {
    _mostrarOpcoesScan(
      titulo: 'Escanear boleto',
      onCamera: () async {
        final foto = await _picker.pickImage(
            source: ImageSource.camera, imageQuality: 90);
        if (foto != null && mounted) _preencherCodigoSimulado();
      },
      onGaleria: () async {
        final foto = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 90);
        if (foto != null && mounted) _preencherCodigoSimulado();
      },
    );
  }

  void _preencherCodigoSimulado() {
    setState(() {
      _codigoCtrl.text =
          '34191.09008 61207.727157 23403.700000 4 00000000015000';
      _valorBoleto = 150.00;
      _valorCtrl.text = '150.00';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código de barras lido com sucesso!'),
        backgroundColor: verde,
      ),
    );
  }

  void _mostrarOpcoesScan({
    required String titulo,
    required VoidCallback onCamera,
    required VoidCallback onGaleria,
  }) {
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
            Text(titulo,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: azul),
              title: const Text('Usar câmera'),
              onTap: () {
                Navigator.pop(ctx);
                onCamera();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: azul),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(ctx);
                onGaleria();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarPagamento() async {
    if (!_formKey.currentState!.validate()) return;
    final valor = _valorBoleto ?? 0;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar pagamento?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaResumo('Código', _codigoCtrl.text),
            const SizedBox(height: 8),
            _linhaResumo('Valor', 'R\$ ${valor.toStringAsFixed(2)}'),
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

    // ── Registra a transação no banco e atualiza o saldo ──────────────────
    if (Sessao.instance.contaId != 0) {
      await DatabaseHelper.instance.registrarTransacao(
        contaId:     Sessao.instance.contaId,
        tipo:        'boleto',
        valor:       valor,
        direcao:     'saida',
        descricao:   _descricaoCtrl.text.isNotEmpty
            ? _descricaoCtrl.text
            : null,
        destinatario: _codigoCtrl.text,
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
              child: Text('Boleto pago!',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaResumo('Código', _codigoCtrl.text),
            const SizedBox(height: 8),
            _linhaResumo('Valor', 'R\$ ${valor.toStringAsFixed(2)}'),
            if (_descricaoCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _linhaResumo('Descrição', _descricaoCtrl.text),
            ],
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => _compartilharComprovante(valor),
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

  void _compartilharComprovante(double valor) {
    final agora = DateTime.now();
    final data =
        '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year} '
        '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

    final texto = 'Comprovante de Boleto - NR BanK\n'
        'Código: ${_codigoCtrl.text}\n'
        'Valor: R\$ ${valor.toStringAsFixed(2)}\n'
        '${_descricaoCtrl.text.isNotEmpty ? 'Descrição: ${_descricaoCtrl.text}\n' : ''}'
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
        title: const Text('Pagar Boleto',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20)),
        leading: const BackButton(color: Colors.white),
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
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
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

              // Botão escanear
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _escanearBoleto,
                  icon: const Icon(Icons.qr_code_scanner,
                      color: azul),
                  label: const Text('Escanear código de barras',
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
                    child: Text('ou digite o código',
                        style: TextStyle(
                            color: textoSecond, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),

              const SizedBox(height: 20),

              _labelCampo('CÓDIGO DE BARRAS'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codigoCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9 .]')),
                ],
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o código do boleto'
                    : null,
                decoration: InputDecoration(
                  hintText:
                      '00000.00000 00000.000000 00000.000000 0 00000000000000',
                  hintStyle: const TextStyle(
                      color: textoSecond, fontSize: 12),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.barcode_reader,
                        color: textoSecond, size: 20),
                  ),
                  filled: true,
                  fillColor: bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: azul, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: vermelho),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: vermelho, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _labelCampo('VALOR (R\$)'),
              const SizedBox(height: 8),
              _buildInput(
                bgCard: bgCard,
                controller: _valorCtrl,
                hint: '0,00',
                icone: Icons.attach_money,
                tipoTeclado: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Informe o valor';
                  final val =
                      double.tryParse(v.replaceAll(',', '.')) ?? 0;
                  if (val <= 0)
                    return 'Valor deve ser maior que zero';
                  if (val > widget.saldo) return 'Saldo insuficiente';
                  _valorBoleto = val;
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _labelCampo('DESCRIÇÃO (opcional)'),
              const SizedBox(height: 8),
              _buildInput(
                bgCard: bgCard,
                controller: _descricaoCtrl,
                hint: 'Ex: Conta de luz, internet...',
                icone: Icons.notes,
                maxLength: 80,
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _processando ? null : _confirmarPagamento,
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
                      : const Text('Pagar boleto',
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
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    TextInputType? tipoTeclado,
    List<TextInputFormatter>? formatadores,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipoTeclado,
      inputFormatters: formatadores,
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
