# Favo de Colorir

App para o ateliê de cerâmica Favo de Colorir (Tijuca, RJ). Centraliza gestão de agenda, registro de materiais, cobrança automática, feed pessoal e comunidade para ~80 alunas ativas.

## Stack

| Camada | Tecnologia |
|--------|------------|
| App (Android + iOS + Web) | Flutter (Dart) |
| Backend/BaaS | Supabase (PostgreSQL, Auth, Storage, Realtime, Edge Functions) |
| Notificações push | Firebase Cloud Messaging |
| Pagamento Pix | Mercado Pago API |
| Pagamento cartão | Nuvemshop |
| Landing page | Astro + Vercel |

## Estrutura

```
favo_de_colorir/
├── app/                  ← Flutter (Android + iOS + Web)
│   ├── lib/
│   │   ├── core/         ← Tema, constantes, router, Supabase client
│   │   ├── models/       ← Models Dart (Profile, Turma, Aula, etc.)
│   │   ├── services/     ← Acesso Supabase
│   │   └── modules/      ← Telas por módulo
│   │       ├── auth/
│   │       ├── agenda/
│   │       ├── materiais/
│   │       ├── cobranca/
│   │       └── feed_pessoal/
│   └── test/
├── supabase/             ← Backend
│   ├── migrations/       ← Schema SQL versionado
│   ├── functions/        ← Edge Functions (Deno/TS)
│   ├── seed.sql          ← Dados iniciais
│   └── config.toml
├── landing/              ← Landing page (Astro)
├── docs/                 ← PRD e documentação
└── .github/workflows/    ← CI/CD
```

## Módulos

| Módulo | Descrição | Fase |
|--------|-----------|------|
| M1 — Auth | Login, cadastro, aceite de políticas, papéis | MVP |
| M2 — Agenda | Turmas, confirmação presença, reposição, lista espera | MVP |
| M3 — Materiais | Registro argila/queimas, totalização por aluna | MVP |
| M4 — Cobrança | Painel financeiro, Pix/cartão, exportação | MVP |
| M5 — Feed pessoal | Timeline, fotos, notas da aluna | MVP |
| M6 — Comunidade | Feed social, chat, moderação | Fase 2 |
| M7 — Estoque | Controle de argilas, alertas | Fase 3 |

## Setup local

### Pré-requisitos

- Flutter SDK 3.x
- Supabase CLI
- Docker (para Supabase local)

### Passos

```bash
# 1. Clonar o repositório
git clone <repo-url>
cd favo_de_colorir

# 2. Subir Supabase local
supabase start

# 3. Configurar variáveis de ambiente
cp app/.env.example app/.env
# Editar app/.env com URL e chave do Supabase local

# 4. Instalar dependências e rodar
cd app
flutter pub get
flutter run
```

### Comandos úteis

```bash
# Análise estática
cd app && flutter analyze

# Testes
cd app && flutter test

# Reset do banco (aplica migrations + seed)
supabase db reset

# Deploy edge functions
supabase functions deploy

# Build release Android
cd app && flutter build appbundle --release
```

## Equipe

| Pessoa | Foco |
|--------|------|
| Marcus | Arquitetura, Supabase, Edge Functions, integrações |
| Leonardo | Flutter — Agenda, Materiais, Feed |
| Luiz | Flutter — Auth, Comunidade, Landing |

## Licença

Proprietário — Favo de Colorir / BaxiJen.
