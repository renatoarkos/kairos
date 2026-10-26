import os
import sys; sys.path.insert(0, sys.argv[1])
from flow_lib import *
SP = sys.argv[1]
st, us = db('GET', 'usuarios?select=id&email=eq.hugo@kairos.com.br'); hugo = us[0]['id']
st, e = db('POST', 'escolas?select=id', {'nome': 'ZZ QA ESCOLA F4', 'cidade': 'Natal', 'estado': 'RN', 'created_by': hugo, 'responsavel_id': hugo}, {'Prefer': 'return=representation'})
eid = e[0]['id']
f = Flow(); p = f.page
def shot(n):
    try: p.screenshot(path=f'{SP}/fail_{n}.png')
    except Exception: pass
def tenta(nome, fn):
    try: fn()
    except Exception as ex:
        shot(re.sub(r'\W+', '_', nome)[:30]); f.passo(nome, False, 'ERRO: ' + repr(ex)[:230] + ' | url=' + p.url.replace(BASE, ''))
f.login()
try:
    print('\nFLUXO 9 — pipeline CRM (negociação)')
    def f9():
        p.goto(BASE + '/comercial/pipeline'); p.wait_for_load_state('networkidle')
        p.locator('button:has-text("Adicionar Escola ao Pipeline")').first.click(); p.wait_for_timeout(600)
        p.fill('input[placeholder^="Buscar escola"]', 'ZZ QA ESCOLA F4'); p.wait_for_timeout(1500)
        p.locator('text=ZZ QA ESCOLA F4').first.click(); p.wait_for_timeout(300)
        p.locator('input[placeholder="Ex: 15000"]').locator('xpath=ancestor::div[.//input[contains(@placeholder,"Buscar")]][1]').locator('input').nth(1).fill('ZZ negociação QA')
        p.locator('button:has-text("Adicionar ao Pipeline")').first.click(); p.wait_for_timeout(3500)
        st, n = db('GET', f'negociacoes?select=titulo,stage,created_by&escola_id=eq.{eid}')
        f.passo('adicionar escola ao pipeline grava negociação', bool(n) and isinstance(n, list), str(n)[:120])
    tenta('fluxo 9', f9)

    print('\nFLUXO 10 — agenda')
    def f10():
        p.goto(BASE + '/agenda'); p.wait_for_load_state('networkidle')
        p.locator('button:has-text("Novo Evento")').first.click(); p.wait_for_timeout(600)
        p.fill('input[placeholder^="Ex: Reuni"]', 'ZZ evento QA')
        p.locator('button:has-text("Criar Evento")').first.click(); p.wait_for_timeout(4000)
        st, ev = db('GET', 'agenda_eventos?select=titulo,criado_por&titulo=eq.ZZ evento QA')
        f.passo('criar evento na agenda', bool(ev) and isinstance(ev, list), str(ev)[:100] + ' | tela: ' + (f.texto()[:0]))
    tenta('fluxo 10', f10)

    print('\nFLUXO 11 — transcrição de reunião')
    def f11():
        p.goto(BASE + '/transcricoes'); p.wait_for_load_state('networkidle')
        p.locator('button:has-text("Nova Transcrição")').first.click(); p.wait_for_timeout(600)
        p.locator('select').first.select_option(value=eid)
        p.fill('input[type="date"]', '2026-10-20'); p.fill('input[placeholder^="Ex: Apresenta"]', 'ZZ transcrição QA')
        p.fill('textarea', 'Texto de transcrição de teste QA')
        p.locator('button:has-text("Salvar Transcrição")').first.click(); p.wait_for_timeout(4000)
        st, t = db('GET', f'transcricoes_reunioes?select=titulo&escola_id=eq.{eid}')
        f.passo('salvar transcrição grava no banco', bool(t) and isinstance(t, list), str(t)[:100])
    tenta('fluxo 11', f11)

    print('\nFLUXO 12 — formulário público de pré-cadastro (sem login)')
    def f12():
        pub = f.browser.new_context(viewport={'width': 1300, 'height': 900}).new_page(); pub.set_default_timeout(45000)
        pub.goto(BASE + '/formulario'); pub.wait_for_load_state('networkidle')
        valores = {'resp_email': 'zz.qa@exemplo.com', 'cnpj': '11222333000181', 'razao_social': 'ZZ QA RAZAO SOCIAL', 'nome_fantasia': 'ZZ QA FANTASIA',
                   'rua': 'Rua Teste', 'numero': '10', 'bairro': 'Centro', 'cep': '58000000', 'cidade': 'João Pessoa', 'email_institucional': 'zz.qa@exemplo.com',
                   'data_inicio_letivo': '2027-02-01', 'data_fim_letivo': '2027-12-15', 'legal_nome': 'Fulano QA', 'legal_cpf': '52998224725', 'legal_email': 'zz.qa@exemplo.com',
                   'legal_whatsapp': '83999999999', 'legal_rua': 'Rua Teste', 'legal_numero': '10', 'legal_bairro': 'Centro', 'legal_cidade': 'João Pessoa', 'legal_cep': '58000000',
                   'fin_email_cobranca': 'zz.qa@exemplo.com', 'ticket_medio': '500'}
        for nome in pub.eval_on_selector_all('[required]', 'els => els.map(e => e.name)'):
            loc = pub.locator(f'[name="{nome}"]').first
            tag = loc.evaluate('e => e.tagName.toLowerCase()')
            try:
                if tag == 'select':
                    opts = loc.evaluate('e => Array.from(e.options).map(o => o.value).filter(Boolean)'); loc.select_option(opts[0])
                elif nome in valores: loc.fill(valores[nome])
                else: loc.fill('1')
            except Exception: pass
        for nome in ['estado', 'legal_estado']:
            try: pub.select_option(f'select[name="{nome}"]', 'PB')
            except Exception: pass
        pub.locator('button:has-text("Enviar Formulário")').first.click(); pub.wait_for_timeout(7000)
        st, fp = db('GET', 'form_precadastro_wemake?select=id,nome_fantasia,status&razao_social=eq.ZZ QA RAZAO SOCIAL')
        f.passo('enviar formulário público grava o pré-cadastro', bool(fp) and isinstance(fp, list), str(fp)[:110] + ' | url=' + pub.url.replace(BASE, ''))
        st, lu = db('GET', 'leads_universal?select=id,fonte&email=eq.zz.qa@exemplo.com')
        f.passo('formulário também gera o lead (origem do formulário)', bool(lu) and isinstance(lu, list), str(lu)[:100])
        p.goto(BASE + '/comercial/pre-cadastros'); p.wait_for_load_state('networkidle')
        f.passo('pré-cadastro aparece na tela de pré-cadastros', 'ZZ QA FANTASIA' in f.texto() or 'ZZ QA RAZAO' in f.texto())
    tenta('fluxo 12', f12)
    print('\nerros de console/servidor:', f.erros_console[:6] or 'nenhum')
finally:
    db('DELETE', 'form_precadastro_wemake?razao_social=eq.ZZ QA RAZAO SOCIAL'); db('DELETE', 'leads_universal?email=eq.zz.qa@exemplo.com')
    db('DELETE', 'agenda_eventos?titulo=eq.ZZ evento QA')
    for t in ['negociacoes', 'transcricoes_reunioes', 'registros', 'contratos', 'tarefas', 'notas_escola']: db('DELETE', f'{t}?escola_id=eq.{eid}')
    db('DELETE', f'escolas?id=eq.{eid}'); db('DELETE', 'escolas?nome=like.ZZ*'); f.fechar()
