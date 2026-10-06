-- ============================================================
-- Catálogo de livros — custo de venda + quantidade por ano letivo
--
-- Rodar DEPOIS de add_catalogo_livros_e_series.sql. Pode rodar de novo.
--
-- 1. produtos_livros.valor_venda: custo de venda unitário (preço da Kairós).
--    Fica vazio até alguém preencher — a planilha só traz o custo de gráfica
--    (`valor_unitario`).
-- 2. registro_serie_livros.ano_letivo: ano letivo a que a escolha de livros se
--    refere. Default 2027, porque as negociações em andamento são pro ano
--    letivo seguinte ao do orçamento da planilha (2026).
-- 3. view produtos_livros_demanda: quantidade de alunos por livro e ano letivo,
--    herdada dos Registros. Pra cada escola e série vale só o registro MAIS
--    RECENTE que tem livros escolhidos naquela série (evita contar a mesma
--    escola duas vezes quando há vários contatos). A quantidade de 2026 não
--    passa por aqui: é a tiragem da planilha, em produtos_livros.
-- ============================================================

ALTER TABLE public.produtos_livros
    ADD COLUMN IF NOT EXISTS valor_venda numeric(12,4);

ALTER TABLE public.registro_serie_livros
    ADD COLUMN IF NOT EXISTS ano_letivo integer NOT NULL DEFAULT 2027;

CREATE INDEX IF NOT EXISTS idx_registro_serie_livros_ano ON public.registro_serie_livros (ano_letivo);

CREATE OR REPLACE VIEW public.produtos_livros_demanda AS
WITH ultimo AS (
    SELECT DISTINCT ON (r.escola_id, l.serie, l.ano_letivo)
           r.escola_id, l.serie, l.ano_letivo, r.id AS registro_id
    FROM public.registro_serie_livros l
    JOIN public.registros r ON r.id = l.registro_id
    WHERE r.escola_id IS NOT NULL
    ORDER BY r.escola_id, l.serie, l.ano_letivo, r.data_contato DESC, r.created_at DESC
)
SELECT
    l.produto_id,
    l.ano_letivo                              AS ano,
    COUNT(DISTINCT u.escola_id)::integer      AS escolas,
    COALESCE(SUM(
        CASE l.serie
            WHEN 'infantil2'  THEN r.qtd_infantil2
            WHEN 'infantil3'  THEN r.qtd_infantil3
            WHEN 'infantil4'  THEN r.qtd_infantil4
            WHEN 'infantil5'  THEN r.qtd_infantil5
            WHEN 'fund1_ano1' THEN r.qtd_fund1_ano1
            WHEN 'fund1_ano2' THEN r.qtd_fund1_ano2
            WHEN 'fund1_ano3' THEN r.qtd_fund1_ano3
            WHEN 'fund1_ano4' THEN r.qtd_fund1_ano4
            WHEN 'fund1_ano5' THEN r.qtd_fund1_ano5
            WHEN 'fund2_ano6' THEN r.qtd_fund2_ano6
            WHEN 'fund2_ano7' THEN r.qtd_fund2_ano7
            WHEN 'fund2_ano8' THEN r.qtd_fund2_ano8
            WHEN 'fund2_ano9' THEN r.qtd_fund2_ano9
            WHEN 'medio_1s'   THEN r.qtd_medio_1s
            WHEN 'medio_2s'   THEN r.qtd_medio_2s
            WHEN 'medio_3s'   THEN r.qtd_medio_3s
        END
    ), 0)::integer                            AS alunos
FROM ultimo u
JOIN public.registro_serie_livros l
  ON l.registro_id = u.registro_id AND l.serie = u.serie AND l.ano_letivo = u.ano_letivo
JOIN public.registros r ON r.id = u.registro_id
GROUP BY l.produto_id, l.ano_letivo;
