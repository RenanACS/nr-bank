/// Sessão do usuário logado — dados mantidos em memória durante o uso do app.
/// Preenchida no login e limpa no logout.
class Sessao {
  static final Sessao instance = Sessao._internal();
  Sessao._internal();

  int    usuarioId   = 0;
  int    contaId     = 0;
  String nomeUsuario = '';
  double saldo       = 0.0;

  bool get logado => usuarioId != 0;

  void limpar() {
    usuarioId   = 0;
    contaId     = 0;
    nomeUsuario = '';
    saldo       = 0.0;
  }
}
