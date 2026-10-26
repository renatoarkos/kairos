import os
import sys; sys.path.insert(0, sys.argv[1])
from flow_lib import *
f = Flow()
print('FLUXO 1 — login + nova escola')
f.passo('login pela tela', f.login())
p = f.page
p.goto(BASE + '/comercial/escolas/nova'); p.wait_for_load_state('networkidle')
p.fill('input[name="nome"]', 'ZZ TESTE QA ESCOLA')
p.fill('input[name="cidade"]', 'João Pessoa'); 
try: p.select_option('select[name="estado"]', 'PB')
except Exception: p.fill('input[name="estado"]', 'PB')
p.click('button[type="submit"]')
try:
    p.wait_for_url(re.compile(r'/comercial/escolas/[0-9a-f-]{36}'), timeout=40000)
    f.passo('cadastrar escola redireciona para a ficha', True, p.url.replace(BASE, ''))
except Exception:
    f.passo('cadastrar escola redireciona para a ficha', False, 'url=' + p.url.replace(BASE, '') + ' | ' + f.texto()[:300])
st, rows = db('GET', 'escolas?select=id,nome,created_by&nome=eq.ZZ TESTE QA ESCOLA')
f.passo('escola gravada no banco', bool(rows) and isinstance(rows, list), str(rows)[:120])
print('erros de console/servidor:', f.erros_console[:5] or 'nenhum')
for r in (rows if isinstance(rows, list) else []): db('DELETE', 'escolas?id=eq.' + r['id'])
f.fechar()
