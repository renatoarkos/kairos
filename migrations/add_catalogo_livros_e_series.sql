-- ============================================================
-- Catálogo de produtos (livros) + séries nos Registros
--
-- PARTE 1: catálogo `produtos_livros` (ficha técnica + valores, 82 livros da
--          planilha, cada livro ligado à sua série).
-- PARTE 2: Registros passam a guardar a quantidade de alunos de TODAS as
--          séries (Infantil 2 ao 3º ano do Médio) e os livros escolhidos pra
--          cada série (`registro_serie_livros`, ligada a `produtos_livros`).
--
-- Carga inicial vinda da planilha "2309 Kairos Educacional.xlsx" (aba
-- "OPÇÃO CAPA DURA", orçamento de 23/09/2026, 82 livros). Novos produtos
-- entram pelo botão "Cadastrar novo produto" em /comercial/produtos.
--
-- Mapeamento planilha → coluna:
--   TÍTULO/DESCRIÇÃO → titulo        AL/PR → publico
--   LARGURA/ALTURA (mm) → largura_mm / altura_mm
--   FORMATO FECHADO → formato_fechado
--   PAPEL CAPA / G/M² / COR CAPA / ENOBRECIMENTO 1 → papel_capa / gramatura_capa / cor_capa / enobrecimento
--   Papelão / Forro → papelao / forro
--   PAPEL MIOLO / G/M² / COR / QTD. PÁGINAS → papel_miolo / gramatura_miolo / cor_miolo / qtd_paginas
--   ACABAMENTO / SHRINK / KIT-AVULSO → acabamento / shrink / tipo_venda
--   TIRAGEM / tiragem atualizada 23/09 → tiragem / tiragem_atualizada
--   VALOR MANUSEIO / PÁGINA / CAPA / shirink → valor_manuseio / valor_pagina / valor_capa / valor_shrink
--   VALOR UNITÁRIO → valor_unitario   PESO LÍQUIDO UNITÁRIO → peso_liquido_unitario
--   VALOR TOTAL → valor_total (calculada: (unitário + manuseio) × tiragem
--   atualizada, a mesma fórmula da planilha)
--
-- Rodar inteiro no SQL Editor do Supabase. Pode rodar de novo sem duplicar:
-- a carga usa ON CONFLICT (opcao_orcamento, titulo) DO NOTHING.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.produtos_livros (
    id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    opcao_orcamento       text NOT NULL DEFAULT 'Opção capa dura',
    titulo                text NOT NULL,
    serie                 text,                       -- código da série (ver src/lib/series.ts); NULL = guia/avulso sem série
    publico               text,                       -- Aluno | Professor
    largura_mm            integer,
    altura_mm             integer,
    formato_fechado       text,
    papel_capa            text,
    gramatura_capa        integer,
    cor_capa              text,
    enobrecimento         text,
    papelao               text,                       -- valor cru da planilha (unidade não informada)
    forro                 text,
    papel_miolo           text,
    gramatura_miolo       integer,
    cor_miolo             text,
    qtd_paginas           integer,
    acabamento            text,
    shrink                integer,                    -- coluna SHRINK da planilha
    tipo_venda            text,                       -- Avulso | Kit
    tiragem               integer,
    tiragem_atualizada    integer,
    valor_manuseio        numeric(12,4),
    valor_pagina          numeric(12,4),
    valor_capa            numeric(12,4),
    valor_shrink          numeric(12,4),
    valor_unitario        numeric(12,4),
    peso_liquido_unitario numeric(12,4),
    valor_total           numeric(14,2) GENERATED ALWAYS AS (
        round((coalesce(valor_unitario, 0) + coalesce(valor_manuseio, 0)) * coalesce(tiragem_atualizada, 0), 2)
    ) STORED,
    observacoes           text,
    ativo                 boolean NOT NULL DEFAULT true,
    criado_por            uuid REFERENCES public.usuarios(id),
    created_at            timestamptz NOT NULL DEFAULT now(),
    updated_at            timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT produtos_livros_titulo_unico UNIQUE (opcao_orcamento, titulo)
);

CREATE INDEX IF NOT EXISTS idx_produtos_livros_titulo ON public.produtos_livros (titulo);

ALTER TABLE public.produtos_livros ENABLE ROW LEVEL SECURITY;

-- Leitura liberada pra qualquer usuário autenticado. Escrita só via
-- service_role (server action em produtos-actions.ts) — mesmo padrão de
-- metas_comerciais e notas_escola.
DROP POLICY IF EXISTS produtos_livros_select ON public.produtos_livros;
CREATE POLICY produtos_livros_select ON public.produtos_livros
    FOR SELECT
    TO authenticated
    USING (true);

-- ── Carga inicial: 82 livros da planilha ─────────────────────
INSERT INTO public.produtos_livros (
    opcao_orcamento, titulo, publico, largura_mm, altura_mm, formato_fechado,
    papel_capa, gramatura_capa, cor_capa, enobrecimento, papelao, forro,
    papel_miolo, gramatura_miolo, cor_miolo, qtd_paginas, acabamento,
    shrink, tipo_venda, tiragem, tiragem_atualizada,
    valor_manuseio, valor_pagina, valor_capa, valor_shrink, valor_unitario, peso_liquido_unitario
) VALUES
  ('Opção capa dura', '1º ANO - APDÃO FÍSICA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 52, 'Espriral branco - capa dura', 1, 'Avulso', 51, 55, 1.5, 0.205, 7.88, 0.35, 23.04, NULL),
  ('Opção capa dura', '1º ANO - ARTES', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 94, 'Espriral branco - capa dura', 1, 'Avulso', 94, 125, 1.5, 0.185, 7.5, 0.35, 30.78, NULL),
  ('Opção capa dura', '1º ANO - CIÊNCIAS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 128, 'Espriral branco - capa dura', 1, 'Avulso', 127, 117, 1.5, 0.185, 7.5, 0.35, 38.45, NULL),
  ('Opção capa dura', '1º ANO - HISTÓRIA E GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 132, 'Espriral branco - capa dura', 1, 'Avulso', 132, 117, 1.5, 0.185, 7.5, 0.35, 39.35, NULL),
  ('Opção capa dura', '1º ANO - INGLÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 118, 'Espriral branco - capa dura', 1, 'Avulso', 118, 77, 1.5, 0.205, 7.88, 0.35, 39.54, NULL),
  ('Opção capa dura', '1º ANO - LITERATURA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 134, 'Espriral branco - capa dura', 1, 'Avulso', 133, 69, 1.5, 0.205, 7.88, 0.35, 43.54, NULL),
  ('Opção capa dura', '1º ANO - MATEMÁTIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 170, 'Espriral branco - capa dura', 1, 'Avulso', 169, 105, 1.5, 0.185, 7.5, 0.35, 47.93, NULL),
  ('Opção capa dura', '1º ANO - PORTUGUÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 144, 'Espriral branco - capa dura', 1, 'Avulso', 143, 109, 1.5, 0.185, 7.5, 0.35, 42.06, NULL),
  ('Opção capa dura', '1º ANO5 - TEOLOGIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 104, 'Espriral branco - capa dura', 1, 'Avulso', 103, 125, 1.5, 0.185, 7.5, 0.35, 33.04, NULL),
  ('Opção capa dura', '2º ANO - APDÃO FÍSICA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 68, 'Espriral branco - capa dura', 1, 'Avulso', 68, 66, 1.5, 0.205, 7.88, 0.35, 27.04, NULL),
  ('Opção capa dura', '2º ANO - ARTES', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 102, 'Espriral branco - capa dura', 1, 'Avulso', 101, 138, 1.5, 0.185, 7.5, 0.35, 32.59, NULL),
  ('Opção capa dura', '2º ANO - CIÊNCIAS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 138, 'Espriral branco - capa dura', 1, 'Avulso', 138, 134, 1.5, 0.185, 7.5, 0.35, 40.71, NULL),
  ('Opção capa dura', '2º ANO - HISTÓRIA E GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 182, 'Espriral branco - capa dura', 1, 'Avulso', 182, 190, 1.5, 0.185, 7.5, 0.35, 50.63, NULL),
  ('Opção capa dura', '2º ANO - INGLÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 102, 'Espriral branco - capa dura', 1, 'Avulso', 102, 90, 1.5, 0.205, 7.88, 0.35, 35.54, NULL),
  ('Opção capa dura', '2º ANO - LITERATURA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 176, 'Espriral branco - capa dura', 1, 'Avulso', 176, 73, 1.5, 0.205, 7.88, 0.35, 54.04, NULL),
  ('Opção capa dura', '2º ANO - MATEMÁTIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 186, 'Espriral branco - capa dura', 1, 'Avulso', 186, 122, 1.5, 0.185, 7.5, 0.35, 51.54, NULL),
  ('Opção capa dura', '2º ANO - PORTUGUÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 178, 'Espriral branco - capa dura', 1, 'Avulso', 178, 104, 1.5, 0.185, 7.5, 0.35, 49.73, NULL),
  ('Opção capa dura', '2º ANO - TEOLOGIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 116, 'Espriral branco - capa dura', 1, 'Avulso', 115, 114, 1.5, 0.185, 7.5, 0.35, 35.74, NULL),
  ('Opção capa dura', '3º ANO - APDÃO FÍSICA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 48, 'Espriral branco - capa dura', 1, 'Avulso', 47, 58, 1.5, 0.205, 7.88, 0.35, 22.04, NULL),
  ('Opção capa dura', '3º ANO - ARTES', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 80, 'Espriral branco - capa dura', 1, 'Avulso', 80, 94, 1.5, 0.205, 7.88, 0.35, 30.04, NULL),
  ('Opção capa dura', '3º ANO - CIÊNCIAS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 228, 'Espriral branco - capa dura', 1, 'Avulso', 228, 90, 1.5, 0.205, 7.88, 0.35, 67.04, NULL),
  ('Opção capa dura', '3º ANO - GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 122, 'Espriral branco - capa dura', 1, 'Avulso', 122, 168, 1.5, 0.185, 7.5, 0.35, 37.1, NULL),
  ('Opção capa dura', '3º ANO - HISTÓRIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 102, 'Espriral branco - capa dura', 1, 'Avulso', 102, 168, 1.5, 0.185, 7.5, 0.35, 32.59, NULL),
  ('Opção capa dura', '3º ANO - INGLÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 102, 'Espriral branco - capa dura', 1, 'Avulso', 101, 68, 1.5, 0.205, 7.88, 0.35, 35.54, NULL),
  ('Opção capa dura', '3º ANO - LITERATURA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 134, 'Espriral branco - capa dura', 1, 'Avulso', 134, 64, 1.5, 0.205, 7.88, 0.35, 43.54, NULL),
  ('Opção capa dura', '3º ANO - MATEMÁTIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 170, 'Espriral branco - capa dura', 1, 'Avulso', 170, 95, 1.5, 0.205, 7.88, 0.35, 52.54, NULL),
  ('Opção capa dura', '3º ANO - PORTUGUÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 180, 'Espriral branco - capa dura', 1, 'Avulso', 180, 41, 1.5, 1.6, 10, 0.35, 298.35, NULL),
  ('Opção capa dura', '3º ANO - TEOLOGIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 94, 'Espriral branco - capa dura', 1, 'Avulso', 94, 88, 1.5, 0.205, 7.88, 0.35, 33.54, NULL),
  ('Opção capa dura', '4º ANO - APDÃO FÍSICA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 60, 'Espriral branco - capa dura', 1, 'Avulso', 60, 50, 1.5, 0.205, 7.88, 0.35, 25.04, NULL),
  ('Opção capa dura', '4º ANO - ARTES', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 122, 'Espriral branco - capa dura', 1, 'Avulso', 122, 73, 1.5, 0.205, 7.88, 0.35, 40.54, NULL),
  ('Opção capa dura', '4º ANO - CIÊNCIAS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 228, 'Espriral branco - capa dura', 1, 'Avulso', 228, 91, 1.5, 0.205, 7.88, 0.35, 67.04, NULL),
  ('Opção capa dura', '4º ANO - GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 132, 'Espriral branco - capa dura', 1, 'Avulso', 131, 147, 1.5, 0.185, 7.5, 0.35, 39.35, NULL),
  ('Opção capa dura', '4º ANO - HISTÓRIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 212, 'Espriral branco - capa dura', 1, 'Avulso', 212, 147, 1.5, 0.185, 7.5, 0.35, 57.4, NULL),
  ('Opção capa dura', '4º ANO - INGLÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 150, 'Espriral branco - capa dura', 1, 'Avulso', 149, 60, 1.5, 0.205, 7.88, 0.35, 47.54, NULL),
  ('Opção capa dura', '4º ANO - LITERATURA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 234, 'Espriral branco - capa dura', 1, 'Avulso', 233, 57, 1.5, 0.205, 7.88, 0.35, 68.54, NULL),
  ('Opção capa dura', '4º ANO - MATEMÁTIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 226, 'Espriral branco - capa dura', 1, 'Avulso', 226, 86, 1.5, 0.205, 7.88, 0.35, 66.54, NULL),
  ('Opção capa dura', '4º ANO - PORTUGUÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 204, 'Espriral branco - capa dura', 1, 'Avulso', 204, 86, 1.5, 0.205, 7.88, 0.35, 61.04, NULL),
  ('Opção capa dura', '4º ANO - TEOLOGIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 104, 'Espriral branco - capa dura', 1, 'Avulso', 104, 62, 1.5, 0.205, 7.88, 0.35, 36.04, NULL),
  ('Opção capa dura', '5º ANO - APDÃO FÍSICA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 90, 'Espriral branco - capa dura', 1, 'Avulso', 89, 55, 1.5, 0.205, 7.88, 0.35, 32.54, NULL),
  ('Opção capa dura', '5º ANO - ARTES', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 144, 'Espriral branco - capa dura', 1, 'Avulso', 144, 93, 1.5, 0.205, 7.88, 0.35, 46.04, NULL),
  ('Opção capa dura', '5º ANO - CIÊNCIAS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 260, 'Espriral branco - capa dura', 1, 'Avulso', 260, 85, 1.5, 0.205, 7.88, 0.35, 75.04, NULL),
  ('Opção capa dura', '5º ANO - GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 248, 'Espriral branco - capa dura', 1, 'Avulso', 247, 150, 1.5, 0.185, 7.5, 0.35, 65.52, NULL),
  ('Opção capa dura', '5º ANO - HISTÓRIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 248, 'Espriral branco - capa dura', 1, 'Avulso', 247, 150, 1.5, 0.185, 7.5, 0.35, 65.52, NULL),
  ('Opção capa dura', '5º ANO - INGLÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 164, 'Espriral branco - capa dura', 1, 'Avulso', 163, 81, 1.5, 0.205, 7.88, 0.35, 51.04, NULL),
  ('Opção capa dura', '5º ANO - LITERATURA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 240, 'Espriral branco - capa dura', 1, 'Avulso', 239, 69, 1.5, 0.205, 7.88, 0.35, 70.04, NULL),
  ('Opção capa dura', '5º ANO - MATEMÁTIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 246, 'Espriral branco - capa dura', 1, 'Avulso', 245, 84, 1.5, 0.205, 7.88, 0.35, 71.54, NULL),
  ('Opção capa dura', '5º ANO - PORTUGUÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 292, 'Espriral branco - capa dura', 1, 'Avulso', 291, 85, 1.5, 0.205, 7.88, 0.35, 83.04, NULL),
  ('Opção capa dura', '5º ANO - TEOLOGIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 118, 'Espriral branco - capa dura', 1, 'Avulso', 118, 74, 1.5, 0.205, 7.88, 0.35, 39.54, NULL),
  ('Opção capa dura', 'GUIA DE ESTUDO NÁRNIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 148, 'Espriral branco - capa dura', 1, 'Avulso', 148, 16, 1.5, 1.6, 10, 0.35, 247.15, NULL),
  ('Opção capa dura', 'GUIA DE ESTUDO POOH', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 130, 'Espriral branco - capa dura', 1, 'Avulso', 129, 78, 1.5, 0.205, 7.88, 0.35, 42.54, NULL),
  ('Opção capa dura', 'GUIA DE ESTUDO TEIA DE CHARLOTE', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 160, 'Espriral branco - capa dura', 1, 'Avulso', 159, 21, 1.5, 1.6, 10, 0.35, 266.35, NULL),
  ('Opção capa dura', 'Infantil 2 - ARTES', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 46, 'Espriral branco - capa dura', 1, 'Avulso', 46, 153, 1.5, 0.185, 7.5, 0.35, 19.95, NULL),
  ('Opção capa dura', 'Infantil 2 - CIÊNCIAS E APDÃO FÍSICA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 58, 'Espriral branco - capa dura', 1, 'Avulso', 57, 75, 1.5, 0.205, 7.88, 0.35, 24.54, NULL),
  ('Opção capa dura', 'Infantil 2 - INGLÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 36, 'Espriral branco - capa dura', 1, 'Avulso', 35, 88, 1.5, 0.205, 7.88, 0.35, 19.04, NULL),
  ('Opção capa dura', 'Infantil 2 - LITERATURA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 92, 'Espriral branco - capa dura', 1, 'Avulso', 92, 49, 1.5, 1.6, 10, 0.35, 157.55, NULL),
  ('Opção capa dura', 'Infantil 2 - MATEMÁTIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 130, 'Espriral branco - capa dura', 1, 'Avulso', 129, 97, 1.5, 0.205, 7.88, 0.35, 42.54, NULL),
  ('Opção capa dura', 'Infantil 2 - PORTUGUÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 94, 'Espriral branco - capa dura', 1, 'Avulso', 93, 97, 1.5, 0.205, 7.88, 0.35, 33.54, NULL),
  ('Opção capa dura', 'Infantil 2 - TEOLOGIA, HISTÓRIA E GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 72, 'Espriral branco - capa dura', 1, 'Avulso', 71, 82, 1.5, 0.205, 7.88, 0.35, 28.04, NULL),
  ('Opção capa dura', 'Infantil 3 - ARTES', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 48, 'Espriral branco - capa dura', 1, 'Avulso', 48, 160, 1.5, 0.185, 7.5, 0.35, 20.4, NULL),
  ('Opção capa dura', 'Infantil 3 - CIÊNCIAS E APDÃO FÍSICA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 54, 'Espriral branco - capa dura', 1, 'Avulso', 53, 89, 1.5, 0.205, 7.88, 0.35, 23.54, NULL),
  ('Opção capa dura', 'Infantil 3 - INGLÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 42, 'Espriral branco - capa dura', 1, 'Avulso', 41, 84, 1.5, 0.205, 7.88, 0.35, 20.54, NULL),
  ('Opção capa dura', 'Infantil 3 - LITERATURA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 114, 'Espriral branco - capa dura', 1, 'Avulso', 114, 78, 1.5, 0.205, 7.88, 0.35, 38.54, NULL),
  ('Opção capa dura', 'Infantil 3 - MATEMÁTIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 152, 'Espriral branco - capa dura', 1, 'Avulso', 152, 89, 1.5, 0.205, 7.88, 0.35, 48.04, NULL),
  ('Opção capa dura', 'Infantil 3 - PORTUGUÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 176, 'Espriral branco - capa dura', 1, 'Avulso', 175, 89, 1.5, 0.205, 7.88, 0.35, 54.04, NULL),
  ('Opção capa dura', 'Infantil 3 - TEOLOGIA, HISTÓRIA E GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 98, 'Espriral branco - capa dura', 1, 'Avulso', 97, 160, 1.5, 0.185, 7.5, 0.35, 31.68, NULL),
  ('Opção capa dura', 'Infantil 4 - ARTES', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 58, 'Espriral branco - capa dura', 1, 'Avulso', 58, 51, 1.5, 0.205, 7.88, 0.35, 24.54, NULL),
  ('Opção capa dura', 'Infantil 4 - CIÊNCIAS E APDÃO FÍSICA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 88, 'Espriral branco - capa dura', 1, 'Avulso', 87, 92, 1.5, 0.205, 7.88, 0.35, 32.04, NULL),
  ('Opção capa dura', 'Infantil 4 - HISTÓRIA E GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 68, 'Espriral branco - capa dura', 1, 'Avulso', 68, 41, 1.5, 1.6, 10, 0.35, 119.15, NULL),
  ('Opção capa dura', 'Infantil 4 - INGLÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 74, 'Espriral branco - capa dura', 1, 'Avulso', 74, 71, 1.5, 0.205, 7.88, 0.35, 28.54, NULL),
  ('Opção capa dura', 'Infantil 4 - LITERATURA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 118, 'Espriral branco - capa dura', 1, 'Avulso', 118, 81, 1.5, 0.205, 7.88, 0.35, 39.54, NULL),
  ('Opção capa dura', 'Infantil 4 - MATEMÁTIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 152, 'Espriral branco - capa dura', 1, 'Avulso', 152, 88, 1.5, 0.205, 7.88, 0.35, 48.04, NULL),
  ('Opção capa dura', 'Infantil 4 - PORTUGUÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 160, 'Espriral branco - capa dura', 1, 'Avulso', 159, 88, 1.5, 0.205, 7.88, 0.35, 50.04, NULL),
  ('Opção capa dura', 'Infantil 4 - TEOLOGIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 70, 'Espriral branco - capa dura', 1, 'Avulso', 70, 161, 1.5, 0.185, 7.5, 0.35, 25.37, NULL),
  ('Opção capa dura', 'Infantil 4 - TEOLOGIA, HISTÓRIA E GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 138, 'Espriral branco - capa dura', 1, 'Avulso', 138, 51, 1.5, 0.205, 7.88, 0.35, 44.54, NULL),
  ('Opção capa dura', 'Infantil 5 - ARTES', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 72, 'Espriral branco - capa dura', 1, 'Avulso', 72, 109, 1.5, 0.185, 7.5, 0.35, 25.82, NULL),
  ('Opção capa dura', 'Infantil 5 - CIÊNCIAS E APDÃO FÍSICA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 120, 'Espriral branco - capa dura', 1, 'Avulso', 120, 68, 1.5, 0.205, 7.88, 0.35, 40.04, NULL),
  ('Opção capa dura', 'Infantil 5 - HISTÓRIA E GEOGRAFIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 128, 'Espriral branco - capa dura', 1, 'Avulso', 128, 58, 1.5, 0.205, 7.88, 0.35, 42.04, NULL),
  ('Opção capa dura', 'Infantil 5 - INGLÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 96, 'Espriral branco - capa dura', 1, 'Avulso', 96, 60, 1.5, 0.205, 7.88, 0.35, 34.04, NULL),
  ('Opção capa dura', 'Infantil 5 - LITERATURA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 118, 'Espriral branco - capa dura', 1, 'Avulso', 118, 76, 1.5, 0.205, 7.88, 0.35, 39.54, NULL),
  ('Opção capa dura', 'Infantil 5 - MATEMÁTIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 186, 'Espriral branco - capa dura', 1, 'Avulso', 185, 36, 1.5, 1.6, 10, 0.35, 307.95, NULL),
  ('Opção capa dura', 'Infantil 5 - PORTUGUÊS', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 150, 'Espriral branco - capa dura', 1, 'Avulso', 150, 36, 1.5, 1.6, 10, 0.35, 250.35, NULL),
  ('Opção capa dura', 'Infantil 5 - TEOLOGIA', 'Aluno', 210, 297, '210x297', 'couche fosco', 170, '4x1', 'Laminação fosco', '18', 'Offset 180 0x0', 'Offset', 90, '4x4', 72, 'Espriral branco - capa dura', 1, 'Avulso', 72, 116, 1.5, 0.185, 7.5, 0.35, 25.82, NULL)
ON CONFLICT (opcao_orcamento, titulo) DO NOTHING;

-- ── Série de cada livro (a partir do título da planilha) ─────
-- "Infantil 2 - ARTES" → infantil2, "1º ANO - ARTES" → fund1_ano1 etc.
-- Os "GUIA DE ESTUDO ..." não têm série e ficam NULL (aparecem como livro
-- avulso, escolhível em qualquer série). Fund. II e Médio ainda não têm
-- livros na planilha: entram por "Cadastrar novo produto" com a série certa.
UPDATE public.produtos_livros SET serie = CASE
    WHEN titulo ILIKE 'Infantil 2 %' THEN 'infantil2'
    WHEN titulo ILIKE 'Infantil 3 %' THEN 'infantil3'
    WHEN titulo ILIKE 'Infantil 4 %' THEN 'infantil4'
    WHEN titulo ILIKE 'Infantil 5 %' THEN 'infantil5'
    WHEN titulo ILIKE '1º ANO%'      THEN 'fund1_ano1'
    WHEN titulo ILIKE '2º ANO%'      THEN 'fund1_ano2'
    WHEN titulo ILIKE '3º ANO%'      THEN 'fund1_ano3'
    WHEN titulo ILIKE '4º ANO%'      THEN 'fund1_ano4'
    WHEN titulo ILIKE '5º ANO%'      THEN 'fund1_ano5'
    ELSE NULL
END
WHERE serie IS NULL;

CREATE INDEX IF NOT EXISTS idx_produtos_livros_serie ON public.produtos_livros (serie);

-- ============================================================
-- PARTE 2 — Séries nos Registros
-- ============================================================

-- 2a. Quantidade de alunos por série em cada registro. As colunas agregadas
--     (qtd_infantil, qtd_fund1, qtd_fund2, qtd_medio) continuam existindo e
--     passam a ser a soma das séries. Em `escolas` essas colunas já existem.
ALTER TABLE public.registros
    ADD COLUMN IF NOT EXISTS qtd_infantil2  integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_infantil3  integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_infantil4  integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_infantil5  integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_fund1_ano1 integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_fund1_ano2 integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_fund1_ano3 integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_fund1_ano4 integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_fund1_ano5 integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_fund2_ano6 integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_fund2_ano7 integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_fund2_ano8 integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_fund2_ano9 integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_medio_1s   integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_medio_2s   integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS qtd_medio_3s   integer DEFAULT 0;

-- 2b. Livros escolhidos pra cada série de um registro (muitos-para-muitos
--     registro × série × livro do catálogo).
CREATE TABLE IF NOT EXISTS public.registro_serie_livros (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    registro_id uuid NOT NULL REFERENCES public.registros(id) ON DELETE CASCADE,
    serie       text NOT NULL CHECK (serie IN (
                    'infantil2','infantil3','infantil4','infantil5',
                    'fund1_ano1','fund1_ano2','fund1_ano3','fund1_ano4','fund1_ano5',
                    'fund2_ano6','fund2_ano7','fund2_ano8','fund2_ano9',
                    'medio_1s','medio_2s','medio_3s')),
    produto_id  uuid NOT NULL REFERENCES public.produtos_livros(id) ON DELETE CASCADE,
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT registro_serie_livros_unico UNIQUE (registro_id, serie, produto_id)
);

CREATE INDEX IF NOT EXISTS idx_registro_serie_livros_registro ON public.registro_serie_livros (registro_id);
CREATE INDEX IF NOT EXISTS idx_registro_serie_livros_produto  ON public.registro_serie_livros (produto_id);

ALTER TABLE public.registro_serie_livros ENABLE ROW LEVEL SECURITY;

-- Leitura pra qualquer autenticado (a tabela só guarda ids). Escrita só via
-- service_role, na server action upsertRegistro (src/lib/actions.ts).
DROP POLICY IF EXISTS registro_serie_livros_select ON public.registro_serie_livros;
CREATE POLICY registro_serie_livros_select ON public.registro_serie_livros
    FOR SELECT
    TO authenticated
    USING (true);
