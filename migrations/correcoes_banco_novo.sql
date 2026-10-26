-- ============================================================
-- CORREÇÕES DO BANCO NOVO — rodar UMA vez no SQL Editor do Supabase.
--   1) origem 'banco_leads' (botão Importar do Banco de Leads)
--   2) agenda: recursão infinita nas regras de acesso (criar/listar eventos)
--   3) colunas de lista (tags, encaminhamentos) criadas como texto
--   4) propostas: colunas de segmentos que a Calculadora grava
-- Pode rodar mais de uma vez.
-- ============================================================

-- Origem "banco_leads": usada quando uma escola é criada a partir do Banco de
-- Leads (botão "Importar do Banco de Leads" da tela Escolas). Sem esse valor na
-- lista, o banco recusa a gravação com "invalid input value for enum".
ALTER TYPE public.origem_lead ADD VALUE IF NOT EXISTS 'banco_leads';


-- ============================================================
-- Agenda: corrige "infinite recursion detected in policy for relation
-- agenda_eventos".
--
-- As policies de agenda_eventos consultavam agenda_participantes, e as de
-- agenda_participantes consultavam agenda_eventos: cada consulta aciona o RLS
-- da outra tabela, em círculo, e o banco recusa a operação (criar evento,
-- listar eventos). A saída é consultar a outra tabela por funções
-- SECURITY DEFINER, que leem sem passar pelo RLS (e só respondem sim/não).
--
-- Pode rodar mais de uma vez.
-- ============================================================

CREATE OR REPLACE FUNCTION public.usuario_participa_evento(p_evento uuid)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.agenda_participantes ap
    WHERE ap.evento_id = p_evento AND ap.profile_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.usuario_criou_evento(p_evento uuid)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.agenda_eventos e
    WHERE e.id = p_evento AND e.criado_por = auth.uid()
  );
$$;

GRANT EXECUTE ON FUNCTION public.usuario_participa_evento(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.usuario_criou_evento(uuid)     TO authenticated;

DROP POLICY IF EXISTS agenda_eventos_select ON public.agenda_eventos;
CREATE POLICY agenda_eventos_select
  ON public.agenda_eventos FOR SELECT
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR criado_por = auth.uid()
    OR public.usuario_participa_evento(id)
  );

DROP POLICY IF EXISTS agenda_participantes_select ON public.agenda_participantes;
CREATE POLICY agenda_participantes_select
  ON public.agenda_participantes FOR SELECT
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR profile_id = auth.uid()
    OR public.usuario_criou_evento(evento_id)
  );

DROP POLICY IF EXISTS agenda_participantes_insert ON public.agenda_participantes;
CREATE POLICY agenda_participantes_insert
  ON public.agenda_participantes FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_gerente_or_supervisor()
    OR public.usuario_criou_evento(evento_id)
  );

DROP POLICY IF EXISTS agenda_participantes_update ON public.agenda_participantes;
CREATE POLICY agenda_participantes_update
  ON public.agenda_participantes FOR UPDATE
  TO authenticated
  USING (
    profile_id = auth.uid()
    OR public.is_gerente_or_supervisor()
    OR public.usuario_criou_evento(evento_id)
  );

DROP POLICY IF EXISTS agenda_participantes_delete ON public.agenda_participantes;
CREATE POLICY agenda_participantes_delete
  ON public.agenda_participantes FOR DELETE
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR public.usuario_criou_evento(evento_id)
  );

NOTIFY pgrst, 'reload schema';


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
