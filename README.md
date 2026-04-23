# Favo de Colorir

App para o ateliê de cerâmica Favo de Colorir (Tijuca, RJ). Centraliza gestão de agenda, registro de materiais com fotos das peças, cobrança (Pix via Mercado Pago), feed pessoal, comunidade e chat 1-1 pra ~80 alunas ativas.

**Último build:** [Releases](https://github.com/BaxiJen/favo_de_colorir/releases) — cada push em `main` publica APK automático com tag `vX.Y.Z-build.N`.

## Stack

| Camada | Tecnologia |
|--------|------------|
| App (Android + iOS + Web) | Flutter (Dart 3.11) |
| State | Riverpod 3 + `ref.listen` |
| Navegação | go_router 17 (StatefulShellRoute + deep link) |
| Backend/BaaS | Supabase (PostgreSQL 17, Auth, Storage, Realtime, Edge Functions) |
| Fotos | `image_picker` + `cached_network_image` + `share_plus` |
| Offline | sqflite + `OfflineSyncService` pra materiais |
| Deep link | `app_links` + scheme `favo://` + auth bridge no Supabase |
| Push (preparado) | `firebase_messaging` — liga quando tiver Firebase project |
| Pagamento Pix | Mercado Pago API + webhook HMAC-SHA256 validado |
| Landing | Astro 5 + Vercel |

## Estrutura

```
favo_de_colorir/
├── app/                                ← Flutter (Android + iOS + Web)
│   ├── lib/
│   │   ├── core/                       ← Theme, router, Supabase, validators, deep link, UserAvatar
│   │   ├── models/                     ← 11 models (Profile, Turma, Aula, Presenca, PecaFoto, Feriado, AuditLog…)
│   │   ├── services/                   ← agenda, auth, billing, community, feed, material, offline_sync,
│   │   │                                  policy, profile, push, reposition, stock, audit, feriado
│   │   └── modules/
│   │       ├── auth/                   ← login, signup, policies, pending, profile, edit_profile,
│   │       │                              reset_password, public_profile, admin_approval, admin_create_user, admin_users
│   │       ├── agenda/                 ← home, my_agenda (semana+mês), aula_detail, reposition,
│   │       │                              waitlist, teacher_dashboard, admin_turmas, turma_detail
│   │       ├── materiais/              ← register_materials (com fotos)
│   │       ├── cobranca/               ← my_payments (Pix QR + comprovante), admin_billing (confirmar + CSV)
│   │       ├── feed/                   ← feed_screen pessoal
│   │       ├── comunidade/             ← community_feed, chat_list, chat_detail
│   │       ├── admin/                  ← admin_config, admin_notifications, admin_policies,
│   │       │                              audit_log, feriados
│   │       ├── onboarding/             ← onboarding_screen (tour de 6 slides no 1º acesso)
│   │       └── shell/                  ← app_shell (bottom nav)
│   └── test/                           ← 156 testes (models, widgets, policy tests)
├── supabase/
│   ├── migrations/                     ← 17 migrations aplicadas (schema, auth, RLS, feriados,
│   │                                     attendance_status, audit_logs, turma_location, onboarding, storage)
│   ├── functions/                      ← 13 edge functions (criar-aluna, enviar-recado, totalizar-cobranca,
│   │                                     exportar-cobranca, moderar-post, gerar-aulas, enviar-push,
│   │                                     enviar-credenciais, reset-senha-usuario, criar-pagamento-pix,
│   │                                     webhook-mercadopago, auth-bridge, enviar-notificacao)
│   ├── seed.sql
│   └── config.toml
├── landing/                            ← Landing Astro (marketing + /auth-callback fallback)
├── docs/                               ← PRD, assets todo, plano de implementação
├── .github/workflows/                  ← flutter-ci.yml (analyze+test+APK+release), landing-ci.yml
└── claude.md                           ← Spec técnica + histórico de sessões
```

## Módulos (estado atual)

| Módulo | Descrição | Status |
|--------|-----------|--------|
| M1 Auth | Login, cadastro, políticas, reset senha via deep link, magic link | ✅ |
| M2 Agenda | Semana+mês, presença, chamada real, reposição, waitlist, cancelar aula c/ cascata, feriados | ✅ |
| M3 Materiais | Registro argila/peças com fotos, offline sync | ✅ |
| M4 Cobrança | Painel, Pix real (MP), comprovante upload, CSV share, confirmar pagamento | ✅ |
| M5 Feed pessoal | Timeline + fotos + notas coloridas + privacidade | ✅ |
| M6 Comunidade | Feed social, moderação IA síncrona, chat 1-1 realtime com foto, perfil público | ✅ |
| M7 Estoque | Controle argilas, alertas | ✅ |
| M8 LGPD | Exclusão conta, consentimento, error handling | ✅ |
| M9 Admin | Gestão usuários paginada, audit_logs, broadcast segmentado, reset senha, feriados | ✅ |
| M10 Onboarding | Tour de 6 slides no 1º acesso + revisitar no perfil | ✅ |

## CI/CD

`flutter-ci.yml` roda a cada push/PR em `main`:

1. **analyze-and-test** — `flutter analyze`, 156 testes, build web
2. **build-android** (só em push `main`) — builda APK release, publica em **Releases** como prerelease `v1.0.0+1-build.N`

`landing-ci.yml` — `npm run test` (Vitest) + `build` Astro + Playwright smoke.

### Variáveis/secrets necessários no GitHub

- `SUPABASE_URL` — URL do projeto
- `SUPABASE_ANON_KEY` — chave pública (pode ir no APK)

### Secrets que vivem só no Supabase (edge functions)

```bash
supabase secrets set OPENAI_API_KEY=...         # moderação IA
supabase secrets set MP_ACCESS_TOKEN=...        # Mercado Pago Pix
supabase secrets set MP_WEBHOOK_SECRET=...      # HMAC do webhook MP
supabase secrets set FCM_SERVER_KEY=...         # push real (opcional, fallback é in-app)
```

## Setup local

### Pré-requisitos

- Flutter SDK 3.41.6 (pinado no CI; versões mais novas podem funcionar)
- Supabase CLI 2.75+
- Android SDK (pra APK) ou Chrome (pra web)

### Passos

```bash
git clone https://github.com/BaxiJen/favo_de_colorir.git
cd favo_de_colorir

# 1. Supabase
export SUPABASE_ACCESS_TOKEN=sbp_...   # ou `supabase login`
supabase link --project-ref SEU-PROJECT-ID
supabase db push
supabase functions deploy --all

# 2. App
cp app/.env.example app/.env
# Edite com SUPABASE_URL + SUPABASE_ANON_KEY (só isso — service_role NÃO vai no app)

cd app
flutter pub get
flutter run -d chrome                            # web dev
flutter run -d <android-device>                  # Android
flutter build apk --release                      # APK local
```

### Auth bridge / deep link

Configure no dashboard Supabase → Authentication → URL Configuration:

- **Site URL:** `https://<project-ref>.supabase.co/functions/v1/auth-bridge`
- **Redirect URLs (allowlist):**
  - `favo://auth-callback`
  - `favo://auth`
  - a própria bridge URL acima

A bridge é uma edge function que serve HTML: tenta abrir `favo://auth-callback` via `window.location` e cai em fallback ("baixe o app") em desktop.

### Storage buckets

Criados automaticamente pela migration `20260423000004_storage_policies.sql` + chamadas de API (ver `claude.md`). Resumo:

| Bucket | Público | Limite | Uso |
|---|---|---|---|
| `avatars` | ✅ | 5 MiB | Foto de perfil |
| `feed` | ✅ | 10 MiB | Feed pessoal |
| `pecas` | ✅ | 10 MiB | Fotos de peças |
| `posts` | ✅ | 10 MiB | Posts da comunidade |
| `chat` | ❌ | 10 MiB | Fotos no chat 1-1 (signed URL 7d) |
| `pagamentos` | ❌ | 5 MiB | Comprovantes (signed URL 30d, aceita PDF) |

## Comandos úteis

```bash
# App
flutter analyze                              # Alvo: 0 issues
flutter test                                 # Alvo: 156 verde
flutter test test/<arquivo>_test.dart        # Só um arquivo
flutter build apk --release                  # APK
flutter build web --release                  # Web estático
flutter build appbundle --release            # .aab pra Google Play

# Supabase
supabase migration list -p <db-password>     # estado de migrations
supabase db push                             # aplicar pendentes
supabase functions deploy <name>             # deploy 1 função
supabase secrets list --project-ref <id>     # ver secrets (só digest)

# Landing
cd landing
npm run dev        # http://localhost:4321
npm run test       # Vitest
npm run test:e2e   # Playwright (precisa chromium)
npm run build      # estático em dist/
```

## Credenciais de teste

- **Admin:** `debora@favodecolorir.com.br` / `FavoAdmin2026!`
- **Alunas:** `ana@teste.com`, `maria@teste.com`, `julia@teste.com` (`Teste123!`)
- **Supabase:** projeto `fhqklezevuqtqenbhsja` (sa-east-1)

## Segurança

- `.gitignore` cobre `*.env`, `.env.local`, `.env.staging`, `.env.production` — nada de credenciais vaza no histórico
- Edge functions sensíveis validam `Authorization` header + `role='admin'` (criar-aluna, enviar-recado, reset-senha-usuario, enviar-credenciais)
- `webhook-mercadopago` valida HMAC-SHA256 do header `x-signature` com `MP_WEBHOOK_SECRET`
- RLS habilitado em todas as 32 tabelas; policies refinadas: teacher só mexe em turmas dela; admin tudo; aluna só os próprios dados
- Storage policies path-based (`<userId>/...`) com RLS por bucket
- Nenhum `SERVICE_ROLE_KEY` no APK — o app Flutter usa apenas `ANON_KEY`

## Equipe

| Pessoa | Foco |
|--------|------|
| Marcus | Arquitetura, Supabase, Edge Functions, integrações |
| Leonardo | Flutter — Agenda, Materiais, Feed |
| Luiz | Flutter — Auth, Comunidade, Landing |

## Links

- **Repo:** github.com/BaxiJen/favo_de_colorir
- **Releases (APK):** [Releases](https://github.com/BaxiJen/favo_de_colorir/releases)
- **CI:** [Actions](https://github.com/BaxiJen/favo_de_colorir/actions)
- **Supabase dashboard:** `fhqklezevuqtqenbhsja.supabase.co`

## Licença

Proprietário — Favo de Colorir / BaxiJen.
