# Kairós — Gestão Comercial

Plataforma de gestão comercial da Kairós Consultoria Educacional. Arquitetura clonada da plataforma da We Make (`app_comercial_We Make`) e reestilizada com a identidade visual da Kairós.

## O que foi trazido da base original

- Toda a estrutura de páginas, componentes e ações de servidor (`src/`).
- As migrações SQL soltas na raiz do projeto original, organizadas aqui em `migrations/`.
- Convenções de arquitetura: Server Actions retornando `ActionResult`, Supabase (Postgres + RLS), design system via CSS custom properties em `src/app/globals.css`.

## O que foi trocado para a Kairós

- **Paleta de cores** — `src/app/globals.css` (bloco `:root`) e `tailwind.config.ts`: azul `#36B6E8`, marinho `#221E36`, vermelho `#EE3737`, amarelo `#F9CC36` (extraídos do manual de marca oficial).
- **Logos** — `public/images/logo-kairos-*.png` (versões colorida, branca e ícone isolado, extraídas dos arquivos de marca da Kairós).
- **Textos de marca** — "We Make" → "Kairós" em todo o código; "CVE Gestão Comercial" → "Kairós Gestão Comercial".
- Referências específicas da We Make sem equivalente conhecido na Kairós foram neutralizadas com marcadores `[COMPLETAR: ...]` (ex.: link/login da plataforma de demonstração) — não foram inventados.
- "Calculadora Eskolare" renomeada para "Calculadora de Precificação" — a lógica de taxas por trás ainda assume as taxas específicas da plataforma Eskolare (usada pela We Make/Cidade Viva) e **precisa ser revisada** para o modelo de cobrança real da Kairós antes de usar em produção.

## O que NÃO foi feito (fora do escopo pedido)

- Nenhum dado foi populado — a plataforma está estruturalmente pronta, mas vazia.
- Nomenclatura do domínio de dados (Escolas, Fornecedor, Negociação) mantida igual à We Make, por escolha explícita — ainda não adaptada para a linguagem do negócio da Kairós (famílias/pais).
- Sem projeto Supabase conectado — `.env.example` tem só placeholders. Migrações em `migrations/` estão prontas para rodar assim que houver um projeto real.
- `public/images/hero-login.png` é um gradiente placeholder gerado programaticamente (cores da marca), não uma foto real — ver prompts sugeridos para gerar a imagem definitiva.
- A geração de "proposta comercial" em PDF (`src/app/proposta/`, `src/app/propostas-pdf/`) tem conteúdo textual fortemente específico da We Make (cases, números, fotos da CEO) — a arquitetura foi mantida mas o conteúdo precisa ser reescrito do zero para a Kairós.

## Setup

```bash
npm install
cp .env.example .env.local  # preencher com um projeto Supabase real
npm run dev
```

Rodar as migrações de `migrations/` (em ordem cronológica pelo nome do arquivo) no SQL editor do Supabase antes do primeiro uso.
