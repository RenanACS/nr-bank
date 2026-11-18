# NR BanK

Protótipo de aplicativo de banco digital feito em **Flutter**, com dados salvos localmente em **SQLite**.

> ⚠️ **Projeto de estudo.** O NR BanK não é um banco real: não movimenta dinheiro, não se conecta a nenhuma instituição financeira e **não deve ser usado em produção**. Veja [Limitações conhecidas](#limitações-conhecidas).

## Funcionalidades

| Tela | O que faz |
|------|-----------|
| **Login** | Entrada por CPF ou e-mail e senha, com opção de biometria (`local_auth`) |
| **Cadastro** | Cria o usuário, a conta e os cartões iniciais |
| **Início** | Saldo e histórico de movimentações |
| **PIX** | Fluxo de pagamento via PIX |
| **Transferência** | Fluxo de TED/transferência bancária |
| **Boleto** | Fluxo de pagamento de boleto |
| **Cartões** | Lista de cartões e bloqueio/desbloqueio |
| **Cotação** | Cotação de dólar, euro, libra e bitcoin em reais, consultada em API pública |
| **Configurações** | Tema, notificações e logout |

## Tecnologias

- [Flutter](https://flutter.dev) (Dart SDK `^3.0.0`)
- [`sqflite`](https://pub.dev/packages/sqflite) e `path`: banco SQLite local
- [`local_auth`](https://pub.dev/packages/local_auth): autenticação biométrica
- [`http`](https://pub.dev/packages/http): consulta de cotações na [AwesomeAPI](https://docs.awesomeapi.com.br/api-de-moedas)
- `image_picker`, `share_plus` e `shared_preferences`

## Banco de dados

O banco `nr_bank.db` é criado na primeira execução por `lib/database_helper.dart` (padrão singleton) e tem quatro tabelas:

| Tabela | Colunas principais |
|--------|--------------------|
| `usuarios` | `id`, `nome`, `cpf` (único), `email` (único), `senha`, `foto_path`, `criado_em` |
| `conta` | `id`, `usuario_id`, `numero_conta` (único), `saldo` |
| `transacoes` | `id`, `conta_id`, `tipo`, `descricao`, `valor`, `direcao`, `destinatario`, `data_hora` |
| `cartoes` | `id`, `usuario_id`, `nome`, `numero`, `validade`, `limite`, `fatura`, `bloqueado`, `cor_hex` |

O arquivo [`RELATORIO_SQLITE.txt`](RELATORIO_SQLITE.txt) documenta a análise que levou a esse modelo e os passos de integração com as telas.

## Como executar

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado (`flutter doctor` sem erros para a plataforma escolhida).

```bash
git clone https://github.com/RenanACS/nr-bank.git
cd nr-bank
flutter pub get
flutter run
```

Para escolher a plataforma, use `flutter run -d <dispositivo>` (veja `flutter devices`). O projeto tem os diretórios de Android, iOS, Web, Windows, Linux e macOS, mas a biometria e o SQLite funcionam melhor em Android e iOS.

## Estrutura

```
lib/
├── main.dart                  # Entrada do app e tela de login
├── cadastro_screen.dart       # Cadastro de usuário
├── home_screen.dart           # Saldo e movimentações
├── pix_screen.dart            # PIX
├── transferencia_screen.dart  # Transferência / TED
├── boleto_screen.dart         # Pagamento de boleto
├── cartoes_screen.dart        # Cartões
├── cotacao_screen.dart        # Cotação de moedas
├── configuracoes_screen.dart  # Configurações
├── database_helper.dart       # Acesso ao SQLite
└── sessao.dart                # Sessão do usuário logado
assets/                        # Logo
test/                          # Teste de widget
```

## Limitações conhecidas

- **Senhas são salvas em texto puro** na tabela `usuarios`. Antes de qualquer uso além de estudo, é preciso aplicar hash com salt (por exemplo bcrypt ou Argon2).
- Os dados ficam só no aparelho: não há servidor, sincronização nem backup.
- Não há validação real de CPF, chave PIX ou código de barras, e nenhuma integração com o sistema financeiro.
- A cobertura de testes é mínima (apenas o `widget_test.dart` padrão).

## Licença

Ainda não definida. Sem licença, o código fica com todos os direitos reservados ao autor, mesmo estando público.
