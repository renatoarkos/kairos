import os
import sys, io, re, json, urllib.request, urllib.error, http.cookiejar
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
BASE = os.environ.get('QA_BASE', 'https://kairos.arkosintelligence.com')
# Termos que NÃO podem aparecer no site (regex), passados por variável de ambiente
# para a lista não ficar no repositório. Ex.: QA_TERMOS_PROIBIDOS='termo1|termo2'
BAD = re.compile(os.environ.get('QA_TERMOS_PROIBIDOS') or r'(?!x)x', re.I)
ERR = re.compile(r'Application error|Internal Server Error|This page could not be found|NEXT_NOT_FOUND|Unhandled Runtime|digest:|Não foi possível (entrar|carregar)|erro do servidor|\[object Object\]|>undefined<|>NaN<|Something went wrong', re.I)

def opener():
    cj = http.cookiejar.CookieJar()
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj)), cj
def get(op, path, method='GET', body=None, headers=None, timeout=90):
    req = urllib.request.Request(BASE + path, method=method, data=body, headers=headers or {})
    try:
        r = op.open(req, timeout=timeout); data = r.read()
        return r.status, r.geturl().replace(BASE, ''), data, dict(r.headers)
    except urllib.error.HTTPError as e:
        return e.code, path, e.read(), dict(e.headers)
    except Exception as e:
        return 0, path, str(e).encode(), {}

def texto(b):
    h = b.decode('utf-8', 'ignore')
    t = re.sub(r'<script.*?</script>|<style.*?</style>', '', h, flags=re.S)
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)), h

def login(user, senha):
    op, cj = opener()
    s, _, d, _ = get(op, '/api/login', 'POST', json.dumps({'email': user, 'password': senha}).encode(), {'content-type': 'application/json'})
    return op, json.loads(d).get('error') is None

def checar(op, path, esperar_login=False):
    s, final, d, h = get(op, path)
    t, raw = texto(d)
    prob = []
    if s != 200: prob.append(f'HTTP {s}')
    if '/login' in final and not esperar_login and not path.startswith('/login'): prob.append('redirecionou p/ login')
    m = ERR.search(t)
    if m: prob.append('erro na página: ' + m.group(0)[:40])
    if re.search(r'This page could.?n.t be found|Esta página não foi encontrada', t): prob.append('página 404')
    if BAD.search(t): prob.append('texto visível com nome de outro sistema')
    return s, final, len(d), prob

if __name__ == '__main__':
    op, ok = login(os.environ['QA_USUARIO'], os.environ['QA_SENHA']); print('login hugo:', ok)
    ids = json.loads(open(sys.argv[1], encoding='utf-8').read()) if len(sys.argv) > 1 else {}
    paginas = ['/comercial', '/comercial/panorama', '/comercial/panorama?base=leads&regiao=Nordeste', '/comercial/escolas', '/comercial/escolas/nova', '/comercial/registros', '/comercial/registros/novo',
               '/comercial/priorizacao', '/comercial/funil-contratacao', '/comercial/metas', '/comercial/quantidade-alunos',
               '/comercial/produtos', '/calculadora', '/comercial/pre-cadastros', '/comercial/propostas', '/comercial/jornada-visual',
               '/comercial/jornada', '/comercial/contratos', '/comercial/pipeline', '/comercial/pipeline-proposta', '/comercial/tabela',
               '/comercial/leads', '/comercial/followup', '/agenda', '/transcricoes', '/leads-banco', '/importacao', '/exports',
               '/estoque', '/amostras', '/dashboards', '/ai-bob', '/financeiro', '/formularios', '/contratos', '/pesquisa-mercado',
               '/sobre', '/tutorial', '/adminpanel']
    if ids.get('escola'): paginas += [f"/comercial/escolas/{ids['escola']}", f"/comercial/escolas/{ids['escola']}/editar"]
    if ids.get('registro'): paginas += [f"/comercial/registros/{ids['registro']}/editar"]
    if ids.get('proposta'): paginas += [f"/comercial/propostas/{ids['proposta']}/editar"]
    print('\n=== PÁGINAS (logado) ===')
    falhas = 0
    for p in paginas:
        s, final, n, prob = checar(op, p)
        print(('OK   ' if not prob else 'FALHA'), p, '|', s, n, 'bytes', ('| ' + '; '.join(prob)) if prob else '')
        falhas += bool(prob)
    print('\n=== PÁGINAS PÚBLICAS (sem login) ===')
    pub, _ = opener()
    for p in ['/login', '/formulario', '/acesso-escola', '/proposta/acesso', '/hub/comercial/login', '/hub/contratos/login', '/hub/pedidos/login', '/hub/contratos', '/hub/pedidos', '/formulario/obrigado']:
        s, final, n, prob = checar(pub, p, esperar_login=True)
        print(('OK   ' if not prob else 'FALHA'), p, '|', s, '->', final, ('| ' + '; '.join(prob)) if prob else '')
        falhas += bool(prob)
    print('\n=== PROTEÇÃO (sem login deve ir para /login) ===')
    for p in ['/comercial', '/comercial/escolas', '/comercial/produtos', '/leads-banco', '/adminpanel']:
        s, final, n, prob = checar(pub, p, esperar_login=True)
        ok2 = '/login' in final
        print(('OK   ' if ok2 else 'FALHA'), p, '->', final)
        falhas += (not ok2)
    print('\n=== APIs de leitura (logado) ===')
    apis = ['/api/health', '/api/usuarios', '/api/negociacoes', '/api/propostas', '/api/pipeline-escola', '/api/pipeline-proposta',
            '/api/buscar-escola?q=acr', '/api/precadastros-select', '/api/planilha/modelo', '/api/planilha/modelo/pessoas',
            '/api/leads-export', '/api/priorizacao-export']
    for p in apis:
        s, final, d, h = get(op, p)
        corpo = d[:80].decode('utf-8', 'ignore').replace('\n', ' ')
        bad = s >= 500 or s == 0 or bool(BAD.search(d[:4000].decode('utf-8', 'ignore')))
        print(('OK   ' if not bad else 'FALHA'), p, '|', s, len(d), 'bytes |', re.sub(BAD, '***', corpo)[:60])
        falhas += bad
    print('\nTOTAL DE FALHAS:', falhas)
