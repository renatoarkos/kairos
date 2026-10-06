# Assets da proposta comercial — pendentes

Esta pasta (`public/proposta/`) é referenciada pelo código em:
`src/app/proposta/[token]/PropostaView.tsx`, `src/app/proposta/[token]/opengraph-image.tsx`,
`src/app/proposta/acesso/page.tsx` e `src/app/acesso-escola/page.tsx`.

Coloque cada arquivo abaixo **exatamente com esse nome** na pasta indicada. O código já está
pronto para lê-los assim que existirem — não precisa mexer em nada além de salvar o arquivo.

## Obrigatórios (sem fallback — se faltar, aparece ícone de imagem quebrada na página pública)

| Arquivo | Pasta | Formato/proporção sugerida | O que precisa mostrar |
|---|---|---|---|
| `logo-white.png` | `public/proposta/` | PNG transparente, ~140×36px (horizontal) | Logo Kairós em branco, para fundo escuro |
| `logo-color.png` | `public/proposta/` | PNG transparente, ~160×44px (horizontal) | Logo Kairós colorida, para fundo claro |
| `foto_propostacomercial.png` | `public/proposta/` | Foto grande, paisagem (ex. 1600×900+) | Foto institucional Kairós (turma, sala, equipe) — vira fundo de seção e imagem de compartilhamento (og:image) |
| `ceo.png` | `public/proposta/` | Foto retrato, enquadramento vertical, rosto centralizado no topo | Foto do responsável/representante da Kairós que assina a proposta |
| `proposta1.png` | `public/proposta/` | Foto paisagem, textura/ambiente | Imagem de fundo decorativa (opacidade baixa) de uma seção |
| `proposta3.png` | `public/proposta/` | Foto paisagem, full-bleed | Imagem de fundo de seção |
| `proposta4.png` | `public/proposta/` | Foto paisagem, full-bleed (usada em 2 seções) | Imagem de fundo de seção |
| `proposta5.png` | `public/proposta/` | Foto paisagem, full-bleed | Imagem de fundo de seção |

**Além disso, me diga o nome e cargo da pessoa da foto `ceo.png`** — deixei marcado
`[COMPLETAR: nome]` e `[COMPLETAR: cargo]` no código (`PropostaView.tsx`) até você confirmar quem é.

## Com fallback (se faltar, a seção só some — não quebra nada)

| Arquivo | Pasta | Proporção sugerida | O que precisa mostrar |
|---|---|---|---|
| `material-didatico.png` | `public/proposta/` | PNG transparente, vertical, para composição com sombra | Imagem "genérica" do material/produto Kairós, mostrada quando a proposta não tem capas por segmento definidas |
| `infantil-5.jpg` | `public/proposta/capas-livros/` | Retrato, ~2:3 (capa de livro) | Capa do material do segmento "Infantil" |
| `1ano-ef.jpg` | `public/proposta/capas-livros/` | Retrato, ~2:3 | Capa do material do segmento "Fund. I" |
| `6ano.jpg` | `public/proposta/capas-livros/` | Retrato, ~2:3 | Capa do material do segmento "Fund. II" |
| `1ano-em.jpg` | `public/proposta/capas-livros/` | Retrato, ~2:3 | Capa do material do segmento "Ensino Médio" |

**Pergunta antes de você produzir essas 5 últimas**: a Kairós entrega material didático físico
(livros/apostilas) por segmento, como a We Make? Se não entrega, me avisa que eu removo essa seção
inteira da proposta em vez de forçar um conceito que não existe no produto da Kairós.

## Vídeos (pasta separada, ver `public/videos/LEIA-ME.md`)
