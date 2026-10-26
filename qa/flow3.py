import os
import sys; sys.path.insert(0, sys.argv[1])
from flow_lib import *
SP = sys.argv[1]
st, us = db('GET', 'usuarios?select=id&email=eq.hugo@kairos.com.br'); hugo = us[0]['id']
st, e = db('POST', 'escolas?select=id', {'nome': 'ZZ QA ESCOLA F3', 'cidade': 'Natal', 'estado': 'RN', 'created_by': hugo, 'responsavel_id': hugo}, {'Prefer': 'return=representation'})
eid = e[0]['id']
db('POST', 'contratos', {'escola_id': eid, 'minuta_enviada': True, 'created_by': hugo, 'livro_qtds': {}})
f = Flow(); p = f.page
def shot(n):
    try: p.screenshot(path=f'{SP}/fail_{n}.png')
    except Exception: pass
def tenta(nome, fn):
    try: fn()
    except Exception as ex:
        shot(re.sub(r'\W+', '_', nome)[:30]); f.passo(nome, False, 'ERRO: ' + repr(ex)[:200] + ' | url=' + p.url.replace(BASE, ''))
f.login()
usuario_criado = None
try:
    print('\nFLUXO 6 — Quantidade de Alunos')
    def f6():
        p.goto(BASE + '/comercial/quantidade-alunos'); p.wait_for_load_state('networkidle')
        linha = p.locator('tr:has(input[value="ZZ QA ESCOLA F3"])')
        f.passo('escola com minuta aparece em Negociação 2027', linha.count() == 1)
        num = linha.locator('input[type="number"]').first
        num.fill('25'); num.blur(); p.wait_for_timeout(2500)
        st, c = db('GET', f'contratos?select=infantil2_qtd&escola_id=eq.{eid}')
        f.passo('editar quantidade por série grava no contrato', c[0]['infantil2_qtd'] == 25, str(c))
        cb = linha.locator('input[type="checkbox"]').first
        cb.check(); p.wait_for_timeout(2500)
        st, c = db('GET', f'contratos?select=livro_impresso&escola_id=eq.{eid}')
        f.passo('marcar "Livro" grava livro_impresso', c[0]['livro_impresso'] is True, str(c))
    tenta('fluxo 6', f6)

    print('\nFLUXO 7 — ficha da escola: tarefa, nota, novo número')
    def f7():
        p.goto(BASE + f'/comercial/escolas/{eid}'); p.wait_for_load_state('networkidle')
        p.locator('button:has-text("Tarefas")').first.click(); p.wait_for_timeout(400)
        p.fill('input[name="titulo"]', 'ZZ tarefa QA'); p.locator('button:has-text("Criar")').first.click(); p.wait_for_timeout(2500)
        st, t = db('GET', f'tarefas?select=titulo,created_by&escola_id=eq.{eid}')
        f.passo('criar tarefa grava no banco', bool(t) and t[0]['titulo'] == 'ZZ tarefa QA', str(t)[:100])
        p.reload(); p.wait_for_load_state('networkidle')
        p.locator('button:has-text("Notas")').first.click(); p.wait_for_timeout(400)
        p.fill('textarea[name="texto"]', 'ZZ nota QA'); p.locator('button:has-text("Salvar")').first.click(); p.wait_for_timeout(2500)
        st, n = db('GET', f'notas_escola?select=texto,created_by&escola_id=eq.{eid}')
        f.passo('criar nota grava no banco', bool(n) and n[0]['texto'] == 'ZZ nota QA', str(n)[:100])
        p.reload(); p.wait_for_load_state('networkidle')
        p.locator('button:has-text("Novo número")').first.click(); p.wait_for_timeout(600)
        campo = p.locator('input[type="number"]:visible').last
        campo.fill('321'); p.locator('button:has-text("Registrar número")').first.click(); p.wait_for_timeout(2500)
        st, h = db('GET', f'alunos_historico?select=valor&escola_id=eq.{eid}')
        f.passo('registrar novo número de alunos', bool(h) and h[0]['valor'] == 321, str(h)[:100])
    tenta('fluxo 7', f7)

    print('\nFLUXO 8 — administração de usuários')
    def f8():
        p.goto(BASE + '/adminpanel'); p.wait_for_load_state('networkidle')
        p.locator('button:has-text("Cadastrar Usuário")').first.click(); p.wait_for_timeout(500)
        p.fill('input[name="email"]', 'zz.qa@kairos.com.br'); p.fill('input[name="full_name"]', 'ZZ Usuário QA')
        p.fill('input[name="password"]', 'QaTeste#2026'); p.select_option('select[name="role"]', 'consultor')
        p.locator('button[type="submit"]:visible').last.click(); p.wait_for_timeout(5000)
        st, u = db('GET', 'usuarios?select=id,role,ativo&email=eq.zz.qa@kairos.com.br')
        f.passo('criar usuário grava em usuarios', bool(u) and u[0]['role'] == 'consultor', str(u))
        if u:
            global usuario_criado; usuario_criado = u[0]['id']
            st, pr = db('GET', f'profiles?select=role,is_active&id=eq.{usuario_criado}')
            f.passo('criar usuário também cria o perfil (profiles)', bool(pr), str(pr))
            import urllib.request as ur
            rq = ur.Request(BASE + '/api/login', method='POST', data=json.dumps({'email': 'zz.qa', 'password': 'QaTeste#2026'}).encode(), headers={'content-type': 'application/json'})
            ok = json.loads(ur.urlopen(rq, timeout=40).read()).get('error') is None
            f.passo('novo usuário consegue entrar', ok)
    tenta('fluxo 8', f8)
    print('\nerros de console/servidor:', f.erros_console[:6] or 'nenhum')
finally:
    if usuario_criado:
        import urllib.request as ur
        db('DELETE', f'profiles?id=eq.{usuario_criado}'); db('DELETE', f'usuarios?id=eq.{usuario_criado}')
        rq = ur.Request(SB + f'/auth/v1/admin/users/{usuario_criado}', method='DELETE', headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY})
        try: ur.urlopen(rq, timeout=30)
        except Exception: pass
    for t in ['tarefas', 'notas_escola', 'alunos_historico', 'contratos', 'registros']: db('DELETE', f'{t}?escola_id=eq.{eid}')
    db('DELETE', f'escolas?id=eq.{eid}'); db('DELETE', 'escolas?nome=like.ZZ*')
    f.fechar()
