# QA — fluxos de front e de back

Testes automatizados que abrem o sistema como um usuário e conferem cada fluxo
no navegador **e** no banco. Tudo que o teste cria tem o prefixo `ZZ` e é
apagado no fim. Rode sempre depois de mudar código ou banco.

## Como rodar

```bash
python -m venv .venv-qa && .venv-qa/Scripts/pip install playwright   # uma vez
export QA_USUARIO=hugo QA_SENHA='<senha do hugo>'                    # conta de gerente
mkdir -p qa/saida
python qa/smoke.py qa/saida/ids.json      # todas as páginas + APIs (ids.json: {"escola": "<uuid>"})
python qa/flow1.py qa/saida               # login + nova escola
python qa/flow2.py qa/saida               # escola, registro com livros por série, produtos, metas
python qa/flow3.py qa/saida               # quantidade de alunos, ficha, usuários
python qa/flow4.py qa/saida               # agenda, transcrição, formulário público
python qa/flow5.py qa/saida               # pipeline, calculadora → proposta → PDF
python qa/audit_cols.py                   # colunas que o código grava e a tabela não tem
python qa/audit_sel.py                    # colunas que o código lê/filtra e a tabela não tem
```

Variáveis opcionais: `QA_BASE` (padrão: o site em produção), `QA_CHROME` e
`QA_TERMOS_PROIBIDOS` (regex com termos que não podem aparecer no site; fica fora do repositório).
Precisa do `.env.local` com as chaves do Supabase (só leitura/limpeza dos testes).

## Checklist de fluxos

| # | Fluxo | Teste | Situação |
|---|-------|-------|----------|
| 0 | Todas as páginas abrem sem erro (49 páginas, logado e público) | smoke.py | OK |
| 0 | Páginas internas exigem login | smoke.py | OK |
| 0 | APIs de leitura respondem | smoke.py | OK |
| 0 | Nenhum texto visível cita outro sistema | smoke.py | OK |
| 1 | Login pela tela | flow1 | OK |
| 2 | Escola: criar, abrir ficha, editar | flow1/2 | OK |
| 3 | Registro com alunos e livros por série; reabrir; não duplicar | flow2 | OK |
| 3 | Demanda de livros em 2027 vem dos registros | flow2 | OK |
| 4 | Produtos: editar custo de venda, filtro 2027, cadastrar | flow2 | OK |
| 5 | Metas: editar | flow2 | OK |
| 6 | Quantidade de Alunos: série e marca de livro | flow3 | OK |
| 7 | Ficha da escola: tarefa, nota, novo número de alunos | flow3 | OK |
| 8 | Usuários: criar (cria também o perfil) e entrar | flow3 | OK |
| 11 | Transcrição de reunião | flow4 | OK |
| 12 | Formulário público → pré-cadastro → lead | flow4 | OK |
| 10 | Agenda: criar evento | flow4 | depende de `correcoes_banco_novo.sql` |
| 9 | Pipeline CRM: card de negociação | flow5 | depende de `correcoes_banco_novo.sql` |
| 13 | Calculadora → proposta → link público | flow5 | depende de `correcoes_banco_novo.sql` |
| 14 | PDF da proposta | flow5 | depende de `correcoes_banco_novo.sql` |
| — | Importar do Banco de Leads (botão da tela Escolas) | manual | depende de `correcoes_banco_novo.sql` |
| — | E-mails (convite de agenda, envio em massa) | manual | depende de `RESEND_API_KEY` |

## Regras

- Todo defeito achado vira correção **e** um passo neste checklist.
- Mudança de banco só vale depois de rodar `migrations/correcoes_banco_novo.sql`
  (ou o `_SETUP_COMPLETO.sql` numa instalação nova) e repetir os testes.
