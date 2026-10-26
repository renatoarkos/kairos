-- ============================================================
-- propostas: colunas de segmentos que a Calculadora grava ao gerar a proposta
-- (sem elas: "Could not find the 'seg_ensino_medio' column of 'propostas'").
-- Pode rodar mais de uma vez.
-- ============================================================
ALTER TABLE public.propostas
  ADD COLUMN IF NOT EXISTS seg_infantil       boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS seg_fundamental_1  boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS seg_fundamental_2  boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS seg_ensino_medio   boolean NOT NULL DEFAULT false;

NOTIFY pgrst, 'reload schema';
