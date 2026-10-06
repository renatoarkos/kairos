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
  CREATE TYPE public.origem_lead AS ENUM ('feira', 'instagram', 'network', 'site', 'whatsapp', 'email', 'telefone', 'visita', 'evento', 'parceiro', 'outro', 'indicacao_escola', 'abeka', 'acsi', 'congresso_ecc', 'envio_material', 'opening_company');
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

CREATE TABLE IF NOT EXISTS public.escolas_resumo (
    id uuid,
    nome text,
    cnpj text,
    perfil_pedagogico perfil_pedagogico,
    escola_paideia boolean,
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
    qtd_infantil integer,
    qtd_fund1 integer,
    qtd_fund2 integer,
    qtd_medio integer,
    origem_lead origem_lead,
    responsavel_id uuid,
    observacoes text,
    ativa boolean,
    created_by uuid,
    updated_by uuid,
    created_at timestamptz,
    updated_at timestamptz,
    total_alunos integer,
    potencial_financeiro integer,
    qtd_infantil2 integer,
    qtd_infantil3 integer,
    qtd_infantil4 integer,
    qtd_infantil5 integer,
    qtd_fund1_ano1 integer,
    qtd_fund1_ano2 integer,
    qtd_fund1_ano3 integer,
    qtd_fund1_ano4 integer,
    qtd_fund1_ano5 integer,
    qtd_fund2_ano6 integer,
    qtd_fund2_ano7 integer,
    qtd_fund2_ano8 integer,
    qtd_fund2_ano9 integer,
    qtd_medio_1s integer,
    qtd_medio_2s integer,
    qtd_medio_3s integer,
    ultimo_contato date,
    classificacao_atual classificacao_lead,
    probabilidade_atual smallint,
    responsavel_nome text,
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
  ALTER TABLE public.escolas_resumo ADD CONSTRAINT fk_escolas_resumo_responsavel_id FOREIGN KEY (responsavel_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.escolas_resumo ADD CONSTRAINT fk_escolas_resumo_created_by FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE public.escolas_resumo ADD CONSTRAINT fk_escolas_resumo_updated_by FOREIGN KEY (updated_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
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
DROP FUNCTION IF EXISTS public.is_gerente_or_supervisor();

CREATE FUNCTION public.is_gerente_or_supervisor()
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
