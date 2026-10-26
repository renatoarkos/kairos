-- ============================================================
-- Colunas que o sistema trata como LISTA (array) mas foram criadas como texto:
--   registros.encaminhamentos, negociacoes.tags, usuario_escolas_pipeline.tags
-- Como texto, o pipeline quebra no navegador ("d.slice(...).map is not a
-- function") e os encaminhamentos dos registros não aparecem. Converte o tipo
-- preservando o que já estiver gravado (aceita '["a","b"]', '{a,b}' e vazio).
-- Pode rodar mais de uma vez: só altera a coluna que ainda for texto.
-- ============================================================

CREATE OR REPLACE FUNCTION public._texto_para_lista(t text)
RETURNS text[]
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
  IF t IS NULL OR btrim(t) IN ('', '[]', '{}') THEN
    RETURN '{}'::text[];
  END IF;
  IF left(btrim(t), 1) = '[' THEN
    RETURN ARRAY(SELECT json_array_elements_text(t::json));
  END IF;
  RETURN t::text[];
END
$$;

DO $$
DECLARE
  alvo RECORD;
BEGIN
  FOR alvo IN
    SELECT * FROM (VALUES
      ('registros', 'encaminhamentos'),
      ('negociacoes', 'tags'),
      ('usuario_escolas_pipeline', 'tags')
    ) AS v(tabela, coluna)
  LOOP
    IF (SELECT data_type FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = alvo.tabela AND column_name = alvo.coluna) = 'text' THEN
      EXECUTE format('ALTER TABLE public.%I ALTER COLUMN %I DROP DEFAULT', alvo.tabela, alvo.coluna);
      EXECUTE format('ALTER TABLE public.%I ALTER COLUMN %I TYPE text[] USING public._texto_para_lista(%I)', alvo.tabela, alvo.coluna, alvo.coluna);
      EXECUTE format('ALTER TABLE public.%I ALTER COLUMN %I SET DEFAULT ''{}''::text[]', alvo.tabela, alvo.coluna);
    END IF;
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';
