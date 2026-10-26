import os
import sys; sys.path.insert(0, sys.argv[1])
from flow_lib import *
import time, traceback
SP = sys.argv[1]
f = Flow(); p = f.page
def shot(nome):
    try: p.screenshot(path=f'{SP}/fail_{nome}.png', full_page=False)
    except Exception: pass
f.login()
escola_id = None; registro_id = None; produto_novo = None
CHIPS = 'input[name^="livros_"]'
try:
    print('\nFLUXO 2 — escola: criar, abrir ficha, editar')
    p.goto(BASE + '/comercial/escolas/nova'); p.wait_for_load_state('networkidle')
    p.fill('input[name="nome"]', 'ZZ QA ESCOLA FLUXO'); p.fill('input[name="cidade"]', 'Recife')
    try: p.select_option('select[name="estado"]', 'PE')
    except Exception: p.fill('input[name="estado"]', 'PE')
    p.fill('input[name="qtd_fund1_ano1"]', '40')
    p.click('button[type="submit"]'); p.wait_for_url(re.compile(r'/comercial/escolas/[0-9a-f-]{36}'), timeout=40000)
    escola_id = re.search(r'/escolas/([0-9a-f-]{36})', p.url).group(1)
    f.passo('criar escola', True)
    f.passo('ficha mostra o nome da escola', 'ZZ QA ESCOLA FLUXO' in f.texto())
    p.goto(BASE + f'/comercial/escolas/{escola_id}/editar'); p.wait_for_load_state('networkidle')
    p.fill('input[name="cidade"]', 'Olinda'); p.click('button[type="submit"]')
    p.wait_for_url(re.compile(r'/comercial/escolas/[0-9a-f-]{36}'), timeout=40000)
    st, r = db('GET', f'escolas?select=cidade,qtd_fund1,updated_by&id=eq.{escola_id}')
    f.passo('editar escola grava no banco', bool(r) and r[0]['cidade'] == 'Olinda' and bool(r[0]['updated_by']), str(r)[:100])

    print('\nFLUXO 3 — registro com alunos e livros por série')
    p.goto(BASE + f'/comercial/registros/novo?escola={escola_id}'); p.wait_for_load_state('networkidle')
    p.fill('textarea[name="resumo"]', 'Registro de teste automatizado QA')
    p.fill('input[name="qtd_infantil2"]', '30'); p.fill('input[name="qtd_fund1_ano1"]', '45')
    def add_livro(nome_input, idx):
        sel = p.locator(f'input[name="{nome_input}"]').locator('xpath=ancestor::div[.//select][1]').locator('select').first
        sel.select_option(index=idx)
        p.wait_for_timeout(300)
    add_livro('qtd_infantil2', 1); add_livro('qtd_infantil2', 1)
    add_livro('qtd_fund1_ano1', 1)
    chips = p.locator(CHIPS).count()
    f.passo('escolher livros na série (chips)', chips >= 2, f'{chips} livros selecionados na tela')
    p.click('button:has-text("Salvar Registro")'); p.wait_for_url(re.compile(r'/comercial/escolas/[0-9a-f-]{36}'), timeout=45000)
    st, r = db('GET', f'registros?select=id,qtd_infantil,qtd_fund1,qtd_infantil2,qtd_fund1_ano1,classificacao,potencial_financeiro&escola_id=eq.{escola_id}')
    ok = isinstance(r, list) and len(r) == 1
    f.passo('registro gravado no banco', ok, str(r)[:160])
    if ok:
        registro_id = r[0]['id']
        f.passo('totais por segmento = soma das séries', r[0]['qtd_infantil'] == 30 and r[0]['qtd_fund1'] == 45, f"inf={r[0]['qtd_infantil']} f1={r[0]['qtd_fund1']}")
        st, v = db('GET', f'registro_serie_livros?select=serie,produto_id,ano_letivo&registro_id=eq.{registro_id}')
        anos = sorted({x['ano_letivo'] for x in v}) if isinstance(v, list) else v
        f.passo('livros vinculados por série', isinstance(v, list) and len(v) >= 2, f'{len(v) if isinstance(v, list) else v} vínculos | anos: {anos}')
        st, e = db('GET', f'escolas?select=qtd_infantil,qtd_fund1,qtd_infantil2,qtd_fund1_ano1&id=eq.{escola_id}')
        f.passo('escola atualizada com as séries do registro', e[0]['qtd_infantil2'] == 30 and e[0]['qtd_fund1_ano1'] == 45, str(e[0]))
        p.goto(BASE + f'/comercial/registros/{registro_id}/editar'); p.wait_for_load_state('networkidle')
        n_chips = p.locator(CHIPS).count()
        f.passo('editar registro: livros voltam marcados', n_chips >= 2, f'{n_chips} livros')
        f.passo('editar registro: alunos por série preenchidos', p.input_value('input[name="qtd_infantil2"]') == '30')
        p.click('button[type="submit"]'); p.wait_for_url(re.compile(r'/comercial/escolas/[0-9a-f-]{36}'), timeout=45000)
        st, v2 = db('GET', f'registro_serie_livros?select=id&registro_id=eq.{registro_id}')
        f.passo('salvar de novo mantém os livros (sem duplicar)', isinstance(v2, list) and len(v2) == len(v), f'{len(v2)} vínculos')
        st, d = db('GET', 'produtos_livros_demanda?select=produto_id,ano,alunos,escolas&ano=eq.2027')
        total = sum(x['alunos'] for x in d) if isinstance(d, list) else -1
        f.passo('demanda 2027 herdada dos registros', total >= 75, f'{total} alunos-livro em 2027')

    print('\nFLUXO 4 — produtos: editar, ano 2027, cadastrar')
    p.goto(BASE + '/comercial/produtos'); p.wait_for_load_state('networkidle')
    linhas = p.locator('tbody tr').count(); f.passo('lista de produtos carrega', linhas >= 80, f'{linhas} linhas')
    p.locator('button[aria-label^="Editar"]').first.click()
    p.fill('input[name="valor_venda"]', '99,90'); p.click('button:has-text("Salvar alterações")'); p.wait_for_timeout(3500)
    st, pv = db('GET', 'produtos_livros?select=titulo,valor_venda&valor_venda=not.is.null')
    f.passo('editar produto grava custo de venda', isinstance(pv, list) and any(abs(float(x['valor_venda']) - 99.9) < 0.01 for x in pv), str(pv)[:100])
    p.click('button:has-text("2027")'); p.wait_for_timeout(800)
    f.passo('filtro 2027 mostra aviso de herança', 'herda os produtos' in f.texto())
    f.passo('coluna de quantidade 2027 presente', 'Qtd. 2027' in f.texto())
    p.click('button:has-text("+ Cadastrar novo produto")'); p.fill('input[name="titulo"]', 'ZZ QA LIVRO NOVO')
    p.select_option('select[name="serie"]', 'fund2_ano6'); p.fill('input[name="valor_unitario"]', '10,5')
    p.click('button:has-text("Salvar produto")'); p.wait_for_timeout(3500)
    st, pn = db('GET', 'produtos_livros?select=id,serie,valor_unitario&titulo=eq.ZZ QA LIVRO NOVO')
    f.passo('cadastrar novo produto', isinstance(pn, list) and len(pn) == 1 and pn[0]['serie'] == 'fund2_ano6', str(pn)[:100])
    if isinstance(pn, list) and pn: produto_novo = pn[0]['id']

    print('\nFLUXO 5 — metas')
    p.goto(BASE + '/comercial/metas'); p.wait_for_load_state('networkidle')
    st, antes = db('GET', 'metas_comerciais?select=meta_reunioes')
    p.click('button:has-text("Editar metas")'); p.fill('input[name="meta_reunioes"]', '77'); p.click('button:has-text("Salvar")'); p.wait_for_timeout(3500)
    st, dep = db('GET', 'metas_comerciais?select=meta_reunioes,atualizado_por')
    f.passo('editar metas grava no banco', dep[0]['meta_reunioes'] == 77, str(dep))
    db('PATCH', 'metas_comerciais?id=eq.1', {'meta_reunioes': antes[0]['meta_reunioes']})
except Exception as e:
    shot('flow2'); f.passo('ERRO inesperado no fluxo', False, repr(e)[:300] + ' | url=' + p.url.replace(BASE, ''))
finally:
    print('\nerros de console/servidor:', f.erros_console[:6] or 'nenhum')
    if registro_id: db('DELETE', f'registros?id=eq.{registro_id}')
    if escola_id: db('DELETE', f'escolas?id=eq.{escola_id}')
    if produto_novo: db('DELETE', f'produtos_livros?id=eq.{produto_novo}')
    db('PATCH', 'produtos_livros?valor_venda=not.is.null', {'valor_venda': None})
    db('DELETE', 'escolas?nome=like.ZZ*')
    f.fechar()
