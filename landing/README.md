# Favo de Colorir — Landing

Landing page do ateliê **Favo de Colorir**, em Astro 5 + Vanilla CSS, deploy estático na Vercel.

Design System: **Artisanal Modernism** (Epilogue + Manrope, paleta mel/terracota, no-line philosophy). Tokens em `src/styles/tokens.css` espelham `app/lib/core/theme.dart`.

## Setup

```bash
npm install
npx playwright install --with-deps chromium  # primeira vez (E2E)
```

## Scripts

| Comando | O que faz |
|---|---|
| `npm run dev` | Dev server em `http://localhost:4321` |
| `npm run build` | Build estático para `dist/` |
| `npm run preview` | Serve `dist/` localmente |
| `npm run check` | Astro check (TS + Astro) |
| `npm run test` | Vitest (unit) |
| `npm run test:watch` | Vitest watch |
| `npm run test:e2e` | Playwright smoke (sobe preview server) |

## Estrutura

```
src/
├── styles/    ← tokens, reset, global (vanilla CSS)
├── components/← Hero, ValueProps, Features, Plans, Studio, ContactCTA, Footer
│   └── ui/    ← Button, Card (primitivos)
├── layouts/   ← Base.astro (head, fonts, schema.org)
└── pages/     ← index.astro
tests/
├── unit/      ← Vitest com Astro Container API
└── e2e/       ← Playwright chromium
```

## Conteúdo placeholder

A primeira versão usa **placeholders** para fotos, contatos e endereço. Lista do que pedir à Débora:
👉 [`docs/landing_assets_todo.md`](../docs/landing_assets_todo.md)

Para localizar os pontos exatos no código:

```bash
grep -rn 'data-todo' src
```

## Deploy

Configurado para Vercel (`vercel.json` com `framework: astro`).

```bash
# uma vez:
vercel link

# deploy:
vercel --prod
```

Ou conectar o repo no dashboard da Vercel apontando para o subdir `landing/`.

## TDD

Padrão do monorepo: teste primeiro (RED), depois componente (GREEN), commit. Componentes UI primitivos têm Vitest unit; composições maiores são cobertas pelo Playwright E2E.
