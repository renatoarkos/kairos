-- Origem "banco_leads": usada quando uma escola é criada a partir do Banco de
-- Leads (botão "Importar do Banco de Leads" da tela Escolas). Sem esse valor na
-- lista, o banco recusa a gravação com "invalid input value for enum".
ALTER TYPE public.origem_lead ADD VALUE IF NOT EXISTS 'banco_leads';
