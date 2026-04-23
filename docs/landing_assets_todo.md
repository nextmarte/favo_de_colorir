# Landing — assets pendentes da Débora

A landing está no ar com **placeholders elegantes** (gradientes em vez de fotos, contatos genéricos). Para sair do ar com identidade real, precisamos dos itens abaixo. Cada item lista onde ele entra na página.

## 1. Identidade visual

- **Logo final** em SVG (preferido) ou PNG @2x. Versões: padrão (cor sobre claro) e mono (claro sobre escuro).
  - Usado em: `landing/public/favicon.svg` (substituir), `Footer.astro` (texto "Favo de Colorir" pode virar SVG).
- **Paleta oficial** se diferente do app. Atualmente herdamos `app/lib/core/theme.dart`: mel `#8D4B00`, terracota `#C75B39`, surface bege `#FFF8F4`. Confirmar.

## 2. Fotos do ateliê (5–8)

Resolução mínima 1600px no lado maior, JPG ou WebP. Tipos:

1. Plano aberto da bancada de modelagem (alunas trabalhando, sem rosto identificável se possível).
2. Detalhe de mãos com argila molhada.
3. Forno aberto com peças.
4. Estande de esmaltação / paleta de cores.
5. Vista geral do espaço (entrada, prateleira de moldes).
6. (opcional) Peças finalizadas em close.

Substituir os tiles de gradiente em `landing/src/components/Studio.astro` por `<img>` com `loading="lazy"`.

## 3. Dados de contato

| Campo | Onde aparece | Placeholder atual |
|---|---|---|
| **WhatsApp** (E.164: `+5521999999999`) | `ContactCTA.astro` link `wa.me/` | `+55 (21) — a confirmar` |
| **Instagram** handle real | `ContactCTA.astro` + `Base.astro` schema `sameAs` | `@favodecolorir` |
| **E-mail** comercial | `ContactCTA.astro` link `mailto:` | `contato@favodecolorir.com.br` |
| **Endereço** completo (rua, número, bairro, CEP) | `Studio.astro` + `Base.astro` schema `PostalAddress` | "Tijuca, Rio de Janeiro · RJ" |

Procurar por `data-todo` no código para marcar exatamente o que substituir:

```bash
grep -rn 'data-todo' landing/src
```

## 4. Texto / cópia

- **Bio curta** do ateliê (1–2 parágrafos). A versão atual em `Studio.astro` é editorial mas genérica.
- **Anos de fundação** — usado na sidebar vertical do hero (`Hero.astro`, `vlabel`). Atualmente "desde 2018" (placeholder).
- **Política de privacidade / termos**: rodapé não tem links ainda. Quando textos existirem, criar páginas `/privacidade` e `/termos`.

## 5. SEO / OG

- **Imagem OG (`/og-default.png`)** 1200×630 com logo + frase curta sobre fundo bege. Atualmente referenciada em `Base.astro` mas o arquivo não existe — gerar e colocar em `landing/public/`.
- **Domínio final**: `astro.config.mjs` está com `https://favodecolorir.com.br` — confirmar que é o domínio comprado.

## 6. App store badges (quando lançar)

- Botão "Para alunas: baixar app" (`Hero.astro`, âncora `#alunas`) e "Baixar aplicativo" (`ContactCTA.astro`) hoje apontam para placeholder. Substituir por:
  - Link Play Store (Android)
  - Link App Store (iOS, depende do build iOS — dívida técnica separada)
  - Fallback: link direto para APK em `https://favodecolorir.com.br/app`

---

**Como entregar:** abrir issue no repo BaxiJen/favo_de_colorir com tag `landing-assets`, anexando arquivos ou link Drive.
