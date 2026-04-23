---
name: flutter-favo
description: Trigger para qualquer trabalho em Dart/Flutter no diretório `app/` do projeto Favo de Colorir. Acionar quando — o user pede para criar/editar tela, service, model ou provider em `app/lib/**`; debugar navegação, estado ou integração Supabase do app mobile; ajustar tema, tipografia ou assets do app; escrever ou corrigir testes em `app/test/`; rodar `flutter analyze` / `flutter test` / `flutter run`; tomar decisão de arquitetura em Riverpod, go_router, Supabase client, sqflite, image_picker ou FCM. NÃO acionar para — landing Astro em `landing/` (usar frontend-design), migrations SQL em `supabase/`, edge functions Deno. Combinar com frontend-design sempre que a tarefa envolver UI visual nova.
---

# Flutter — app Favo de Colorir

App mobile-first (Android prioritário, iOS + Web secundários) do ateliê Favo de Colorir. Uma única codebase Flutter; backend é Supabase.

## Stack travada (`app/pubspec.yaml`)

| Camada | Pacote | Versão | Arquivo de referência |
|---|---|---|---|
| SDK | Dart/Flutter | `sdk: ^3.11.4` | — |
| Estado | `flutter_riverpod` + `riverpod_annotation` | 3.3.1 / 4.0.2 | providers em cada módulo |
| Navegação | `go_router` | 17.2.0 | `lib/core/router.dart` |
| Backend | `supabase_flutter` | 2.12.2 | `lib/core/supabase_client.dart` |
| Push | `firebase_messaging` | 16.1.3 | — (M1 init pending) |
| Fotos | `image_picker` + `cached_network_image` | 1.2.1 / 3.4.1 | M5 feed, M6 comunidade |
| Offline | `sqflite` + `path_provider` | 2.4.2 / 2.1.5 | `lib/services/offline_sync_service.dart` |
| i18n | `intl` | 0.20.2 | `main.dart` inicializa `pt_BR` |
| Config | `flutter_dotenv` | 6.0.0 | `.env` carregado no `main()` |
| Tipografia | `google_fonts` | 8.0.2 | `lib/core/theme.dart` |
| Lint | `flutter_lints` | 6.0.0 | `analysis_options.yaml` |

**Não adicione dependência** sem discutir primeiro — a lista é curta de propósito.

## Arquitetura — onde cada coisa mora

```
app/lib/
├── main.dart                — dotenv → Supabase → intl(pt_BR) → ProviderScope → MaterialApp.router
├── core/
│   ├── constants.dart
│   ├── error_handler.dart   — fluxo único de tratamento de erro; use em vez de try/catch ad-hoc
│   ├── router.dart          — GoRouter + `routerProvider`
│   ├── supabase_client.dart — `SupabaseConfig.initialize()` + getter global
│   └── theme.dart           — `FavoTheme.light` (Artisanal Modernism)
├── models/                  — POJO imutáveis (`final` fields, `fromJson`, `copyWith`)
│   aula · cobranca · feed_entry · peca · presenca · profile · registro_argila · turma
├── modules/                 — uma pasta por módulo do PRD (tela + widgets + providers locais)
│   admin · agenda · auth · cobranca · comunidade · estoque · feed · materiais · shell
└── services/                — camada de dados; 1 provider Riverpod por service
    agenda · auth · billing · community · feed · material · offline_sync ·
    policy · profile · reposition · stock
```

**Mapa módulo ↔ PRD:**
| M# | Módulo | Pasta |
|---|---|---|
| M1 | Auth (login, cadastro, aceite LGPD) | `modules/auth` |
| M2 | Agenda (turmas, presença, reposição) | `modules/agenda` |
| M3 | Materiais (argila, queimas) | `modules/materiais` |
| M4 | Cobrança (Pix Mercado Pago + cartão Nuvemshop) | `modules/cobranca` |
| M5 | Feed pessoal | `modules/feed` |
| M6 | Comunidade (feed social + chat + moderação IA) | `modules/comunidade` |
| M7 | Estoque | `modules/estoque` |
| — | Navegação/shell (bottom nav, rotas) | `modules/shell` |

## Regras de código (não negociáveis)

1. **Estado só via Riverpod.** Telas são `ConsumerWidget`/`ConsumerStatefulWidget`; leituras por `ref.watch(...)`/`ref.read(...)`. Nada de `StatefulWidget` + `setState` pra estado de domínio. `setState` fica apenas pra estado puramente visual efêmero da tela.
2. **Telas não tocam `Supabase.instance.client` direto.** Vão pelo service correspondente em `lib/services/`. O service expõe um `Provider` Riverpod.
3. **Models imutáveis.** `final`, `fromJson`/`toJson`, `copyWith`. Sem `dynamic` em campos.
4. **Navegação só por go_router.** Rotas centralizadas em `core/router.dart`. Proibido `Navigator.push(MaterialPageRoute(...))`.
5. **Cores/tipografia só do tema.** Pegue em `Theme.of(context).colorScheme` ou nos tokens do `FavoTheme`. Proibido hex inline. Tipografia é **Epilogue** (display) + **Manrope** (body) via `google_fonts` — jamais Inter/Roboto/Arial (regra do Design System "Artisanal Modernism", ver `claude.md` da raiz).
6. **Datas e moedas sempre via `intl` em pt_BR.** `DateFormat.yMMMd('pt_BR')`, `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`.
7. **Linguagem inclusiva em strings visíveis.** Preferir "a turma", "quem faz aula", "cada pessoa" ou "alunas e alunos". **Nunca** só "alunas" como genérico — a turma tem alunas e alunos. Vale em copy de tela, mensagens de erro, notifs.
8. **Erros** passam por `core/error_handler.dart`. Não encapsule toda chamada async em `try/catch` local.
9. **Sem `print`.** Use `debugPrint` e só durante debug. Logs estruturados ficam pro futuro.

## TDD obrigatório — red → green → commit

**Jamais implemente sem um teste falhando antes.** Fluxo:
1. Escreva o teste em `app/test/` e rode — veja ele falhar (red).
2. Implemente o mínimo pra passar.
3. Rode a suíte inteira + `flutter analyze`.
4. Commit.

**Comandos (do diretório `app/`):**
```bash
flutter pub get                          # resolve dependências (após editar pubspec)
flutter analyze                          # lint + typecheck. Alvo: 0 issues.
flutter test                             # suíte inteira
flutter test test/<arquivo>_test.dart    # arquivo único
flutter test --name "padrão"             # filtro por nome
flutter run -d <device>                  # teste manual
flutter run -d chrome                    # build web (PWA temporário)
```

**Antes de QUALQUER commit:** `flutter analyze && flutter test`. Se ambos não passarem, consertar antes de commitar (regra gravada em `feedback_commits_tests` e `feedback_tests_first` na memória).

## Testes — padrões e arquivos-referência

Testes em `app/test/`. Use como referência:
- `navigation_test.dart` — teste de rotas go_router
- `models_test.dart` — round-trip fromJson/toJson
- `admin_features_test.dart` — widgets + lógica
- `moderation_test.dart` — lógica pura (sem widget)
- `turma_enrollment_test.dart`, `reposition_test.dart`, `stock_test.dart` — services
- `photo_upload_test.dart` — upload via image_picker + Supabase Storage
- `error_handler_test.dart` — core
- `widget_test.dart` — smoke do app

**Como mockar Supabase:** faça a tela depender do service via Provider Riverpod; em teste, sobrescreva o provider com `ProviderScope(overrides: [serviceProvider.overrideWithValue(FakeService())], child: ...)`. Nunca instancie Supabase em teste unitário.

**Widget tests:** `testWidgets(...)` com `tester.pumpWidget(...)` embrulhado em `ProviderScope` e em `MaterialApp` ou `MaterialApp.router`. Pra telas com go_router, use uma rota mínima de teste em vez do router real.

**Lógica pura:** `test(...)` do `package:flutter_test/flutter_test.dart` (que reexporta `package:test`).

## Supabase — integração

- `SupabaseConfig.initialize()` em `core/supabase_client.dart` lê `SUPABASE_URL` e `SUPABASE_ANON_KEY` do `.env`.
- Schema, RLS e Edge Functions vivem em `supabase/` (outra pasta do monorepo, não Dart).
- **RLS ativa sempre** — confirme que o acesso do app respeita as policies. Se algo retorna lista vazia inesperadamente, suspeite de RLS primeiro.
- **Realtime** em `community_service.dart` (chat) e possivelmente em agenda (presença em tempo real).
- **Storage:** fotos em buckets por aluna/aluno. Respeite a convenção de path.

## Tema — "Artisanal Modernism"

`lib/core/theme.dart` define `FavoTheme.light`. Tokens (mel/terracota) são replicados em `landing/src/styles/tokens.css` — se mudar um lado, sincronize o outro (principalmente paleta e font stack).

Regras visuais (do `claude.md` raiz):
- Tipografia distintiva (Epilogue + Manrope)
- Paleta com acentos fortes, sem "roxo em branco"
- Composição espacial com asymmetry/overlap
- Motion intencional (não usar AnimatedContainer genérico sem propósito)

**Pra trabalho visual novo, combine esta skill com `frontend-design`** (obrigatória pelo claude.md raiz). A `flutter-favo` traz arquitetura + Supabase + test patterns; a `frontend-design` traz decisões de composição visual.

## Antipadrões — não fazer

- `setState` em tela grande pra estado de domínio (→ Riverpod)
- Chamar `Supabase.instance.client.from(...)` de dentro de um widget (→ service)
- `Navigator.push(MaterialPageRoute(...))` (→ `context.go(...)` via go_router)
- Hex inline (`Color(0xFF...)`) em widget (→ tokens do tema)
- `print(...)` (→ `debugPrint` só em debug, removido antes de commit)
- Adicionar pacote ao `pubspec.yaml` sem discutir
- Usar "alunas" como genérico da turma (→ neutralizar ou "alunas e alunos")
- Commit com `flutter analyze` ou `flutter test` falhando
- Implementar antes de ter um teste vermelho

## Dica de leitura rápida antes de mexer num módulo

1. Abra `lib/modules/<modulo>/` e leia a tela-raiz.
2. Abra o service correspondente em `lib/services/`.
3. Confira o model em `lib/models/`.
4. Olhe o teste existente em `app/test/<modulo>_*_test.dart` (se houver) pra entender os contratos.
5. Só depois edite.
