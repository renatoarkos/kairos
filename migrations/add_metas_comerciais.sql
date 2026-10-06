-- ============================================================
-- Metas comerciais editáveis — antes viviam hardcoded em src/lib/metas.ts
-- e num objeto local duplicado em comercial/metas/page.tsx (os dois tinham
-- que ser editados junto pra não divergir). Agora ficam nessa tabela
-- singleton (uma linha só, id sempre 1), editável por um formulário em
-- /comercial/metas em vez de precisar mexer em código toda vez que a meta
-- mudar.
--
-- Valores iniciais = os últimos números confirmados no briefing da Kairós
-- (2026-09-21/28): reuniões e prazo de Hugo (Diretor Executivo), receita de
-- Francieudes (Diretor Financeiro); alunos/propostas/minutas ainda sem
-- número oficial da Kairós, mantidos como estavam (herdados da We Make).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.metas_comerciais (
    id                  integer PRIMARY KEY DEFAULT 1,
    meta_alunos         integer NOT NULL DEFAULT 0,
    meta_receita        numeric NOT NULL DEFAULT 0,
    meta_reunioes       integer NOT NULL DEFAULT 0,
    meta_propostas      integer NOT NULL DEFAULT 0,
    meta_minutas        integer NOT NULL DEFAULT 0,
    meta_escolas_novas  integer NOT NULL DEFAULT 0,
    prazo               date NOT NULL,
    updated_at          timestamptz NOT NULL DEFAULT now(),
    atualizado_por       uuid REFERENCES public.usuarios(id),
    CONSTRAINT metas_comerciais_singleton CHECK (id = 1)
);

INSERT INTO public.metas_comerciais (id, meta_alunos, meta_receita, meta_reunioes, meta_propostas, meta_minutas, meta_escolas_novas, prazo)
VALUES (1, 4000, 1000000, 50, 25, 15, 100, '2026-12-31')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.metas_comerciais ENABLE ROW LEVEL SECURITY;

-- Leitura liberada pra qualquer usuário autenticado (mesmo nível de acesso
-- que os KPIs que essas metas alimentam). Escrita só via service_role
-- (server action em metas-actions.ts) — mesmo padrão de notas_escola.
CREATE POLICY metas_comerciais_select ON public.metas_comerciais
    FOR SELECT
    TO authenticated
    USING (true);
