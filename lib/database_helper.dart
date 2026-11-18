import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nr_bank.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        nome       TEXT    NOT NULL,
        cpf        TEXT    NOT NULL UNIQUE,
        email      TEXT    NOT NULL UNIQUE,
        senha      TEXT    NOT NULL,
        foto_path  TEXT,
        criado_em  TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE conta (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id   INTEGER NOT NULL,
        numero_conta TEXT    NOT NULL UNIQUE,
        saldo        REAL    NOT NULL DEFAULT 0.0,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transacoes (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        conta_id     INTEGER NOT NULL,
        tipo         TEXT    NOT NULL,
        descricao    TEXT,
        valor        REAL    NOT NULL,
        direcao      TEXT    NOT NULL,
        destinatario TEXT,
        data_hora    TEXT    NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (conta_id) REFERENCES conta(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cartoes (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nome       TEXT    NOT NULL,
        numero     TEXT    NOT NULL,
        validade   TEXT    NOT NULL,
        limite     REAL    NOT NULL DEFAULT 0.0,
        fatura     REAL    NOT NULL DEFAULT 0.0,
        bloqueado  INTEGER NOT NULL DEFAULT 0,
        cor_hex    TEXT    NOT NULL DEFAULT '#1E293B',
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');
  }

  Future<int> inserirUsuario({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
  }) async {
    final db = await database;
    return await db.insert('usuarios', {
      'nome': nome,
      'cpf': cpf,
      'email': email,
      'senha': senha,
    });
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorLogin(String login) async {
    final db = await database;
    final resultado = await db.query(
      'usuarios',
      where: 'cpf = ? OR email = ?',
      whereArgs: [login, login],
      limit: 1,
    );
    return resultado.isNotEmpty ? resultado.first : null;
  }

  Future<List<Map<String, dynamic>>> listarUsuarios() async {
    final db = await database;
    return await db.query('usuarios');
  }

  Future<int> criarConta({
    required int usuarioId,
    required String numeroConta,
    double saldoInicial = 0.0,
  }) async {
    final db = await database;
    return await db.insert('conta', {
      'usuario_id': usuarioId,
      'numero_conta': numeroConta,
      'saldo': saldoInicial,
    });
  }

  Future<Map<String, dynamic>?> buscarConta(int usuarioId) async {
    final db = await database;
    final resultado = await db.query(
      'conta',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      limit: 1,
    );
    return resultado.isNotEmpty ? resultado.first : null;
  }

  Future<void> atualizarSaldo(int contaId, double novoSaldo) async {
    final db = await database;
    await db.update(
      'conta',
      {'saldo': novoSaldo},
      where: 'id = ?',
      whereArgs: [contaId],
    );
  }

  Future<int> registrarTransacao({
    required int contaId,
    required String tipo,
    required double valor,
    required String direcao,
    String? descricao,
    String? destinatario,
  }) async {
    final db = await database;

    final transacaoId = await db.insert('transacoes', {
      'conta_id': contaId,
      'tipo': tipo,
      'descricao': descricao,
      'valor': valor,
      'direcao': direcao,
      'destinatario': destinatario,
    });

    final conta = await db.query(
      'conta',
      where: 'id = ?',
      whereArgs: [contaId],
      limit: 1,
    );
    if (conta.isNotEmpty) {
      final saldoAtual = (conta.first['saldo'] as num).toDouble();
      final novoSaldo =
          direcao == 'entrada' ? saldoAtual + valor : saldoAtual - valor;
      await atualizarSaldo(contaId, novoSaldo);
    }

    return transacaoId;
  }

  Future<List<Map<String, dynamic>>> listarTransacoes(
    int contaId, {
    int limite = 20,
  }) async {
    final db = await database;
    return await db.query(
      'transacoes',
      where: 'conta_id = ?',
      whereArgs: [contaId],
      orderBy: 'data_hora DESC',
      limit: limite,
    );
  }

  Future<int> inserirCartao({
    required int usuarioId,
    required String nome,
    required String numero,
    required String validade,
    required double limite,
    double fatura = 0.0,
    String corHex = '#1E293B',
  }) async {
    final db = await database;
    return await db.insert('cartoes', {
      'usuario_id': usuarioId,
      'nome': nome,
      'numero': numero,
      'validade': validade,
      'limite': limite,
      'fatura': fatura,
      'bloqueado': 0,
      'cor_hex': corHex,
    });
  }

  Future<List<Map<String, dynamic>>> listarCartoes(int usuarioId) async {
    final db = await database;
    return await db.query(
      'cartoes',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );
  }

  Future<void> toggleBloqueioCartao(int cartaoId, bool bloqueado) async {
    final db = await database;
    await db.update(
      'cartoes',
      {'bloqueado': bloqueado ? 1 : 0},
      where: 'id = ?',
      whereArgs: [cartaoId],
    );
  }

  Future<void> fecharBanco() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
