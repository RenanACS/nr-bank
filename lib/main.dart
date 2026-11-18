import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'database_helper.dart';
import 'sessao.dart';
import 'home_screen.dart';
import 'transferencia_screen.dart';
import 'pix_screen.dart';
import 'boleto_screen.dart';
import 'cotacao_screen.dart';
import 'cadastro_screen.dart';
import 'cartoes_screen.dart';
import 'configuracoes_screen.dart';

// Controle global do tema
final ValueNotifier<ThemeMode> temaApp = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaApp,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,

          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xFF2563EB),
            scaffoldBackgroundColor: const Color(0xFFFDFDFD),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            cardColor: Colors.white,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFF2563EB),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Colors.white,
            ),
            cardColor: const Color(0xFF1E293B),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          initialRoute: '/login',
          routes: {
            '/cadastro':      (context) => const CadastroScreen(),
            '/login':         (context) => const LoginScreen(),
            '/home':          (context) => const HomeScreen(),
            '/cotacao':       (context) => const CotacaoScreen(),
            '/cartoes':       (context) => const CartoesScreen(),
            '/configuracoes': (context) => const ConfiguracoesScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/transferencia') {
              final saldo = settings.arguments as double;
              return MaterialPageRoute(
                builder: (context) => TransferenciaScreen(saldo: saldo),
              );
            }
            if (settings.name == '/pix') {
              final saldo = settings.arguments as double;
              return MaterialPageRoute(
                builder: (context) => PixScreen(saldo: saldo),
              );
            }
            if (settings.name == '/boleto') {
              final saldo = settings.arguments as double;
              return MaterialPageRoute(
                builder: (context) => BoletoScreen(saldo: saldo),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

// ─── Login Screen ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication _auth        = LocalAuthentication();
  final _loginCtrl                       = TextEditingController();
  final _senhaCtrl                       = TextEditingController();
  bool    _carregando                    = false;
  String? _erro;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  // ── Login com CPF / e-mail + senha ──────────────────────────────────────────
  Future<void> _realizarLogin() async {
    final login = _loginCtrl.text.trim();
    final senha = _senhaCtrl.text;

    if (login.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos');
      return;
    }

    setState(() { _carregando = true; _erro = null; });

    try {
      final usuario = await DatabaseHelper.instance.buscarUsuarioPorLogin(login);

      if (usuario == null || usuario['senha'] != senha) {
        setState(() {
          _erro = 'CPF/e-mail ou senha incorretos';
          _carregando = false;
        });
        return;
      }

      final conta = await DatabaseHelper.instance.buscarConta(usuario['id'] as int);

      // Preenche a sessão
      Sessao.instance.usuarioId   = usuario['id']   as int;
      Sessao.instance.nomeUsuario = usuario['nome']  as String;
      Sessao.instance.contaId     = (conta?['id']    as int?)    ?? 0;
      Sessao.instance.saldo       = ((conta?['saldo'] as num?))?.toDouble() ?? 0.0;

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _erro = 'Erro ao fazer login. Tente novamente.';
        _carregando = false;
      });
    }
  }

  // ── Login biométrico ────────────────────────────────────────────────────────
  Future<void> _autenticarBiometria() async {
    try {
      final autenticado = await _auth.authenticate(
        localizedReason: 'Use sua digital para entrar no NR BanK',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (!autenticado || !mounted) return;

      final usuarios = await DatabaseHelper.instance.listarUsuarios();
      if (usuarios.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma conta cadastrada')),
        );
        return;
      }

      final usuario = usuarios.first;
      final conta   = await DatabaseHelper.instance.buscarConta(usuario['id'] as int);

      Sessao.instance.usuarioId   = usuario['id']   as int;
      Sessao.instance.nomeUsuario = usuario['nome']  as String;
      Sessao.instance.contaId     = (conta?['id']    as int?)    ?? 0;
      Sessao.instance.saldo       = ((conta?['saldo'] as num?))?.toDouble() ?? 0.0;

      if (!mounted) return;
      Navigator.pushNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometria não disponível neste dispositivo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('NR BanK'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.jpeg',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text(
              'Login',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Campo CPF / E-mail
            TextField(
              controller: _loginCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'CPF ou Email',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 20),

            // Campo senha
            TextField(
              controller: _senhaCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Senha',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),

            // Mensagem de erro
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(
                _erro!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
              ),
            ],

            const SizedBox(height: 30),

            // Botão entrar
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
                onPressed: _carregando ? null : _realizarLogin,
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
                        'Entrar',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão biometria
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _autenticarBiometria,
                icon: const Icon(Icons.fingerprint, color: Color(0xFF2563EB)),
                label: const Text(
                  'Entrar com digital',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    'Não tem conta?',
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
                onPressed: () => Navigator.pushNamed(context, '/cadastro'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Criar conta',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
