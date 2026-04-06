# Product Requirements Document (PRD)
## Plataforma Favo de Colorir

|              |                                                 |
|--------------|-------------------------------------------------|
| **Produto:** | App Favo de Colorir                             |
| **Cliente:** | Débora — Favo de Colorir (Tijuca, RJ)           |
| **Equipe:**  | Marcus, Luis Barbedo, Leonardo Camilo — BaxiJen |
| **Versão:**  | 1.1 — Atualizado com feedback da cliente        |
| **Data:**    | Março de 2026                                   |
| **Status:**  | Para desenvolvimento                            |

|                                                                                                                                                                                                                                         |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **✅ ATUALIZADO v1.1:** Esta versão incorpora o feedback da Débora recebido após revisão da v1.0, incluindo: aceite obrigatório de políticas no cadastro, fluxo de triagem prévia pelo Instagram, e análise competitiva do app Ceramik. |

---

## Índice

*(Gerado automaticamente no Word — no Markdown, use os links dos headings)*

# 1. Visão geral do produto

## 1.1 Problema

O Favo de Colorir é um ateliê de cerâmica na Tijuca (RJ) com ~80 alunas ativas, 3 professoras e 1 assistente. Toda a gestão de turmas, cobranças, reposições e comunicação é feita manualmente via WhatsApp, bloco de notas e papel. A cobrança mensal sozinha consome 2 dias inteiros de trabalho. Vagas são perdidas por falta de controle de presença, e não existe comunidade digital entre as alunas.

## 1.2 Solução

Um aplicativo mobile-first (Android prioritário, iOS e web app como complemento) que centraliza: gestão de agenda e turmas, registro de materiais (argila e queimas), cobrança automática, feed pessoal de evolução das alunas, e comunidade exclusiva do ateliê.

## 1.3 Definição de sucesso

- 100% das alunas baixam e usam o app (Débora vai tornar obrigatório)

- Cobrança mensal reduzida de 2 dias para minutos

- Zero vagas perdidas por falta de controle de presença

- Pagamentos fluindo pela plataforma sem intervenção manual

## 1.4 Usuários-alvo

|                    |                                               |                                                 |
|--------------------|-----------------------------------------------|-------------------------------------------------|
| **Persona**        | **Descrição**                                 | **Necessidade principal**                       |
| **Débora (Admin)** | Proprietária, professora, financeiro          | Eliminar trabalho manual de cobrança e controle |
| **Professoras**    | Fê e Bia — dão aulas, registram materiais     | Registrar argila/peças de forma rápida          |
| **Assistente**     | Apoio operacional no ateliê                   | Acesso básico ao painel                         |
| **Alunas (~80)**   | Mulheres, maioria adulta, celular Android/iOS | Gerenciar aulas, ver histórico, comunidade      |

## 1.5 Plataformas e tecnologia

- **Framework:** Flutter (gera Android, iOS e web app)

- **Prioridade:** Android → iOS → Web app

- **Distribuição:** Play Store + APK direto como plano B; App Store após validação

- **Domínio:** Separado da loja (ex: atelie.favodecolorir.com.br)

- **Pagamentos:** Mercado Pago (Pix) + Nuvemshop (cartão)

- **Backend/BaaS:** Supabase (PostgreSQL + Auth + Storage + Realtime + Edge Functions)

- **Notificações push:** Firebase Cloud Messaging (FCM)

- **Landing page:** Astro (hospedada na Vercel)

# 2. Arquitetura técnica

> **✅ ATUALIZADO v1.2:** Seção nova. Define stack, estrutura de repositório, comandos CLI para setup e estratégia de deploy.

## 2.1 Stack definida

| Camada | Tecnologia | Justificativa |
|---|---|---|
| **App (Android + iOS)** | Flutter (Dart) | Codebase única gera Android, iOS e web app. Luiz já tem experiência. |
| **Backend / BaaS** | Supabase | PostgreSQL relacional (ideal para turmas, alunas, planos, cobranças). Auth, Storage, Realtime e Edge Functions inclusos. Free tier suporta 80+ alunas. |
| **Banco de dados** | PostgreSQL (via Supabase) | Relacional = perfeito para totalizações de cobrança (argilas + queimas por aluna por mês). Firestore (NoSQL) seria doloroso pra isso. |
| **Autenticação** | Supabase Auth | E-mail + senha. Row Level Security (RLS) para separar permissões (admin vê financeiro, professora não). |
| **Storage (fotos)** | Supabase Storage | Fotos das peças no feed pessoal e comunidade. Buckets separados por aluna. |
| **Realtime** | Supabase Realtime | Chat professora ↔ aluna, atualizações de presença em tempo real. |
| **Edge Functions** | Supabase Edge Functions (Deno) | Totalização mensal de cobranças, disparo de notificações, moderação de posts com IA. |
| **Notificações push** | Firebase Cloud Messaging (FCM) | Gratuito, funciona Android + iOS. Supabase dispara webhook → FCM entrega a notificação. |
| **Pagamento Pix** | Mercado Pago API (ou API Pix do banco da Débora) | QR code automático, sem taxas para Pix. |
| **Pagamento cartão** | Nuvemshop (integração existente) | Débora já usa. Parcela 2-3x sem juros para oficinas/planos. |
| **Landing page** | Astro | Estático, leve, SEO excelente. Perfeito para página de download do app. |
| **Hospedagem landing** | Vercel | Deploy automático no `git push`. Free tier suficiente. |
| **Repositório** | GitHub (monorepo) | Uma única repo para app, landing, backend e docs. |

## 2.2 Por que Supabase e não Firebase?

- **Cobranças são relacionais:** totalizar "argila usada + queimas de esmalte por aluna por mês" é um `SELECT SUM() GROUP BY` simples em PostgreSQL. Em Firestore seria um pesadelo de denormalização e cloud functions.
- **Row Level Security:** uma policy no banco resolve "professora não vê financeiro" sem lógica extra no app.
- **SQL real:** relatórios, exportações CSV/PDF e analytics do ateliê ficam triviais.
- **Preço:** free tier suporta 500MB de banco, 1GB de storage, 50k auth users. Sobra pro Favo.
- **Migração:** se um dia precisar sair do Supabase, é PostgreSQL padrão — exporta e leva pra qualquer lugar.

## 2.3 Estrutura do monorepo

```
favo-platform/
├── app/                        ← Flutter (Android + iOS + web app)
│   ├── android/                ← configs nativas Android (gerado pelo Flutter CLI)
│   ├── ios/                    ← configs nativas iOS (gerado pelo Flutter CLI)
│   ├── web/                    ← configs web app (gerado pelo Flutter CLI)
│   ├── lib/                    ← código Dart (95% do trabalho vive aqui)
│   │   ├── core/               ← tema, constantes, utils, cliente Supabase
│   │   ├── models/             ← modelos de dados (Aluna, Turma, Aula, etc.)
│   │   ├── services/           ← camada de acesso ao Supabase (repos)
│   │   ├── modules/
│   │   │   ├── auth/           ← M1: login, cadastro, aceite de políticas
│   │   │   ├── agenda/         ← M2: turmas, presença, reposição, lista espera
│   │   │   ├── materiais/      ← M3: registro argila, queimas
│   │   │   ├── cobranca/       ← M4: painel financeiro, pagamentos
│   │   │   ├── feed_pessoal/   ← M5: histórico, fotos, anotações
│   │   │   ├── comunidade/     ← M6: feed social, chat, moderação
│   │   │   └── estoque/        ← M7: controle de argilas
│   │   └── main.dart
│   ├── test/                   ← testes unitários e de widget
│   └── pubspec.yaml
│
├── landing/                    ← Astro (landing page)
│   ├── src/
│   │   ├── pages/
│   │   │   └── index.astro     ← página principal
│   │   ├── components/
│   │   └── layouts/
│   ├── public/                 ← assets (logo, screenshots do app)
│   ├── astro.config.mjs
│   └── package.json
│
├── supabase/                   ← backend (gerenciado via Supabase CLI)
│   ├── migrations/             ← schema do banco (SQL versionado)
│   ├── functions/              ← edge functions (Deno/TypeScript)
│   │   ├── totalizar-cobranca/ ← roda no 1º dia útil do mês
│   │   ├── enviar-notificacao/ ← integra com FCM
│   │   └── moderar-post/       ← filtro IA para comunidade
│   ├── seed.sql                ← dados iniciais (tipos de argila, preços queima)
│   └── config.toml
│
├── docs/                       ← documentação do projeto
│   ├── prd_v1.2.md
│   ├── requisitos.md
│   └── fluxos/
│
├── .github/
│   └── workflows/              ← CI/CD (build, test, deploy)
│
├── .gitignore
└── README.md
```

## 2.4 Setup do projeto via CLI

> **⚠️ REGRA IMPORTANTE: Toda a estrutura deve ser criada via CLI. Não criar pastas nem arquivos manualmente.** Cada ferramenta tem seu scaffolding que gera configs, manifests e boilerplate corretos. Criar na mão causa erros sutis de build, especialmente no Xcode (iOS) e Gradle (Android).

### Passo 1 — Criar o monorepo

```bash
mkdir favo-platform && cd favo-platform
git init
```

### Passo 2 — Scaffold do Flutter (gera app/ com Android + iOS + Web)

```bash
flutter create --org br.com.favodecolorir --project-name favo app
```

Isso gera automaticamente:
- `app/android/` com Gradle configs, AndroidManifest, etc.
- `app/ios/` com Xcode project, Info.plist, Podfile, etc.
- `app/web/` com index.html e configs
- `app/lib/main.dart` com o app inicial
- `app/pubspec.yaml` com dependências

### Passo 3 — Adicionar dependências Flutter

```bash
cd app
flutter pub add supabase_flutter
flutter pub add firebase_messaging
flutter pub add image_picker
flutter pub add cached_network_image
flutter pub add go_router
flutter pub add flutter_riverpod
flutter pub add intl
cd ..
```

### Passo 4 — Scaffold do Supabase

```bash
supabase init
```

Isso gera `supabase/config.toml` e a estrutura de migrations/functions.

```bash
supabase start          # sobe instância local (Docker)
supabase db reset       # aplica migrations + seed
```

### Passo 5 — Criar edge functions via CLI

```bash
supabase functions new totalizar-cobranca
supabase functions new enviar-notificacao
supabase functions new moderar-post
```

### Passo 6 — Scaffold da landing page (Astro)

```bash
npm create astro@latest landing -- --template minimal
```

### Passo 7 — Setup do Firebase (só pra FCM)

```bash
cd app
flutterfire configure --project=favo-de-colorir
cd ..
```

Isso gera os arquivos `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) automaticamente.

### Passo 8 — Configurar .gitignore

```bash
cat > .gitignore << 'EOF'
# Flutter
app/build/
app/.dart_tool/
app/.packages
app/android/.gradle/
app/ios/Pods/
app/ios/.symlinks/
app/.flutter-plugins
app/.flutter-plugins-dependencies

# Supabase
supabase/.temp/
supabase/.env

# Landing
landing/node_modules/
landing/dist/

# IDE
.idea/
.vscode/
*.iml
.DS_Store

# Env
.env
.env.local
EOF
```

### Passo 9 — Primeiro commit

```bash
git add -A
git commit -m "chore: scaffold inicial — Flutter + Supabase + Astro"
```

## 2.5 Estratégia de deploy

| Output | Comando | Destino |
|---|---|---|
| **APK (Android)** | `cd app && flutter build apk --release` | Play Store + APK direto (plano B) |
| **AAB (Android)** | `cd app && flutter build appbundle --release` | Play Store (formato preferido) |
| **IPA (iOS)** | `cd app && flutter build ipa --release` | App Store (via Xcode/Transporter) |
| **Web app** | `cd app && flutter build web --release` | Supabase Hosting ou Vercel |
| **Landing page** | `cd landing && npm run build` | Vercel (auto-deploy no git push) |
| **Edge functions** | `supabase functions deploy` | Supabase Edge |
| **Migrations** | `supabase db push` | Supabase (produção) |

## 2.6 Ambientes

| Ambiente | Supabase | App | Uso |
|---|---|---|---|
| **Local** | `supabase start` (Docker) | `flutter run` (emulador) | Desenvolvimento diário |
| **Staging** | Projeto Supabase separado (free tier) | Build de debug | Testes com grupo de alunas beta |
| **Produção** | Projeto Supabase principal | Build de release | App publicado nas stores |

## 2.7 Divisão de trabalho sugerida

| Pessoa | Foco principal | Módulos |
|---|---|---|
| **Marcus** | Arquitetura, Supabase, edge functions, integrações (Pix, FCM) | M4 (Cobrança), infra |
| **Leonardo** | Flutter — telas e lógica de negócio (já conhece o projeto) | M2 (Agenda), M3 (Materiais), M5 (Feed) |
| **Luiz** | Flutter — auth, comunidade, landing page | M1 (Auth), M6 (Comunidade), Landing |

---

# 3. Análise competitiva — Ceramik

|                                                                                                                    |
|--------------------------------------------------------------------------------------------------------------------|
| **✅ ATUALIZADO v1.1:** Seção nova na v1.1. Débora indicou o app Ceramik (ceramik.app) como referência do mercado. |

O Ceramik (ceramik.app/pt) é um app voltado para professores de cerâmica, já disponível em português BR. Atualmente na App Store (iOS) e com Google Play em breve no Brasil. Cobra R\$49,90/mês para até 55 membros. Analisamos suas funcionalidades para identificar insights e diferenças.

## 2.1 Funcionalidades do Ceramik

|                                     |                                                          |                                                                |
|-------------------------------------|----------------------------------------------------------|----------------------------------------------------------------|
| **Funcionalidade**                  | **Ceramik**                                              | **Favo de Colorir**                                            |
| **Gestão de turmas/agenda**         | Sim                                                      | Sim — com confirmação de presença automática (diferencial)     |
| **Registro de presença**            | Sim                                                      | Sim — com notificação 1 dia antes + liberação de vaga          |
| **Student journals (feed pessoal)** | Sim                                                      | Sim — com dados automáticos de argila + privado/público        |
| **Comunidade/feed social**          | Sim                                                      | Sim — com moderação por IA + chat professora-aluna             |
| **Rastreamento de queimas (kiln)**  | Sim (dimensões, peso, custo)                             | Sim — com cobrança automática por peça (diferencial)           |
| **Controle de estoque**             | Sim                                                      | Sim — com alerta de reabastecimento                            |
| **Faturamento/pagamentos**          | Sim (invoicing)                                          | Sim — Pix + cartão integrado com totalização automática        |
| **Planos de aula (mensal/fixo)**    | Sim                                                      | Sim — mensal, trimestral, semestral com regras de cancelamento |
| **Sistema de reposição**            | Mencionado como reagendamento no agendamento inteligente | Sim — diferencial forte                                        |
| **Lista de espera**                 | Sim (agendamento inteligente com listas de espera)       | Sim — com notificação automática                               |
| **Cobrança de argila por uso**      | Não identificado                                         | Sim — diferencial forte (maior dor da Débora)                  |
| **Políticas do ateliê no cadastro** | Não identificado                                         | Sim — aceite obrigatório (novo v1.1)                           |
| **Idioma**                          | Português BR e Inglês                                    | Português BR (nativo)                                          |

## 2.2 Diferenciais do Favo de Colorir

- Sistema de reposição automática com liberação de vagas em tempo real (Ceramik menciona reagendamento, mas sem o fluxo de confirmação proativa)

- Cobrança automática de argila por consumo (maior dor, não encontrada no Ceramik)

- Confirmação de presença proativa (notificação 1 dia antes)

- Moderação de comunidade com filtro de IA

- Políticas do ateliê integradas ao onboarding

- 100% em português BR, adaptado ao contexto brasileiro

## 2.3 Insights para incorporar

- **Kiln tracking detalhado:** O Ceramik registra dimensões e peso das peças. Podemos adicionar campos opcionais de dimensão/peso no registro de peças para enriquecer o histórico.

- **Quick notes:** O Ceramik tem notas rápidas com cores. Podemos incorporar isso ao feed pessoal da aluna como "anotações rápidas" com categorias.

- **Studio analytics:** O Ceramik mostra analytics por aluna (frequência, uso do plano). Já temos isso planejado no painel admin, mas podemos dar destaque visual com gráficos.

- **Modelo de preços como referência:** Ceramik cobra \$24.99/mês para 55 membros (plano Pro). Isso valida o modelo SaaS para ateliês, mas o Favo é um produto interno, não SaaS.

# 4. Arquitetura de módulos

O app é dividido em 7 módulos funcionais.

|                       |                                                             |                     |
|-----------------------|-------------------------------------------------------------|---------------------|
| **Módulo**            | **Descrição**                                               | **Usuários**        |
| **M1 — Autenticação** | Login, cadastro, perfis, permissões, aceite de políticas    | Todos               |
| **M2 — Agenda**       | Turmas, confirmação de presença, reposição, lista de espera | Todos               |
| **M3 — Materiais**    | Registro de argila, queimas, totalização por aluna          | Professoras + Admin |
| **M4 — Cobrança**     | Painel financeiro, cobranças, Pix/cartão                    | Admin (Débora)      |
| **M5 — Feed pessoal** | Histórico individual, fotos, anotações                      | Alunas              |
| **M6 — Comunidade**   | Feed social, posts, moderação, chat                         | Todos               |
| **M7 — Estoque**      | Controle de argilas, alertas                                | Admin + Professoras |

# 5. M1 — Autenticação e perfis

## 5.1 Tipos de usuário e permissões

|                    |                                                                    |                |
|--------------------|--------------------------------------------------------------------|----------------|
| **Papel**          | **Acesso**                                                         | **Prioridade** |
| **Admin (Débora)** | Tudo: agenda, materiais, financeiro, comunidade, estoque, usuários | **Alta**       |
| **Professora**     | Agenda, materiais, comunidade, mensagens, estoque. Sem financeiro. | **Alta**       |
| **Assistente**     | Agenda (visualização), materiais                                   | **Média**      |
| **Aluna**          | Agenda pessoal, feed pessoal, comunidade, histórico, pagamentos    | **Alta**       |

## 5.2 Fluxo de cadastro

|                                                                                                                             |
|-----------------------------------------------------------------------------------------------------------------------------|
| **✅ ATUALIZADO v1.1:** Atualizado com feedback da Débora: triagem prévia pelo Instagram + aceite obrigatório de políticas. |

### Etapa 1 — Triagem prévia (fora do app)

Antes de direcionar ao app, **Débora faz a triagem pelo Instagram/WhatsApp**: verifica a disponibilidade de turmas e confirma com a interessada que há vaga no horário desejado. Somente após essa confirmação, Débora envia o link do app.

> *Motivo (feedback da Débora): "Ela baixar o app pra depois descobrir que não tem vaga não acho muito bom." A experiência de primeiro contato deve ser positiva.*

### Etapa 2 — Cadastro no app

1.  Aluna recebe link de convite e baixa o app

2.  Preenche dados: nome completo, e-mail, telefone, data de nascimento

3.  Campos opcionais: foto de perfil, experiência com cerâmica

### Etapa 3 — Aceite obrigatório de políticas do ateliê

|                                                                                                                                                                                                    |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **✅ ATUALIZADO v1.1:** Novo requisito (feedback da Débora): "Na hora do cadastro, acho importante deixar bem claro as políticas do ateliê. A aluna tem que concordar pra conseguir se cadastrar." |

Antes de finalizar o cadastro, a aluna deve ler e aceitar as políticas do ateliê. **O cadastro só é concluído após o aceite.**

Políticas que devem ser apresentadas:

- Regras de reposição (máx 1/mês, aviso com 1 dia, não remarca se faltar)

- Política de faltas (confirmação de presença obrigatória)

- Cobrança de argilas e queimas de esmalte (por consumo, no final do mês)

- Política de cancelamento por plano (mensal: 10-15 dias; trimestral/semestral: multa 20%)

- Regras de uso da comunidade (respeito, moderação, sem conteúdo político)

### Implementação técnica

- Tela dedicada com scroll das políticas + checkbox "Li e concordo"

- Botão de cadastro só ativa após marcar o checkbox

- Registro de data/hora do aceite no banco de dados (conformidade legal)

- Admin pode editar o texto das políticas a qualquer momento

- Se as políticas forem atualizadas, alunas existentes devem aceitar novamente no próximo login

### Etapa 4 — Aprovação

4.  Admin aprova o cadastro e vincula a aluna à turma pré-combinada

5.  Aluna recebe notificação de boas-vindas com detalhes da turma

> *Migração: importar dados existentes do Google Forms para o banco de dados do app.*

## 5.3 User stories

- Como admin, quero que novas alunas aceitem as políticas do ateliê antes de completar o cadastro.

- Como admin, quero filtrar a disponibilidade antes de enviar o link do app para não frustrar a aluna.

- Como admin, quero editar as políticas do ateliê e forçar re-aceite das alunas existentes.

- Como aluna, quero entender as regras do ateliê de forma clara antes de me matricular.

- Como admin, quero convidar novas alunas por link para que elas se cadastrem sozinhas.

- Como admin, quero aprovar cadastros para manter controle de quem acessa o app.

# 6. M2 — Agenda e agendamentos

## 6.1 Estrutura de turmas

|                    |                                                           |
|--------------------|-----------------------------------------------------------|
| **Atributo**       | **Detalhe**                                               |
| **Modalidades**    | Aula regular (semanal, 2h), Oficina/Workshop, Aula avulsa |
| **Capacidade**     | Regular: 8. Oficina: 10. Ateliê comporta 10.              |
| **Horários**       | Fixos semanais (seg-sáb). Ver grade no doc de requisitos. |
| **Níveis**         | Sem progressão. Iniciantes e avançadas juntas.            |
| **Pré-requisitos** | Nenhum.                                                   |

## 6.2 Confirmação de presença

**Regra crítica:** 1 dia antes de cada aula, notificação push: "Vou" ou "Não vou".

|                       |                                                           |
|-----------------------|-----------------------------------------------------------|
| **Cenário**           | **Comportamento**                                         |
| **Confirma "Vou"**    | Presença pré-registrada. Aparece como confirmada.         |
| **Informa "Não vou"** | Vaga liberada para reposição. Falta registrada.           |
| **Não responde**      | Lembrete 6h antes. Se não responder, conta como esperada. |

## 6.3 Sistema de reposição

### Regras de negócio

- Máx 1 reposição/mês (admin pode liberar extras)

- Reposição não reagenda: faltou, perdeu

- Aviso com 1 dia de antecedência

- Agendamento automático se houver vaga

### Fluxo

6.  Aluna informa que vai faltar

7.  Vaga liberada na turma original

8.  Notifica alunas com reposição pendente

9.  Aluna seleciona turma no app

10. Confirmação automática

## 6.4 Lista de espera

- Turma cheia → interessadas entram na fila

- Vaga abre → notificação automática → 24h para aceitar

## 6.5 Aulas avulsas

- Aluna experiente compra aula única, escolhe turma com vaga, paga e agenda

## 6.6 User stories

- Como aluna, quero confirmar presença com um tap.

- Como aluna, quero ver turmas com vaga para repor aula sem WhatsApp.

- Como professora, quero ver quem está confirmada antes da aula.

- Como admin, quero que vagas não fiquem ociosas.

# 7. M3 — Registro de materiais

## 7.1 Registro de argila

11. Professora abre o app, seleciona turma/aula

12. Para cada aluna: tipo de argila (dropdown) + kg usados

13. Registra devolução se houver

14. Cálculo automático: usado − devolvido

- Tipos de argila configuráveis pela admin (nome + preço/kg)

## 7.2 Registro de queimas

**Biscoito (1ª queima):** não cobrada.

**Esmalte (2ª queima):** cobrada por peça. Caneca ~R\$5-6, prato R\$8-15 (configurável).

15. Professora seleciona aluna + tipo peça + tamanho

16. Sistema aplica preço configurado

17. Registra etapa: modelou / pintou / queima de esmalte

## 7.3 Campos opcionais (insight Ceramik)

|                                                                                                                                   |
|-----------------------------------------------------------------------------------------------------------------------------------|
| **✅ ATUALIZADO v1.1:** Insight do Ceramik: adicionar campos opcionais de dimensões e peso das peças para enriquecer o histórico. |

- Dimensões da peça (altura, diâmetro) — opcional

- Peso da peça — opcional

> *Campos opcionais não bloqueiam o fluxo. Professora pode preencher ou não.*

## 7.4 User stories

- Como professora, quero registrar argila e peças em menos de 2 min por aluna.

- Como admin, quero configurar preços de queima por tipo de peça.

- Como aluna, quero saber qual argila usei na aula passada.

# 8. M4 — Cobrança e pagamentos

## 8.1 Planos

|                |                                |                    |
|----------------|--------------------------------|--------------------|
| **Plano**      | **Descrição**                  | **Cancelamento**   |
| **Mensal**     | Valor cheio, renova automático | Aviso 10-15 dias   |
| **Trimestral** | Desconto                       | Multa 20% restante |
| **Semestral**  | Maior desconto                 | Multa 20% restante |
| **Avulsa**     | Pagamento único                | N/A                |
| **Oficina**    | Pagamento único, tudo incluso  | N/A                |

## 8.2 Composição da cobrança

**Total =** Mensalidade + Argilas do mês + Queimas de esmalte do mês

### Fluxo

18. 1º dia útil: sistema totaliza argilas + queimas por aluna

19. Gera painel de cobrança com valores discriminados

20. Débora revisa e confirma

21. Sistema dispara notificação para cada aluna

22. Aluna paga pelo app (Pix ou cartão)

23. Status atualiza: pendente → pago

## 8.3 Pagamentos

- **Pix:** Preferêncial. Sem taxas. QR code automático.

- **Cartão:** Via Nuvemshop. Parcela 2-3x (oficinas/planos).

## 8.4 Painel financeiro (só admin)

- Visão geral: total a receber, recebido, pendente

- Lista por aluna: plano, argilas, queimas, total, status

- Filtros e exportação (CSV/PDF)

## 8.5 User stories

- Como admin, quero ver num painel quem pagou e quem não pagou.

- Como admin, quero totalização automática sem perder 2 dias.

- Como aluna, quero ver detalhamento da cobrança.

- Como aluna, quero pagar pelo app sem link do WhatsApp.

# 9. M5 — Feed pessoal / histórico da aluna

Um dos 3 módulos prioritários para o MVP. Diário de evolução na cerâmica.

|           |                                                              |                |
|-----------|--------------------------------------------------------------|----------------|
| **ID**    | **Funcionalidade**                                           | **Prioridade** |
| **FP-01** | Timeline por aula: data, turma, o que fez                    | **Alta**       |
| **FP-02** | Foto(s) da peça em cada etapa                                | **Alta**       |
| **FP-03** | Registro de argila usada                                     | **Alta**       |
| **FP-04** | Anotações livres + notas rápidas com cores (insight Ceramik) | **Alta**       |
| **FP-05** | Privado por padrão, opção de publicar na comunidade          | **Média**      |
| **FP-06** | Filtro por tipo de peça, argila, período                     | **Baixa**      |
| **FP-07** | Campos opcionais: dimensões e peso da peça (insight Ceramik) | **Baixa**      |

## 9.1 User stories

- Como aluna, quero ver meu histórico de peças.

- Como aluna, quero saber qual argila usei na peça X.

- Como aluna, quero adicionar fotos em diferentes etapas.

- Como aluna, quero escolher se compartilho na comunidade ou não.

# 10. M6 — Comunidade

Feed social exclusivo. Modelo: grupo de Facebook clássico.

|           |                                      |                |
|-----------|--------------------------------------|----------------|
| **ID**    | **Funcionalidade**                   | **Prioridade** |
| **CM-01** | Feed único (sem separação por turma) | **Alta**       |
| **CM-02** | Post com foto/vídeo/texto            | **Alta**       |
| **CM-03** | Comentários e curtidas               | **Alta**       |
| **CM-04** | Sem compartilhamento externo         | **Alta**       |
| **CM-05** | Sem DM entre alunas                  | **Alta**       |
| **CM-06** | Chat professora ↔ aluna              | **Alta**       |
| **CM-07** | Enquetes e desafios criativos        | **Média**      |
| **CM-08** | Blog/dicas das professoras           | **Média**      |
| **CM-09** | Acesso só alunas ativas              | **Alta**       |

## 10.1 Moderação

24. Filtro automático (IA) para conteúdo político/inadequado

25. Flagados → fila de aprovação

26. Sem flag → direto no feed

27. Admin/professoras podem excluir manualmente

## 10.2 Notificações

|                          |                   |                   |
|--------------------------|-------------------|-------------------|
| **Tipo**                 | **Comportamento** | **Configurável?** |
| **Recado geral**         | Obrigatório       | Não               |
| **Confirmação presença** | Obrigatório       | Não               |
| **Lembrete reposição**   | Obrigatório       | Não               |
| **Cobrança**             | Obrigatório       | Não               |
| **Nova postagem**        | Opcional          | Sim               |
| **Resposta comentário**  | Opcional          | Sim               |
| **Mensagem direta**      | Obrigatório       | Não               |

# 11. M7 — Controle de estoque

|           |                                      |                |
|-----------|--------------------------------------|----------------|
| **ID**    | **Funcionalidade**                   | **Prioridade** |
| **ES-01** | Cadastro de argilas com estoque (kg) | **Média**      |
| **ES-02** | Baixa automática conforme uso        | **Média**      |
| **ES-03** | Alerta nível mínimo (~2 sacos)       | **Média**      |
| **ES-04** | Registro de compras                  | **Baixa**      |
| **ES-05** | Histórico de consumo mensal          | **Baixa**      |

> *Prazo reposição: ~5 dias. Alerta deve considerar janela + consumo médio.*

# 12. Mapa de telas

## 12.1 Telas da aluna

|                     |                                           |            |
|---------------------|-------------------------------------------|------------|
| **Tela**            | **Descrição**                             | **Módulo** |
| **Login/Cadastro**  | Entrada + aceite de políticas obrigatório | M1         |
| **Home**            | Próxima aula, notificações, atalhos       | M2         |
| **Minha agenda**    | Calendário, confirmação, reposições       | M2         |
| **Repor aula**      | Turmas com vaga                           | M2         |
| **Meu feed**        | Timeline pessoal + notas rápidas          | M5         |
| **Comunidade**      | Feed social                               | M6         |
| **Mensagens**       | Chat com professoras                      | M6         |
| **Meus pagamentos** | Cobrança, histórico, pagar                | M4         |
| **Perfil**          | Dados, notificações, plano                | M1         |

## 12.2 Telas da professora

|                         |                                        |            |
|-------------------------|----------------------------------------|------------|
| **Tela**                | **Descrição**                          | **Módulo** |
| **Dashboard**           | Turmas do dia, confirmadas, pendências | M2         |
| **Turma do dia**        | Lista presentes + registro rápido      | M3         |
| **Registrar materiais** | Aluna → argila + peças                 | M3         |
| **Comunidade**          | Feed + blog/dicas                      | M6         |
| **Mensagens**           | Chat com alunas                        | M6         |
| **Estoque**             | Visão argilas, alertas                 | M7         |

## 12.3 Telas da admin

|                         |                                              |            |
|-------------------------|----------------------------------------------|------------|
| **Tela**                | **Descrição**                                | **Módulo** |
| **Dashboard admin**     | Agenda, cobranças, moderação, alertas        | Todos      |
| **Gestão de turmas**    | Criar, editar, abrir/fechar                  | M2         |
| **Gestão de alunas**    | Cadastros, planos, histórico                 | M1         |
| **Políticas do ateliê** | Editar texto das políticas, forçar re-aceite | M1         |
| **Painel financeiro**   | Cobranças, status, exportar                  | M4         |
| **Moderar posts**       | Fila de posts flagados                       | M6         |
| **Notificações gerais** | Recados para todas                           | M6         |
| **Configurações**       | Preços queima, tipos argila                  | M3/M7      |

# 13. MVP e faseamento

## 13.1 MVP (Fase 1)

|                                                                                                                                                                           |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1\. Gestão de pagamentos e cobrança automática (argilas + queimas) 2. Sistema de reposição (confirmação de presença + reagendamento) 3. Feed pessoal / histórico da aluna |

Inclui: M1 (com políticas), M2, M3, M4, M5

## 13.2 Fase 2 — Comunidade

- M6 completo

## 13.3 Fase 3 — Extras

- M7 — Estoque

- Enquetes e desafios

- Blog das professoras

## 13.4 Descartado

- Loja integrada, marketplace, kits, certificados, videoaulas, integração WhatsApp

# 14. Diretrizes de design

|                                  |
|----------------------------------|
| Criativo • Artesanal • Acolhedor |

- **Estilo:** Minimalista e limpo.

- **Formas:** Cantos arredondados, orgânicas.

- **Fotos:** Reais do ateliê.

- **Paleta:** Tons quentes (mel, terracota). Débora enviará referências.

- **Tom:** Informal, acolhedor, textos diretos.

- **Mobile-first:** Design para celular. Web como espelho.

# 15. Requisitos não-funcionais

|                     |                                               |
|---------------------|-----------------------------------------------|
| **Categoria**       | **Requisito**                                 |
| **Performance**     | Telas carregam \< 2s em 4G                    |
| **Performance**     | Registro de materiais funciona offline        |
| **Segurança**       | Autenticação segura (e-mail + senha ou OAuth) |
| **Segurança**       | Financeiro só admin                           |
| **Segurança**       | LGPD: consentimento + opção excluir conta     |
| **Disponibilidade** | 99.5% uptime                                  |
| **Escala**          | Até 200 usuários simultâneos                  |
| **Backup**          | Diário automático                             |
| **Notificações**    | Push (FCM ou equivalente)                     |
| **Analytics**       | DAU/MAU, telas mais acessadas                 |

# 16. Próximos passos

|        |                                                |           |               |
|--------|------------------------------------------------|-----------|---------------|
| **\#** | **Ação**                                       | **Resp.** | **Prazo**     |
| **1**  | Débora aprovar PRD v1.1                        | Débora    | 1 semana      |
| **2**  | Enviar formulário cadastro (Google Forms)      | Débora    | 1 semana      |
| **3**  | Enviar fotos controle manual (argilas/queimas) | Débora    | 1 semana      |
| **4**  | Enviar referências visuais + identidade visual | Débora    | 15 dias       |
| **5**  | Baixar e analisar o app Ceramik em detalhe     | BaxiJen   | 1 semana      |
| **6**  | ~~Definir stack técnica~~ ✅ Definido (Flutter + Supabase + Astro) | BaxiJen   | Concluído |
| **7**  | Redigir texto das políticas do ateliê          | Débora    | 2 semanas     |
| **8**  | Criar wireframes MVP                           | BaxiJen   | 2 semanas     |
| **9**  | Apresentar wireframes                          | Todos     | Reunião \#2   |
| **10** | Configurar repositório (monorepo Flutter) — seguir seção 2.4 | BaxiJen   | 1 semana      |
| **11** | Recrutar grupo de testes                       | Débora    | Antes do beta |

PRD v1.2 — BaxiJen — Marcus, Luis Barbedo, Leonardo Camilo

Confidencial — Para desenvolvimento interno e revisão da cliente
