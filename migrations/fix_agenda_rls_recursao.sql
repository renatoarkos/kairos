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
