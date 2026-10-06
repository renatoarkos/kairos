-- ============================================================
-- Corrige escolas_resumo: virou uma TABELA vazia na introspecção
-- automática do schema (000_schema_base.sql), porque na We Make ela é uma
-- VIEW viva — criada direto no Supabase, fora de qualquer migration
-- versionada, então a introspecção via PostgREST só enxergou suas
-- colunas e recriou como tabela comum (sem nenhuma linha).
--
-- Isso deixava 9 telas da plataforma (priorização, tabela geral, metas,
-- jornada, jornada visual, leads, ficha da escola) sempre vazias mesmo
-- com escolas cadastradas — todas leem de escolas_resumo, não de escolas.
--
-- security_invoker=true faz a view respeitar o RLS de quem está
-- consultando (gerente vê tudo; consultor só o que já vê hoje em
-- `escolas`), em vez do dono da view — mesmo comportamento observado na
-- We Make (fila de priorização muda de tamanho conforme o cargo de quem
-- está logado).
-- ============================================================

DROP TABLE IF EXISTS public.escolas_resumo;

CREATE VIEW public.escolas_resumo
WITH (security_invoker = true) AS
SELECT
  e.*,
  ultimo.data_contato  AS ultimo_contato,
  ultimo.classificacao AS classificacao_atual,
  ultimo.probabilidade AS probabilidade_atual,
  u.nome_completo      AS responsavel_nome
FROM public.escolas e
LEFT JOIN LATERAL (
  SELECT r.data_contato, r.classificacao, r.probabilidade
  FROM public.registros r
  WHERE r.escola_id = e.id
  ORDER BY r.data_contato DESC, r.created_at DESC
  LIMIT 1
) ultimo ON true
LEFT JOIN public.usuarios u ON u.id = e.responsavel_id;
