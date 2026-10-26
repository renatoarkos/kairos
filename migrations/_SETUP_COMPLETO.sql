-- ################################################################
-- KAIROS — SCRIPT COMPLETO DE SETUP DO BANCO (v12)
-- Master v8 + metas_comerciais + catalogo de livros/series + custo de venda/demanda 2027.
-- Cole este arquivo inteiro no SQL Editor do Supabase e rode de uma vez.
-- Pode rodar mais de uma vez: nada é apagado além de políticas de acesso (RLS)
-- e views, que o próprio script recria. Os dados das tabelas são preservados.
--
-- IMPORTANTE (por que a v12 existe): a escolas_resumo é uma VIEW. Nas versões
-- anteriores o script criava antes uma TABELA provisória com esse nome e a
-- trocava por view no fim. O executor de SQL do Supabase acrescenta
-- "ENABLE ROW LEVEL SECURITY" para todo "CREATE TABLE" que acha no texto, e
-- isso quebrava com 42809 ("not supported for views"). Agora a view é criada
-- direto, sem tabela provisória.
-- ################################################################

-- Re-execução segura: remove as policies antigas do schema public (todas são
-- recriadas abaixo). Sem isso, rodar o script de novo falha com
-- "policy ... already exists".
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;


-- ================================================================
-- ARQUIVO: 000_schema_base.sql
-- ================================================================
-- ============================================================
-- Schema base da Kairos, extraido do banco real da We Make
-- (introspeccao via OpenAPI do PostgREST)
-- ============================================================

-- Tipos enum
DO $$ BEGIN
  CREATE TYPE public.perfil_pedagogico AS ENUM ('crista_catolica', 'evangelica', 'por_principio', 'crista_classica', 'convencional', 'outro');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.origem_lead AS ENUM ('feira', 'instagram', 'network', 'site', 'whatsapp', 'email', 'telefone', 'visita', 'evento', 'parceiro', 'outro', 'indicacao_escola', 'abeka', 'acsi', 'congresso_ecc', 'envio_material', 'opening_company', 'banco_leads');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.classificacao_lead AS ENUM ('quente', 'morno', 'frio');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.meio_contato AS ENUM ('presencial', 'whatsapp', 'email', 'telefone', 'videoconf', 'outro');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.nivel_interesse AS ENUM ('muito_baixo', 'baixo', 'medio', 'alto', 'muito_alto');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.prontidao_negociacao AS ENUM ('parada', 'nova_reuniao', 'esperando_retorno', 'apresentacao', 'contrato_enviado', 'atualizar_contrato', 'contrato_assinado', 'parceiro_ativo');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.abertura_propostal AS ENUM ('nenhuma', 'baixa', 'media', 'alta');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.tarefa_prioridade AS ENUM ('baixa', 'media', 'alta', 'urgente');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.tarefa_status AS ENUM ('pendente', 'concluida', 'cancelada');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.user_role AS ENUM ('gerente', 'supervisor', 'consultor', 'assistente', 'readonly');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Tabelas (sem FKs, pra nao depender de ordem)
CREATE TABLE IF NOT EXISTS public.agenda_eventos (
    id uuid DEFAULT gen_random_uuid(),
    titulo text NOT NULL,
    descricao text,
    local text,
    tipo text DEFAULT 'reuniao',
    cor text DEFAULT '#2563eb',
    data_inicio timestamptz NOT NULL,
    data_fim timestamptz NOT NULL,
    dia_inteiro boolean DEFAULT false,
    escola_id uuid,
    recorrencia text,
    criado_por uuid NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.agenda_participantes (
    id uuid DEFAULT gen_random_uuid(),
    evento_id uuid NOT NULL,
    profile_id uuid,
    email text NOT NULL,
    nome text,
    status text DEFAULT 'pendente',
    notificado boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.audit_log (
    id uuid DEFAULT gen_random_uuid(),
    user_id uuid,
    user_email text,
    action text NOT NULL,
    table_name text NOT NULL,
    record_id uuid,
    old_data jsonb,
    new_data jsonb,
    ip_address text,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.ciecc_inscritos (
    id uuid DEFAULT gen_random_uuid(),
    fonte text NOT NULL,
    nome text,
    tipo_pessoa text,
    tipo_inscricao text,
    cargo_original text,
    email text,
    telefone text,
    telefone_fixo text,
    cidade text,
    uf text,
    nome_escola text,
    cnpj_escola text,
    lote text,
    forma_pagamento text,
    status_financeiro text,
    valor_total numeric,
    tempo_funcionamento text,
    confessionalidade text,
    formacao_docentes text,
    cosmovisao_curriculo text,
    desafios_ecc text,
    interesse_bilingue integer,
    fatores_decisao text,
    investimento_atual text,
    disponibilidade_invest text,
    csi numeric,
    nps integer,
    interesse_solucao_cve text,
    decisores text,
    prazo_decisao text,
    qtd_alunos_total integer,
    qtd_infantil integer,
    qtd_fund1 integer,
    qtd_fund2 integer,
    qtd_medio integer,
    participou_congresso_anterior boolean,
    importado_em timestamptz DEFAULT now(),
    importado_por uuid,
    escola_id uuid,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.ciecc_leads_sem_escola (
    id uuid DEFAULT gen_random_uuid(),
    fonte text NOT NULL,
    nome text,
    tipo_inscricao text,
    instituicao text,
    email text,
    telefone text,
    cidade text,
    uf text,
    data_inscricao date,
    lote text,
    valor numeric,
    forma_pagamento text,
    status_financeiro text,
    importado_em timestamptz DEFAULT now(),
    importado_por uuid,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.contratos (
    id uuid DEFAULT gen_random_uuid(),
    escola_id uuid NOT NULL,
    formulario_enviado boolean DEFAULT false,
    formulario_recebido boolean DEFAULT false,
    minuta_enviada boolean DEFAULT false,
    retorno_minuta boolean DEFAULT false,
    observacao_minuta text,
    minuta_atualizada boolean DEFAULT false,
    contrato_enviado boolean DEFAULT false,
    contrato_assinado boolean DEFAULT false,
    contrato_arquivado boolean DEFAULT false,
    encaminhamento_final text,
    infantil2_qtd integer DEFAULT 0,
    infantil2_valor numeric DEFAULT 0,
    infantil3_qtd integer DEFAULT 0,
    infantil3_valor numeric DEFAULT 0,
    infantil4_qtd integer DEFAULT 0,
    infantil4_valor numeric DEFAULT 0,
    infantil5_qtd integer DEFAULT 0,
    infantil5_valor numeric DEFAULT 0,
    fund1_ano1_qtd integer DEFAULT 0,
    fund1_ano1_valor numeric DEFAULT 0,
    tempo_contrato integer DEFAULT 1,
    valor_total numeric,
    created_by uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    fund1_ano2_qtd integer DEFAULT 0,
    fund1_ano2_valor numeric DEFAULT 0,
    fund1_ano3_qtd integer DEFAULT 0,
    fund1_ano3_valor numeric DEFAULT 0,
    fund1_ano4_qtd integer DEFAULT 0,
    fund1_ano4_valor numeric DEFAULT 0,
    fund1_ano5_qtd integer DEFAULT 0,
    fund1_ano5_valor numeric DEFAULT 0,
    valor_total_calculado numeric DEFAULT 0,
    implantacao_status text DEFAULT 'nao_iniciada',
    implantacao_iniciada_em timestamptz,
    implantacao_concluida_em timestamptz,
    declinou boolean DEFAULT false,
    proposta_enviada boolean DEFAULT false,
    fund2_ano6_qtd integer DEFAULT 0,
    fund2_ano6_valor numeric DEFAULT 0,
    fund2_ano7_qtd integer DEFAULT 0,
    fund2_ano7_valor numeric DEFAULT 0,
    fund2_ano8_qtd integer DEFAULT 0,
    fund2_ano8_valor numeric DEFAULT 0,
    fund2_ano9_qtd integer DEFAULT 0,
    fund2_ano9_valor numeric DEFAULT 0,
    medio_1s_qtd integer DEFAULT 0,
    medio_1s_valor numeric DEFAULT 0,
    medio_2s_qtd integer DEFAULT 0,
    medio_2s_valor numeric DEFAULT 0,
    medio_3s_qtd integer DEFAULT 0,
    medio_3s_valor numeric DEFAULT 0,
    livro_impresso boolean DEFAULT false,
    livro_qtds jsonb NOT NULL,
    marcado_veterana boolean DEFAULT false,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.contratos_arquivos (
    id uuid DEFAULT gen_random_uuid(),
    escola_id uuid NOT NULL,
    nome text NOT NULL,
    path text NOT NULL,
    tamanho integer,
    tipo text,
    created_by uuid,
    created_at timestamptz DEFAULT now(),
    categoria text DEFAULT 'contrato',
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.documentos_oficiais (
    id uuid DEFAULT gen_random_uuid(),
    tipo text NOT NULL,
    nome_arquivo text NOT NULL,
    url text NOT NULL,
    storage_path text NOT NULL,
    tamanho integer,
    mime_type text,
    atualizado_por uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.escolas (
    id uuid DEFAULT gen_random_uuid(),
    nome text NOT NULL,
    cnpj text,
    perfil_pedagogico perfil_pedagogico DEFAULT 'convencional',
    escola_paideia boolean DEFAULT false,
    rua text,
    numero text,
    complemento text,
    bairro text,
    cidade text,
    estado text,
    cep text,
    telefone text,
    email text,
    site text,
    contato_nome text,
    contato_cargo text,
    diretor_nome text,
    qtd_infantil integer DEFAULT 0,
    qtd_fund1 integer DEFAULT 0,
    qtd_fund2 integer DEFAULT 0,
    qtd_medio integer DEFAULT 0,
    origem_lead origem_lead,
    responsavel_id uuid,
    observacoes text,
    ativa boolean DEFAULT true,
    created_by uuid,
    updated_by uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    total_alunos integer,
    potencial_financeiro integer,
    qtd_infantil2 integer DEFAULT 0,
    qtd_infantil3 integer DEFAULT 0,
    qtd_infantil4 integer DEFAULT 0,
    qtd_infantil5 integer DEFAULT 0,
    qtd_fund1_ano1 integer DEFAULT 0,
    qtd_fund1_ano2 integer DEFAULT 0,
    qtd_fund1_ano3 integer DEFAULT 0,
    qtd_fund1_ano4 integer DEFAULT 0,
    qtd_fund1_ano5 integer DEFAULT 0,
    qtd_fund2_ano6 integer DEFAULT 0,
    qtd_fund2_ano7 integer DEFAULT 0,
    qtd_fund2_ano8 integer DEFAULT 0,
    qtd_fund2_ano9 integer DEFAULT 0,
    qtd_medio_1s integer DEFAULT 0,
    qtd_medio_2s integer DEFAULT 0,
    qtd_medio_3s integer DEFAULT 0,
    maior_sala integer DEFAULT 0,
    prioridade_manual integer,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.form_precadastro_wemake (
    id uuid DEFAULT gen_random_uuid(),
    resp_email text NOT NULL,
    cnpj text,
    razao_social text NOT NULL,
    nome_fantasia text NOT NULL,
    rua text NOT NULL,
    numero text NOT NULL,
    bairro text NOT NULL,
    cep text,
    cidade text NOT NULL,
    estado text NOT NULL,
    email_institucional text NOT NULL,
    seg_infantil boolean DEFAULT false,
    seg_fundamental_1 boolean DEFAULT false,
    seg_fundamental_2 boolean DEFAULT false,
    seg_ensino_medio boolean DEFAULT false,
    alunos_infantil integer DEFAULT 0,
    alunos_fundamental_1 integer DEFAULT 0,
    alunos_fundamental_2 integer DEFAULT 0,
    alunos_ensino_medio integer DEFAULT 0,
    data_inicio_letivo date,
    data_fim_letivo date,
    formato_ano_letivo text,
    observacoes text,
    legal_nome text NOT NULL,
    legal_cpf text,
    legal_email text NOT NULL,
    legal_whatsapp text,
    legal_rua text NOT NULL,
    legal_numero text NOT NULL,
    legal_complemento text,
    legal_bairro text NOT NULL,
    legal_cidade text NOT NULL,
    legal_estado text NOT NULL,
    legal_cep text,
    fin_email_cobranca text NOT NULL,
    ticket_medio text,
    status text DEFAULT 'pendente',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    maior_sala integer DEFAULT 0,
    site text,
    telefone_institucional text,
    entrega_mesmo_endereco boolean DEFAULT true,
    entrega_rua text,
    entrega_numero text,
    entrega_complemento text,
    entrega_bairro text,
    entrega_cep text,
    entrega_cidade text,
    entrega_estado text,
    infantil4_qtd integer DEFAULT 0,
    infantil5_qtd integer DEFAULT 0,
    fund1_ano1_qtd integer DEFAULT 0,
    fund1_ano2_qtd integer DEFAULT 0,
    fund1_ano3_qtd integer DEFAULT 0,
    fund1_ano4_qtd integer DEFAULT 0,
    fund1_ano5_qtd integer DEFAULT 0,
    fund2_ano6_qtd integer DEFAULT 0,
    fund2_ano7_qtd integer DEFAULT 0,
    fund2_ano8_qtd integer DEFAULT 0,
    fund2_ano9_qtd integer DEFAULT 0,
    medio_1s_qtd integer DEFAULT 0,
    medio_2s_qtd integer DEFAULT 0,
    medio_3s_qtd integer DEFAULT 0,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.formularios (
    id uuid DEFAULT gen_random_uuid(),
    data_envio timestamptz DEFAULT now(),
    email_responsavel text NOT NULL,
    nome_escola text NOT NULL,
    cnpj text,
    rua text,
    numero text,
    complemento text,
    bairro text,
    cidade text,
    estado text,
    cep text,
    infantil2_qtd integer DEFAULT 0,
    infantil3_qtd integer DEFAULT 0,
    infantil4_qtd integer DEFAULT 0,
    infantil5_qtd integer DEFAULT 0,
    fund1_ano1_qtd integer DEFAULT 0,
    data_inicio_letivo date,
    data_fim_letivo date,
    formato_ano_letivo text,
    observacoes text,
    legal_nome text,
    legal_cpf text,
    legal_rg text,
    legal_orgao text,
    legal_rua text,
    legal_numero text,
    legal_complemento text,
    legal_bairro text,
    legal_cidade text,
    legal_estado text,
    legal_cep text,
    legal_email text,
    legal_celular text,
    fin_nome text,
    fin_cpf text,
    fin_rg text,
    fin_orgao text,
    fin_email text,
    fin_celular text,
    ped_nome text,
    ped_cpf text,
    ped_rg text,
    ped_orgao text,
    ped_email text,
    ped_celular text,
    fund1_ano2_qtd integer DEFAULT 0,
    fund1_ano3_qtd integer DEFAULT 0,
    fund1_ano4_qtd integer DEFAULT 0,
    fund1_ano5_qtd integer DEFAULT 0,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.leads_contato_escola (
    id uuid DEFAULT gen_random_uuid(),
    escola_id uuid NOT NULL,
    pessoa_id uuid,
    nome text,
    cargo text,
    telefone text,
    email text,
    ordem smallint,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.leads_escola (
    id uuid DEFAULT gen_random_uuid(),
    nome text NOT NULL,
    cnpj text,
    endereco text,
    bairro text,
    cidade text,
    uf text,
    cep text,
    qtd_alunos integer,
    alunos_infantil integer,
    alunos_fund1 integer,
    alunos_fund2 integer,
    alunos_ens_medio integer,
    tempo_funcionamento text,
    status_lead text,
    status_ciecc1 text,
    status_ciecc2 text,
    origem text,
    observacoes text,
    rep_legal_nome text,
    rep_legal_email text,
    rep_legal_tel text,
    escola_crm_id uuid,
    importado_em timestamptz DEFAULT now(),
    importado_por uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    updated_by text,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.leads_oikos_live (
    id uuid DEFAULT gen_random_uuid(),
    pessoa_id uuid,
    nome text,
    email text,
    telefone text,
    data_captacao timestamptz,
    qualificado boolean DEFAULT false,
    importado_em timestamptz DEFAULT now(),
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.leads_participacao (
    id uuid DEFAULT gen_random_uuid(),
    pessoa_id uuid NOT NULL,
    escola_id uuid,
    evento text NOT NULL,
    lote text,
    modalidade text,
    valor_lote numeric,
    valor_desconto numeric,
    valor_taxa numeric,
    valor_total numeric,
    forma_pagamento text,
    status_financeiro text,
    parcelas_pagas smallint,
    total_parcelas smallint,
    regra_desconto text,
    data_inscricao date,
    check_in boolean DEFAULT false,
    fonte text,
    participou_evento_anterior boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.leads_perfil_escola (
    id uuid DEFAULT gen_random_uuid(),
    escola_id uuid NOT NULL,
    evento_ref text,
    confessionalidade text,
    formacao_docentes text,
    cosmovisao text,
    desafios_ecc text,
    importancia_bilingue smallint,
    fatores_escolha text,
    investimento_atual text,
    disposicao_investimento text,
    nps smallint,
    csi text,
    interesse_solucao text,
    decisores text,
    prazo_decisao text,
    data_formulario date,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.leads_pessoa (
    id uuid DEFAULT gen_random_uuid(),
    nome_completo text,
    cpf text,
    rg text,
    email text,
    tel_celular text,
    tel_fixo text,
    tel_comercial text,
    sexo text,
    data_nascimento date,
    endereco text,
    bairro text,
    cidade text,
    uf text,
    cep text,
    tipo_inscricao text,
    cargo text,
    escola_id uuid,
    profile_id uuid,
    importado_em timestamptz DEFAULT now(),
    importado_por uuid,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.leads_universal (
    id uuid DEFAULT gen_random_uuid(),
    fonte text NOT NULL,
    nome text,
    cpf text,
    rg text,
    sexo text,
    data_nascimento text,
    email text,
    tel_celular text,
    tel_fixo text,
    tel_comercial text,
    cidade text,
    uf text,
    endereco text,
    bairro text,
    cep text,
    escola_nome text,
    escola_cnpj text,
    tipo_inscricao text,
    cargo text,
    lote text,
    modalidade text,
    data_inscricao text,
    forma_pagamento text,
    status_financeiro text,
    valor_total numeric,
    qtd_alunos_total integer,
    qtd_infantil integer,
    qtd_fund1 integer,
    qtd_fund2 integer,
    qtd_medio integer,
    dados_extras jsonb,
    importado_em timestamptz DEFAULT now(),
    importado_por uuid,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.negociacao_comentarios (
    id uuid DEFAULT extensions.uuid_generate_v4(),
    negociacao_id uuid NOT NULL,
    autor_id uuid NOT NULL,
    texto text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.negociacao_membros (
    id uuid DEFAULT extensions.uuid_generate_v4(),
    negociacao_id uuid NOT NULL,
    profile_id uuid NOT NULL,
    added_by uuid,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.negociacoes (
    id uuid DEFAULT gen_random_uuid(),
    escola_id uuid NOT NULL,
    titulo text,
    stage text DEFAULT 'prospeccao',
    responsavel_id uuid,
    valor_estimado numeric,
    probabilidade smallint DEFAULT 0,
    previsao_fechamento date,
    motivo_perda text,
    ativa boolean DEFAULT true,
    observacoes text,
    created_by uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    tags text NOT NULL,
    descricao text,
    due_date timestamptz,
    due_alerta_min integer,
    checklist jsonb NOT NULL,
    agenda_evento_id uuid,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.notas_escola (
    id uuid DEFAULT gen_random_uuid(),
    escola_id uuid NOT NULL,
    texto text NOT NULL,
    fixada boolean DEFAULT false,
    created_by uuid,
    created_at timestamptz DEFAULT now(),
    categoria text DEFAULT 'contato',
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.registros (
    id uuid DEFAULT gen_random_uuid(),
    escola_id uuid NOT NULL,
    negociacao_id uuid,
    data_contato date DEFAULT CURRENT_DATE,
    hora_contato text,
    meio_contato meio_contato DEFAULT 'whatsapp',
    resumo text NOT NULL,
    responsavel_id uuid,
    contato_nome text,
    contato_cargo text,
    interesse nivel_interesse DEFAULT 'medio',
    prontidao prontidao_negociacao DEFAULT 'esperando_retorno',
    abertura abertura_propostal DEFAULT 'media',
    encaminhamentos text NOT NULL,
    qtd_infantil integer DEFAULT 0,
    qtd_fund1 integer DEFAULT 0,
    qtd_fund2 integer DEFAULT 0,
    qtd_medio integer DEFAULT 0,
    potencial_financeiro integer DEFAULT 0,
    probabilidade smallint DEFAULT 0,
    classificacao classificacao_lead DEFAULT 'frio',
    proximo_contato date,
    notas_internas text,
    created_by uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.tarefas (
    id uuid DEFAULT gen_random_uuid(),
    escola_id uuid NOT NULL,
    negociacao_id uuid,
    titulo text NOT NULL,
    descricao text,
    responsavel_id uuid,
    vencimento date,
    prioridade tarefa_prioridade DEFAULT 'media',
    status tarefa_status DEFAULT 'pendente',
    concluida_em timestamptz,
    created_by uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.transcricoes_reunioes (
    id uuid DEFAULT gen_random_uuid(),
    escola_id uuid NOT NULL,
    data_reuniao date NOT NULL,
    titulo text,
    participantes text,
    plataforma text DEFAULT 'meet',
    transcricao text,
    resumo_ia text,
    arquivo_transcricao_path text,
    arquivo_transcricao_nome text,
    arquivo_transcricao_size integer,
    arquivo_midia_path text,
    arquivo_midia_nome text,
    arquivo_midia_size integer,
    arquivo_midia_tipo text,
    created_by uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.usuario_escolas_pipeline (
    id uuid DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    escola_id uuid NOT NULL,
    stage text DEFAULT 'prospeccao',
    tags text NOT NULL,
    nota text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.usuarios (
    id uuid NOT NULL,
    email text NOT NULL,
    nome_completo text,
    foto_perfil text,
    empresa_id uuid,
    escola_id uuid,
    departamento text,
    cargo text,
    ativo boolean DEFAULT true,
    role text DEFAULT 'usuario',
    permissoes jsonb,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    last_login timestamptz,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid NOT NULL,
    email text NOT NULL,
    full_name text NOT NULL,
    role user_role DEFAULT 'consultor',
    phone text,
    region text,
    avatar_url text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (id)
);

-- Chaves estrangeiras (depois de TODAS as tabelas existirem)
DO $$ BEGIN
  ALTER TABLE public.agenda_eventos ADD CONSTRAINT fk_agenda_eventos_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.agenda_eventos ADD CONSTRAINT fk_agenda_eventos_criado_por FOREIGN KEY (criado_por) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.agenda_participantes ADD CONSTRAINT fk_agenda_participantes_evento_id FOREIGN KEY (evento_id) REFERENCES public.agenda_eventos(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.agenda_participantes ADD CONSTRAINT fk_agenda_participantes_profile_id FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.audit_log ADD CONSTRAINT fk_audit_log_user_id FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.ciecc_inscritos ADD CONSTRAINT fk_ciecc_inscritos_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.contratos ADD CONSTRAINT fk_contratos_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.contratos ADD CONSTRAINT fk_contratos_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.contratos_arquivos ADD CONSTRAINT fk_contratos_arquivos_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.contratos_arquivos ADD CONSTRAINT fk_contratos_arquivos_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.documentos_oficiais ADD CONSTRAINT fk_documentos_oficiais_atualizado_por FOREIGN KEY (atualizado_por) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.escolas ADD CONSTRAINT fk_escolas_responsavel_id FOREIGN KEY (responsavel_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.escolas ADD CONSTRAINT fk_escolas_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.escolas ADD CONSTRAINT fk_escolas_updated_by FOREIGN KEY (updated_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.leads_contato_escola ADD CONSTRAINT fk_leads_contato_escola_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.leads_participacao ADD CONSTRAINT fk_leads_participacao_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.leads_perfil_escola ADD CONSTRAINT fk_leads_perfil_escola_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.leads_pessoa ADD CONSTRAINT fk_leads_pessoa_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.leads_pessoa ADD CONSTRAINT fk_leads_pessoa_profile_id FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.negociacao_comentarios ADD CONSTRAINT fk_negociacao_comentarios_negociacao_id FOREIGN KEY (negociacao_id) REFERENCES public.negociacoes(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.negociacao_comentarios ADD CONSTRAINT fk_negociacao_comentarios_autor_id FOREIGN KEY (autor_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.negociacao_membros ADD CONSTRAINT fk_negociacao_membros_negociacao_id FOREIGN KEY (negociacao_id) REFERENCES public.negociacoes(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.negociacao_membros ADD CONSTRAINT fk_negociacao_membros_profile_id FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.negociacoes ADD CONSTRAINT fk_negociacoes_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.negociacoes ADD CONSTRAINT fk_negociacoes_responsavel_id FOREIGN KEY (responsavel_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.negociacoes ADD CONSTRAINT fk_negociacoes_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.negociacoes ADD CONSTRAINT fk_negociacoes_agenda_evento_id FOREIGN KEY (agenda_evento_id) REFERENCES public.agenda_eventos(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.notas_escola ADD CONSTRAINT fk_notas_escola_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.notas_escola ADD CONSTRAINT fk_notas_escola_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.registros ADD CONSTRAINT fk_registros_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.registros ADD CONSTRAINT fk_registros_negociacao_id FOREIGN KEY (negociacao_id) REFERENCES public.negociacoes(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.registros ADD CONSTRAINT fk_registros_responsavel_id FOREIGN KEY (responsavel_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.registros ADD CONSTRAINT fk_registros_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.tarefas ADD CONSTRAINT fk_tarefas_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.tarefas ADD CONSTRAINT fk_tarefas_negociacao_id FOREIGN KEY (negociacao_id) REFERENCES public.negociacoes(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.tarefas ADD CONSTRAINT fk_tarefas_responsavel_id FOREIGN KEY (responsavel_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.tarefas ADD CONSTRAINT fk_tarefas_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.transcricoes_reunioes ADD CONSTRAINT fk_transcricoes_reunioes_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.transcricoes_reunioes ADD CONSTRAINT fk_transcricoes_reunioes_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.usuario_escolas_pipeline ADD CONSTRAINT fk_usuario_escolas_pipeline_user_id FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.usuario_escolas_pipeline ADD CONSTRAINT fk_usuario_escolas_pipeline_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.usuarios ADD CONSTRAINT fk_usuarios_escola_id FOREIGN KEY (escola_id) REFERENCES public.escolas(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Função helper de RLS — precisa existir ANTES de qualquer CREATE POLICY
-- que a use (a primeira é em add_alunos_historico.sql, logo depois de
-- propostas.sql) e DEPOIS da tabela public.usuarios (functions LANGUAGE sql
-- são resolvidas contra o schema já na criação, não só na primeira
-- chamada — por isso não pode ficar antes das tabelas existirem).
CREATE OR REPLACE FUNCTION public.is_gerente_or_supervisor()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid() AND role IN ('gerente','supervisor') AND ativo = true
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_gerente_or_supervisor() TO authenticated, anon;


-- ================================================================
-- ARQUIVO: propostas.sql
-- ================================================================
-- =============================================================
-- propostas table — We Make comercial app
-- =============================================================

CREATE TABLE IF NOT EXISTS propostas (
  id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  token                 UUID          UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  escola_id             UUID          REFERENCES escolas(id) ON DELETE SET NULL,
  escola_nome           TEXT          NOT NULL,
  escola_logo_url       TEXT,
  escola_email          TEXT,
  escola_pin            TEXT          NOT NULL DEFAULT LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0'),
  tipo                  TEXT          NOT NULL DEFAULT 'curriculo'
                                        CHECK (tipo IN ('curriculo', 'curriculo_comodato')),
  validade              DATE          NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
  num_alunos            INTEGER       NOT NULL DEFAULT 100,
  segmentos             INTEGER       NOT NULL DEFAULT 2,
  valor_aluno_ano       NUMERIC(10,2) NOT NULL DEFAULT 0,
  num_parcelas          INTEGER       NOT NULL DEFAULT 12,
  duracao_meses         INTEGER       NOT NULL DEFAULT 48,
  comodato_pv           NUMERIC(12,2),
  comodato_parcela      NUMERIC(10,2),
  comodato_retorno_pct  NUMERIC(6,2),
  comodato_tx_rate      NUMERIC(5,4),
  comodato_notebooks    INTEGER,
  dados_calculo         JSONB,
  texto_personalizado   TEXT,
  status                TEXT          NOT NULL DEFAULT 'ativa'
                                        CHECK (status IN ('ativa', 'expirada', 'aceita', 'recusada')),
  criado_por            UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  visualizacoes         INTEGER       NOT NULL DEFAULT 0,
  visualizado_em        TIMESTAMPTZ
);

-- -----------------------------------------------------------------
-- Row Level Security
-- -----------------------------------------------------------------

ALTER TABLE propostas ENABLE ROW LEVEL SECURITY;

-- Authenticated users (team) can do everything
CREATE POLICY "authenticated manage propostas"
  ON propostas
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Anonymous users (schools, external viewers) can read by token
CREATE POLICY "anon read propostas by token"
  ON propostas
  FOR SELECT
  TO anon
  USING (true);

-- -----------------------------------------------------------------
-- updated_at trigger
-- -----------------------------------------------------------------

CREATE OR REPLACE FUNCTION propostas_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_propostas_updated_at ON propostas;
CREATE TRIGGER trg_propostas_updated_at
  BEFORE UPDATE ON propostas
  FOR EACH ROW
  EXECUTE FUNCTION propostas_set_updated_at();

-- -----------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_propostas_token ON propostas (token);


-- ================================================================
-- ARQUIVO: add_alunos_historico.sql
-- ================================================================
-- ============================================================
-- alunos_historico — registro append-only do número de alunos ao longo
-- da negociação de cada escola.
--
-- Contexto: o número de alunos de uma escola pode mudar durante a
-- negociação (cadastro inicial → proposta → contrato). Antes disso não
-- havia histórico: cada tabela (escolas, propostas, contratos) só guarda
-- o valor mais recente, sobrescrevendo o anterior. Esta tabela nunca é
-- atualizada, só recebe novas linhas — o valor original do formulário
-- de pré-cadastro fica preservado (populado pelo backfill abaixo) e cada
-- novo número registrado manualmente vira uma linha nova, mantendo a
-- linha do tempo completa.
-- ============================================================

CREATE TABLE IF NOT EXISTS alunos_historico (
  id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  escola_id      UUID          NOT NULL REFERENCES escolas(id) ON DELETE CASCADE,
  negociacao_id  UUID          REFERENCES negociacoes(id) ON DELETE SET NULL,
  valor          INTEGER       NOT NULL CHECK (valor >= 0),
  origem         TEXT          NOT NULL DEFAULT 'manual' CHECK (origem IN ('cadastro', 'proposta', 'manual')),
  observacao     TEXT,
  created_by     UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_alunos_historico_escola
  ON alunos_historico (escola_id, created_at DESC);

ALTER TABLE alunos_historico ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS alunos_historico_select ON public.alunos_historico;
DROP POLICY IF EXISTS alunos_historico_insert ON public.alunos_historico;

-- Mesma lógica de visibilidade de registros/negociações: gerente/supervisor
-- vê tudo, consultor/assistente vê o que é da escola que ele é responsável
-- ou que ainda não tem dono (pool). Sem UPDATE/DELETE — é um log, não se edita.
CREATE POLICY alunos_historico_select
  ON public.alunos_historico FOR SELECT
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = alunos_historico.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY alunos_historico_insert
  ON public.alunos_historico FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = alunos_historico.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

-- ─── Backfill: preserva o número original (cadastro) de cada escola já
-- existente como a primeira linha do histórico, na data de criação da
-- escola — só roda pra escola que ainda não tem nenhuma linha, então é
-- seguro rodar este arquivo de novo sem duplicar.
INSERT INTO alunos_historico (escola_id, valor, origem, created_at)
SELECT e.id, e.total_alunos, 'cadastro', e.created_at
FROM escolas e
WHERE e.total_alunos IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM alunos_historico h WHERE h.escola_id = e.id
  );


-- ================================================================
-- ARQUIVO: add_arquivada_em_propostas.sql
-- ================================================================
-- =============================================================
-- propostas — adiciona arquivamento (soft delete)
-- (null = ativa/visível na listagem; preenchido = arquivada, some
--  da listagem padrão mas continua no banco para histórico/auditoria)
-- =============================================================

ALTER TABLE propostas
  ADD COLUMN IF NOT EXISTS arquivada_em TIMESTAMPTZ;


-- ================================================================
-- ARQUIVO: add_valor_comodato_propostas.sql
-- ================================================================
-- =============================================================
-- propostas — adiciona valor por aluno/ano do cenário Currículo + Comodato
-- (antes esse número era só derivado da parcela do comodato ÷ alunos;
--  agora é um valor editável na calculadora, para que "Somente Currículo"
--  e "Currículo + Comodato" apareçam lado a lado na proposta)
-- =============================================================

ALTER TABLE propostas
  ADD COLUMN IF NOT EXISTS valor_aluno_ano_comodato NUMERIC(10,2);


-- ================================================================
-- ARQUIVO: add_fund2_medio_contratos.sql
-- ================================================================
-- =============================================================
-- contratos — adiciona segmentos Fundamental II e Ensino Médio
-- (hoje só existem Infantil 2-5 e Fund I 1º-5º ano; escolas com
--  Fund II/Médio não tinham como ter esses segmentos precificados
--  no contrato, embora já sejam capturados no cadastro da escola)
-- =============================================================

ALTER TABLE contratos
  ADD COLUMN IF NOT EXISTS fund2_ano6_qtd    INTEGER       NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano6_valor  NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano7_qtd    INTEGER       NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano7_valor  NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano8_qtd    INTEGER       NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano8_valor  NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano9_qtd    INTEGER       NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano9_valor  NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medio_1s_qtd      INTEGER       NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medio_1s_valor    NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medio_2s_qtd      INTEGER       NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medio_2s_valor    NUMERIC(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medio_3s_qtd      INTEGER       NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medio_3s_valor    NUMERIC(10,2) NOT NULL DEFAULT 0;

-- Nota: o valor total do contrato passa a ser calculado no código da
-- aplicação (src/app/(dashboard)/comercial/contratos/page.tsx), somando
-- qtd*valor de todos os 16 segmentos — não depende de `valor_total` /
-- `valor_total_calculado`, cuja definição original não está disponível
-- neste repositório para ser estendida com segurança.


-- ================================================================
-- ARQUIVO: add_funil_contratacao.sql
-- ================================================================
-- =============================================================
-- Funil de Contratação — fase de implantação
-- Inicia quando o contrato é arquivado (contrato_arquivado = true).
-- A regra de auto-início fica em código (upsertContrato, src/lib/actions.ts):
-- ao arquivar o contrato, implantacao_status vira 'em_andamento'
-- automaticamente, salvo quando o formulário já envia um status explícito.
-- =============================================================

ALTER TABLE contratos
  ADD COLUMN IF NOT EXISTS implantacao_status TEXT
    CHECK (implantacao_status IN ('nao_iniciada','em_andamento','concluida'))
    DEFAULT 'nao_iniciada',
  ADD COLUMN IF NOT EXISTS implantacao_iniciada_em  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS implantacao_concluida_em TIMESTAMPTZ;

-- Garante o default explícito em linhas já existentes (colunas adicionadas
-- depois do INSERT original ficam NULL, não no valor DEFAULT).
UPDATE contratos SET implantacao_status = 'nao_iniciada' WHERE implantacao_status IS NULL;


-- ================================================================
-- ARQUIVO: add_form_precadastro_granular.sql
-- ================================================================
-- =============================================================
-- form_precadastro_wemake — séries granulares + site/telefone +
-- endereço de entrega do material didático
--
-- Substitui a lógica de "quantidade agregada por segmento" (4
-- números) por uma grade granular por série (14 séries: Infantil
-- 4-5, Fund I 1º-5º, Fund II 6º-9º, Médio 1ª-3ª). As colunas
-- agregadas (alunos_infantil, alunos_fundamental_1/2,
-- alunos_ensino_medio) continuam existindo — passam a ser
-- preenchidas automaticamente como soma das séries (ver
-- enviarFormularioPublico em src/lib/actions.ts), para não quebrar
-- o espelhamento em leads_universal que já depende delas.
-- =============================================================

ALTER TABLE form_precadastro_wemake
  ADD COLUMN IF NOT EXISTS site TEXT,
  ADD COLUMN IF NOT EXISTS telefone_institucional TEXT,

  -- Endereço de entrega do material didático (Anexo III do contrato)
  ADD COLUMN IF NOT EXISTS entrega_mesmo_endereco BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS entrega_rua TEXT,
  ADD COLUMN IF NOT EXISTS entrega_numero TEXT,
  ADD COLUMN IF NOT EXISTS entrega_complemento TEXT,
  ADD COLUMN IF NOT EXISTS entrega_bairro TEXT,
  ADD COLUMN IF NOT EXISTS entrega_cep TEXT,
  ADD COLUMN IF NOT EXISTS entrega_cidade TEXT,
  ADD COLUMN IF NOT EXISTS entrega_estado TEXT,

  -- Séries granulares (Anexo II — quantidade mínima de alunos por série)
  ADD COLUMN IF NOT EXISTS infantil4_qtd  INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS infantil5_qtd  INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund1_ano1_qtd INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund1_ano2_qtd INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund1_ano3_qtd INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund1_ano4_qtd INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund1_ano5_qtd INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano6_qtd INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano7_qtd INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano8_qtd INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fund2_ano9_qtd INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medio_1s_qtd   INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medio_2s_qtd   INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS medio_3s_qtd   INTEGER DEFAULT 0;


-- ================================================================
-- ARQUIVO: add_num_parcelas_curriculo.sql
-- ================================================================
-- Proposta com comodato mostra 2 modelos lado a lado (Somente Currículo vs
-- Currículo + Comodato) no mesmo documento. `num_parcelas` ficou dedicado ao
-- parcelamento do comodato (sempre 12x, mensal -- regra de negócio). Falta um
-- campo próprio para o parcelamento do lado "Somente Currículo" dentro dessa
-- mesma proposta (padrão: 5x), que hoje reusa `num_parcelas` incorretamente
-- e mostra 12x nos dois lados.
ALTER TABLE propostas
  ADD COLUMN IF NOT EXISTS num_parcelas_curriculo INTEGER DEFAULT 5;


-- ================================================================
-- ARQUIVO: add_declinou_e_prioridade.sql
-- ================================================================
-- Adiciona:
-- 1) contratos.declinou — a escola recusou a proposta (checklist do Funil de Contratação)
-- 2) escolas.prioridade_manual — ordem de priorização definida manualmente pelo time comercial
--    (menor número = maior prioridade; NULL = sem prioridade definida, fica por último)

ALTER TABLE contratos
  ADD COLUMN IF NOT EXISTS declinou BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS proposta_enviada BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE escolas
  ADD COLUMN IF NOT EXISTS prioridade_manual INTEGER NULL;


-- ================================================================
-- ARQUIVO: add_categoria_contratos_arquivos.sql
-- ================================================================
-- Adiciona uma categoria aos arquivos anexados em contratos_arquivos, pra
-- diferenciar o PDF da proposta comercial (anexado manualmente quando a
-- escola não tem proposta gerada pela Calculadora) dos demais documentos do
-- contrato já suportados hoje (minuta, contrato assinado etc.).
-- Linhas existentes continuam classificadas como 'contrato' (comportamento
-- inalterado); só uploads novos feitos pelo botão de anexar proposta usam
-- categoria = 'proposta'.

ALTER TABLE contratos_arquivos
  ADD COLUMN IF NOT EXISTS categoria TEXT NOT NULL DEFAULT 'contrato';

-- O bucket "documentos-oficiais" (usado por ContratoUpload.tsx e agora
-- também por AnexarPropostaPdf.tsx) nunca foi criado em produção — por isso
-- contratos_arquivos está vazia até hoje, o upload de contrato nunca
-- funcionou de fato. Cria o bucket público, com o mesmo limite de 20MB já
-- validado no client, aceitando PDF/Word/imagem.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documentos-oficiais',
  'documentos-oficiais',
  true,
  20971520,
  ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'image/png', 'image/jpeg']
)
ON CONFLICT (id) DO NOTHING;

-- Policies mínimas: qualquer usuário autenticado pode enviar/ler/remover
-- arquivos neste bucket (mesmo padrão de acesso já usado nas tabelas do
-- funil — controle é por papel dentro do app, não por policy de storage
-- granular por escola).
DROP POLICY IF EXISTS "documentos-oficiais: authenticated select" ON storage.objects;
CREATE POLICY "documentos-oficiais: authenticated select"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'documentos-oficiais' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "documentos-oficiais: authenticated insert" ON storage.objects;
CREATE POLICY "documentos-oficiais: authenticated insert"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'documentos-oficiais' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "documentos-oficiais: authenticated delete" ON storage.objects;
CREATE POLICY "documentos-oficiais: authenticated delete"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'documentos-oficiais' AND auth.uid() IS NOT NULL);

-- contratos_arquivos também nunca teve policy de INSERT liberada pro client
-- comum (confirmado: 42501 row-level security policy) — é por isso que a
-- tabela está vazia até hoje, apesar do upload em ContratoUpload.tsx já
-- existir. SELECT já funciona (RLS permite), só faltava o INSERT.
DROP POLICY IF EXISTS "contratos_arquivos: authenticated insert" ON contratos_arquivos;
CREATE POLICY "contratos_arquivos: authenticated insert"
  ON contratos_arquivos FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);


-- ================================================================
-- ARQUIVO: add_categoria_notas_escola.sql
-- ================================================================
-- Separa as anotações rápidas de contato comercial (já existentes, feitas
-- pelo popover no Funil de Contratação) dos novos comentários sobre o
-- processo de negociação do contrato (novo painel de Minuta/Contrato) —
-- sem isso os dois tipos apareceriam misturados na mesma lista em ambos os
-- lugares. Notas já existentes continuam classificadas como 'contato'
-- (comportamento inalterado).
ALTER TABLE notas_escola
  ADD COLUMN IF NOT EXISTS categoria TEXT NOT NULL DEFAULT 'contato';


-- ================================================================
-- ARQUIVO: add_livro_impresso.sql
-- ================================================================
-- Adiciona contratos.livro_impresso — tag que identifica se a escola quer o
-- livro impresso (usada na tela "Quantidade de Alunos" pra compor a tabela
-- de pedido pra gráfica, com a distribuição de alunos por série/turma).

ALTER TABLE contratos
  ADD COLUMN IF NOT EXISTS livro_impresso BOOLEAN NOT NULL DEFAULT false;


-- ================================================================
-- ARQUIVO: add_contrato_marcado_veterana.sql
-- ================================================================
-- Marca explicitamente quando uma escola foi adicionada à tela "Quantidade
-- de Alunos" como veterana (planilha do Dênis / adição manual), em vez de
-- inferir isso de contrato_assinado — que também é usado por escolas novas
-- que fecharam contrato de verdade pelo funil 2027.
ALTER TABLE contratos
  ADD COLUMN IF NOT EXISTS marcado_veterana BOOLEAN NOT NULL DEFAULT false;


-- ================================================================
-- ARQUIVO: add_contrato_livro_qtds.sql
-- ================================================================
-- Quantidade de livros por série é independente da quantidade de alunos do
-- contrato: ao marcar a tag "Livro" a escola entra na tabela da gráfica com
-- uma cópia dos números do contrato, mas dali em diante pode ser ajustada
-- separadamente sem alterar o contrato (que continua empurrando mudanças
-- pra cá sempre que editado, a menos que a gráfica seja ajustada por conta).
ALTER TABLE contratos
  ADD COLUMN IF NOT EXISTS livro_qtds JSONB NOT NULL DEFAULT '{}'::jsonb;


-- ================================================================
-- ARQUIVO: aplicar_rls.sql
-- ================================================================
-- ============================================================
-- RLS — Políticas de segurança do CRM
--
-- Modelo:
--   Gerente/supervisor   → vê e edita tudo
--   Consultor/Assistente → vê escolas onde é responsavel_id OU sem dono (pool)
--                          vê registros/negociações/contratos da escola que pode ver
--   Leads_universal      → todos autenticados (free pool)
--   Profiles             → todos autenticados leem; usuário edita o próprio
--   Audit_log            → só gerente/supervisor
--   Agenda               → criador + participantes
--
-- IMPORTANTE: as policies não bloqueiam o service_role (admin no servidor).
-- ============================================================

-- ─── 1) FUNÇÃO HELPER ─────────────────────────────────────────────────
-- Definida em 000_schema_base.sql (precisa existir antes de qualquer
-- CREATE POLICY no script, inclusive as de add_alunos_historico.sql).
-- Nada a fazer aqui além de garantir que está com a versão certa.
CREATE OR REPLACE FUNCTION public.is_gerente_or_supervisor()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE id = auth.uid() AND role IN ('gerente','supervisor') AND ativo = true
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_gerente_or_supervisor() TO authenticated, anon;

-- ─── 2) DROPA TODAS AS POLICIES ANTIGAS (para re-rodar idempotente) ───
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('profiles','escolas','registros','negociacoes','contratos',
                        'formularios','leads_universal','agenda_eventos',
                        'agenda_participantes','audit_log')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I',
                   r.policyname, r.schemaname, r.tablename);
  END LOOP;
END$$;

-- ============================================================
-- PROFILES
-- Todos autenticados leem (necessário para JOIN de responsavel_nome).
-- Usuário pode editar o próprio. Gerente pode editar qualquer um.
-- ============================================================
CREATE POLICY profiles_select_all
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY profiles_update_own_or_admin
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid() OR public.is_gerente_or_supervisor())
  WITH CHECK (id = auth.uid() OR public.is_gerente_or_supervisor());

CREATE POLICY profiles_insert_admin
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (public.is_gerente_or_supervisor());

CREATE POLICY profiles_delete_admin
  ON public.profiles FOR DELETE
  TO authenticated
  USING (public.is_gerente_or_supervisor());

-- ============================================================
-- ESCOLAS
-- Gerente/supervisor: tudo
-- Consultor: vê onde é responsável OU responsavel_id IS NULL (pool)
-- Consultor pode INSERIR (precisa) e UPDATE só onde é responsável
-- Apenas gerente DELETA
-- ============================================================
CREATE POLICY escolas_select
  ON public.escolas FOR SELECT
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR responsavel_id = auth.uid()
    OR responsavel_id IS NULL
  );

CREATE POLICY escolas_insert
  ON public.escolas FOR INSERT
  TO authenticated
  WITH CHECK (true);  -- qualquer autenticado pode cadastrar

CREATE POLICY escolas_update
  ON public.escolas FOR UPDATE
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR responsavel_id = auth.uid()
    OR responsavel_id IS NULL
  )
  WITH CHECK (
    public.is_gerente_or_supervisor()
    OR responsavel_id = auth.uid()
    OR responsavel_id IS NULL
  );

CREATE POLICY escolas_delete
  ON public.escolas FOR DELETE
  TO authenticated
  USING (public.is_gerente_or_supervisor());

-- ============================================================
-- REGISTROS — herda visibilidade da escola
-- ============================================================
CREATE POLICY registros_select
  ON public.registros FOR SELECT
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = registros.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY registros_insert
  ON public.registros FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = registros.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY registros_update
  ON public.registros FOR UPDATE
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = registros.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY registros_delete
  ON public.registros FOR DELETE
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = registros.escola_id AND e.responsavel_id = auth.uid()
    )
  );

-- ============================================================
-- NEGOCIACOES — mesma lógica
-- ============================================================
CREATE POLICY negociacoes_select
  ON public.negociacoes FOR SELECT
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = negociacoes.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY negociacoes_insert
  ON public.negociacoes FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = negociacoes.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY negociacoes_update
  ON public.negociacoes FOR UPDATE
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = negociacoes.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY negociacoes_delete
  ON public.negociacoes FOR DELETE
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = negociacoes.escola_id AND e.responsavel_id = auth.uid()
    )
  );

-- ============================================================
-- CONTRATOS — mesma lógica
-- ============================================================
CREATE POLICY contratos_select
  ON public.contratos FOR SELECT
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = contratos.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY contratos_insert
  ON public.contratos FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = contratos.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY contratos_update
  ON public.contratos FOR UPDATE
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.escolas e
      WHERE e.id = contratos.escola_id
        AND (e.responsavel_id = auth.uid() OR e.responsavel_id IS NULL)
    )
  );

CREATE POLICY contratos_delete
  ON public.contratos FOR DELETE
  TO authenticated
  USING (public.is_gerente_or_supervisor());

-- ============================================================
-- FORMULARIOS — não tem escola_id (são pré-cadastros).
-- Todos autenticados leem; só gerente edita/deleta.
-- ============================================================
CREATE POLICY formularios_select
  ON public.formularios FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY formularios_insert_public
  ON public.formularios FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);  -- formulário público pode submeter

CREATE POLICY formularios_update_admin
  ON public.formularios FOR UPDATE
  TO authenticated
  USING (public.is_gerente_or_supervisor());

CREATE POLICY formularios_delete_admin
  ON public.formularios FOR DELETE
  TO authenticated
  USING (public.is_gerente_or_supervisor());

-- ============================================================
-- LEADS_UNIVERSAL — pool aberto (todos veem/mexem; só gerente deleta)
-- ============================================================
CREATE POLICY leads_select
  ON public.leads_universal FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY leads_insert
  ON public.leads_universal FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY leads_update
  ON public.leads_universal FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY leads_delete_admin
  ON public.leads_universal FOR DELETE
  TO authenticated
  USING (public.is_gerente_or_supervisor());

-- ============================================================
-- AGENDA_EVENTOS — criador + participantes veem; criador edita
-- ============================================================
CREATE POLICY agenda_eventos_select
  ON public.agenda_eventos FOR SELECT
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR criado_por = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.agenda_participantes ap
      WHERE ap.evento_id = agenda_eventos.id AND ap.profile_id = auth.uid()
    )
  );

CREATE POLICY agenda_eventos_insert
  ON public.agenda_eventos FOR INSERT
  TO authenticated
  WITH CHECK (criado_por = auth.uid());

CREATE POLICY agenda_eventos_update
  ON public.agenda_eventos FOR UPDATE
  TO authenticated
  USING (criado_por = auth.uid() OR public.is_gerente_or_supervisor());

CREATE POLICY agenda_eventos_delete
  ON public.agenda_eventos FOR DELETE
  TO authenticated
  USING (criado_por = auth.uid() OR public.is_gerente_or_supervisor());

-- ============================================================
-- AGENDA_PARTICIPANTES — quem está no evento vê; criador do evento edita
-- ============================================================
CREATE POLICY agenda_participantes_select
  ON public.agenda_participantes FOR SELECT
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR profile_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.agenda_eventos e
      WHERE e.id = agenda_participantes.evento_id AND e.criado_por = auth.uid()
    )
  );

CREATE POLICY agenda_participantes_insert
  ON public.agenda_participantes FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.agenda_eventos e
      WHERE e.id = agenda_participantes.evento_id AND e.criado_por = auth.uid()
    )
  );

CREATE POLICY agenda_participantes_update
  ON public.agenda_participantes FOR UPDATE
  TO authenticated
  USING (
    profile_id = auth.uid()  -- próprio participante pode mudar status
    OR public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.agenda_eventos e
      WHERE e.id = agenda_participantes.evento_id AND e.criado_por = auth.uid()
    )
  );

CREATE POLICY agenda_participantes_delete
  ON public.agenda_participantes FOR DELETE
  TO authenticated
  USING (
    public.is_gerente_or_supervisor()
    OR EXISTS (
      SELECT 1 FROM public.agenda_eventos e
      WHERE e.id = agenda_participantes.evento_id AND e.criado_por = auth.uid()
    )
  );

-- ============================================================
-- AUDIT_LOG — só gerente/supervisor lê. Insert via trigger (service_role).
-- ============================================================
CREATE POLICY audit_log_select_admin
  ON public.audit_log FOR SELECT
  TO authenticated
  USING (public.is_gerente_or_supervisor());

-- (sem policy de INSERT/UPDATE/DELETE → ninguém via API consegue mexer.
--  Apenas o service_role conseguirá, o que é o esperado.)

-- ============================================================
-- Recarrega cache do PostgREST
-- ============================================================
NOTIFY pgrst, 'reload schema';


-- ================================================================
-- ARQUIVO: fix_is_gerente_or_supervisor.sql
-- ================================================================
-- A definição correta de is_gerente_or_supervisor() (consultando `usuarios`,
-- não a `profiles` legada) foi movida para 000_schema_base.sql, pois a
-- função precisa existir ANTES de qualquer CREATE POLICY no script —
-- inclusive as de add_alunos_historico.sql, que roda logo após propostas.sql
-- e muito antes de aplicar_rls.sql. Este arquivo fica só como marcador de
-- histórico; nada a executar.


-- ================================================================
-- ARQUIVO: add_view_escolas_resumo.sql
-- ================================================================
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

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
             WHERE n.nspname = 'public' AND c.relname = 'escolas_resumo' AND c.relkind = 'v') THEN
    DROP VIEW public.escolas_resumo;
  ELSIF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE n.nspname = 'public' AND c.relname = 'escolas_resumo' AND c.relkind = 'r') THEN
    DROP TABLE public.escolas_resumo;
  END IF;
END $$;

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



-- ================================================================
-- ARQUIVO: add_metas_comerciais.sql
-- ================================================================
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


-- ================================================================
-- ARQUIVO: add_catalogo_livros_e_series.sql
-- ================================================================
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


-- ================================================================
-- ARQUIVO: add_custo_venda_e_demanda_2027.sql
-- ================================================================
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

DROP VIEW IF EXISTS public.produtos_livros_demanda;
CREATE VIEW public.produtos_livros_demanda WITH (security_invoker = true) AS
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


-- ================================================================
-- ARQUIVO: fix_agenda_rls_recursao.sql
-- ================================================================
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


-- Valor de origem usado pelo botao Importar do Banco de Leads.
ALTER TYPE public.origem_lead ADD VALUE IF NOT EXISTS 'banco_leads';


-- ================================================================
-- SEGURANÇA — RLS em todas as tabelas + acesso da equipe logada
-- ================================================================
-- 1) Liga o RLS em toda tabela do schema public que ainda não tem. Sem RLS, a
--    chave pública do site (anon) leria e gravaria direto na tabela. O
--    service_role (servidor do app) ignora o RLS, então nada do back-end muda.
DO $$
DECLARE t RECORD;
BEGIN
  FOR t IN
    SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p') AND NOT c.relrowsecurity
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.relname);
  END LOOP;
END $$;

-- 2) Tabelas que o app lê/grava com o login do usuário e que não têm policy
--    própria nos arquivos acima: a equipe logada (authenticated) acessa; o
--    anônimo continua bloqueado. O controle por papel (gerente, consultor...)
--    é feito dentro do app, o mesmo padrão das demais tabelas.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'tarefas', 'notas_escola', 'transcricoes_reunioes', 'negociacao_membros',
    'negociacao_comentarios', 'contratos_arquivos', 'leads_pessoa',
    'leads_perfil_escola', 'leads_participacao', 'leads_oikos_live',
    'leads_escola', 'leads_contato_escola'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_authenticated_all', t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true)', t || '_authenticated_all', t);
  END LOOP;
END $$;

-- usuarios: o app só LÊ com o login do usuário (nome, cargo); criar, editar e
-- excluir contas é sempre feito pelo servidor (service_role). Por isso só
-- leitura aqui — ninguém consegue mudar o próprio cargo pela API.
DROP POLICY IF EXISTS usuarios_select_authenticated ON public.usuarios;
CREATE POLICY usuarios_select_authenticated ON public.usuarios
  FOR SELECT TO authenticated USING (true);

-- Permissões padrão do Supabase no schema public (as tabelas ficam protegidas
-- pelo RLS ligado acima).
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Pede pra API (PostgREST) do Supabase recarregar o cache de tabelas.
NOTIFY pgrst, 'reload schema';
