# Vídeos de fundo — telas de login dos hubs

Referenciados em `src/app/hub/comercial/login/page.tsx`, `src/app/hub/contratos/login/page.tsx`
e `src/app/hub/pedidos/login/page.tsx` (vídeo de fundo em loop, sem áudio, atrás do formulário
de login).

| Arquivo | Pasta |
|---|---|
| `hero.mp4` | `public/videos/` |
| `hero1.mp4` | `public/videos/` |
| `hero2.mp4` | `public/videos/` |

Cada tela de login lista os 3 arquivos como fontes alternativas, mas na prática cada uma toca só
a **primeira da sua lista** (`hub/comercial` toca `hero.mp4`, `hub/contratos` toca `hero1.mp4`,
`hub/pedidos` toca `hero2.mp4`) — ou seja, você pode entregar **3 vídeos diferentes** (um pra cada
tela) ou o **mesmo vídeo 3 vezes** com esses 3 nomes, se não quiser produzir três cenas distintas
agora. Qualquer um dos dois funciona sem mexer em código.

Sugestão de formato: mp4 (H.264), sem áudio, 10-20s em loop, paisagem, cena institucional
(escola/turma/ambiente Kairós) — mesmo espírito do `foto_propostacomercial.png`.
