import os
import sys; sys.path.insert(0, sys.argv[1])
from flow_lib import *
import urllib.request as ur
SP = sys.argv[1]
st, us = db('GET', 'usuarios?select=id&email=eq.hugo@kairos.com.br'); hugo = us[0]['id']
st, e = db('POST', 'escolas?select=id', {'nome': 'ZZ QA ESCOLA F5', 'cidade': 'Natal', 'estado': 'RN', 'created_by': hugo, 'responsavel_id': hugo}, {'Prefer': 'return=representation'})
eid = e[0]['id']
pre = {'resp_email': 'zz@exemplo.com', 'razao_social': 'ZZ QA PRE F5', 'nome_fantasia': 'ZZ QA PRE F5', 'rua': 'Rua A', 'numero': '1', 'bairro': 'Centro',
       'cidade': 'Natal', 'estado': 'RN', 'email_institucional': 'zz@exemplo.com', 'legal_nome': 'Fulano', 'legal_email': 'zz@exemplo.com', 'legal_rua': 'Rua A',
       'legal_numero': '1', 'legal_bairro': 'Centro', 'legal_cidade': 'Natal', 'legal_estado': 'RN', 'fin_email_cobranca': 'zz@exemplo.com',
       'alunos_fundamental_1': 120, 'seg_fundamental_1': True, 'fund1_ano1_qtd': 120}
st, pr = db('POST', 'form_precadastro_wemake?select=id', pre, {'Prefer': 'return=representation'})
print('pré-cadastro de teste:', st if st >= 300 else 'ok', pr if st >= 300 else '')
f = Flow(); p = f.page
def shot(n):
    try: p.screenshot(path=f'{SP}/fail_{n}.png')
    except Exception: pass
def tenta(nome, fn):
    try: fn()
    except Exception as ex:
        shot(re.sub(r'\W+', '_', nome)[:30]); f.passo(nome, False, 'ERRO: ' + repr(ex)[:240] + ' | url=' + p.url.replace(BASE, ''))
f.login()
prop_id = None; token = None
try:
    print('\nFLUXO 9 — pipeline CRM (negociação)')
    def f9():
        p.goto(BASE + '/comercial/pipeline'); p.wait_for_load_state('networkidle')
        p.locator('button:has-text("Adicionar Escola ao Pipeline")').first.click(); p.wait_for_timeout(600)
        p.fill('input[placeholder^="Buscar escola"]', 'ZZ QA ESCOLA F5'); p.wait_for_timeout(1800)
        p.locator('text=Natal/RN').first.click(); p.wait_for_timeout(400)
        p.locator('button:has-text("Adicionar ao Pipeline")').first.click(); p.wait_for_timeout(4000)
        st, n = db('GET', f'negociacoes?select=titulo,stage,created_by&escola_id=eq.{eid}')
        f.passo('adicionar escola ao pipeline grava negociação', isinstance(n, list) and len(n) == 1, str(n)[:120])
        p.reload(); p.wait_for_load_state('networkidle')
        f.passo('card da escola aparece no quadro do pipeline', 'ZZ QA ESCOLA F5' in f.texto())
    tenta('fluxo 9', f9)

    print('\nFLUXO 13 — calculadora → proposta')
    def f13():
        p.goto(BASE + '/calculadora'); p.wait_for_load_state('networkidle')
        campo = p.locator('input[placeholder^="— Escolher escola"]').first
        campo.click(); campo.fill('ZZ QA PRE'); p.wait_for_timeout(1500)
        p.locator('text=ZZ QA PRE F5').first.click(); p.wait_for_timeout(1500)
        p.locator('button:has-text("Gerar Proposta")').first.click(); p.wait_for_timeout(1500)
        p.locator('button:has-text("Gerar Proposta")').last.click(); p.wait_for_timeout(7000)
        st, pp = db('GET', 'propostas?select=id,token,escola_nome,escola_pin,status,criado_por&escola_nome=like.ZZ QA*')
        ok = isinstance(pp, list) and len(pp) >= 1
        f.passo('gerar proposta grava no banco', ok, str(pp)[:200])
        if ok:
            global prop_id, token
            prop_id, token = pp[0]['id'], pp[0]['token']
            f.passo('proposta tem criador (criado_por)', bool(pp[0]['criado_por']))
            p.goto(BASE + '/comercial/propostas'); p.wait_for_load_state('networkidle')
            f.passo('proposta aparece na lista de propostas', 'ZZ QA' in f.texto())
            p.goto(BASE + f'/comercial/propostas/{prop_id}/editar'); p.wait_for_load_state('networkidle')
            f.passo('abrir edição da proposta', 'Erro' not in f.texto()[:200] and p.url.endswith('/editar'))
            anon = f.browser.new_context(viewport={'width': 1300, 'height': 900}).new_page(); anon.set_default_timeout(45000)
            anon.goto(BASE + f'/proposta/{token}'); anon.wait_for_load_state('networkidle'); anon.wait_for_timeout(2000)
            t = re.sub(r'\s+', ' ', anon.inner_text('body'))
            f.passo('link público da proposta abre (sem login)', 'This page' not in t and len(t) > 50, t[:110])
            f.passo('link público sem nome de outro sistema', not BAD.search(t))
    tenta('fluxo 13', f13)

    print('\nFLUXO 14 — PDF da proposta')
    def f14():
        if not prop_id: f.passo('PDF da proposta', False, 'sem proposta gerada no passo anterior'); return
        r = p.request.get(BASE + f'/api/propostas/pdf/{prop_id}', timeout=120000)
        ct = r.headers.get('content-type', ''); corpo = r.body()
        f.passo('gerar PDF da proposta', r.status == 200 and 'pdf' in ct and corpo[:4] == b'%PDF', f'HTTP {r.status} | {ct} | {len(corpo)} bytes')
    tenta('fluxo 14', f14)
    print('\nerros de console/servidor:', f.erros_console[:6] or 'nenhum')
finally:
    db('DELETE', 'propostas?escola_nome=like.ZZ QA*'); db('DELETE', 'form_precadastro_wemake?razao_social=like.ZZ QA*')
    db('DELETE', f'negociacoes?escola_id=eq.{eid}'); db('DELETE', f'escolas?id=eq.{eid}'); f.fechar()
