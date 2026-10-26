import os
import sys, io, json, re, urllib.request
from playwright.sync_api import sync_playwright
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
BASE = os.environ.get('QA_BASE', 'https://kairos.arkosintelligence.com')
CHROME = os.environ.get('QA_CHROME', 'C:/Program Files/Google/Chrome/Application/chrome.exe')
# Termos que NÃO podem aparecer no site (regex), passados por variável de ambiente
# para a lista não ficar no repositório. Ex.: QA_TERMOS_PROIBIDOS='termo1|termo2'
BAD = re.compile(os.environ.get('QA_TERMOS_PROIBIDOS') or r'(?!x)x', re.I)

env = {}
for l in open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env.local'), encoding='utf-8'):
    if '=' in l:
        k, v = l.strip().split('=', 1); env[k] = v
SB, KEY = env['NEXT_PUBLIC_SUPABASE_URL'], env['SUPABASE_SERVICE_ROLE_KEY']

def db(method, path, body=None, extra=None):
    h = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json', **(extra or {})}
    import urllib.parse
    r = urllib.request.Request(SB + '/rest/v1/' + urllib.parse.quote(path, safe="/?=&,.()*-_:%"), method=method, data=json.dumps(body).encode() if body is not None else None, headers=h)
    try:
        with urllib.request.urlopen(r, timeout=60) as x:
            raw = x.read(); return x.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]

class Flow:
    def __init__(self, headless=True):
        self.pw = sync_playwright().start()
        self.browser = self.pw.chromium.launch(executable_path=CHROME, headless=headless)
        self.ctx = self.browser.new_context(viewport={'width': 1400, 'height': 900})
        self.page = self.ctx.new_page()
        self.page.set_default_timeout(45000)
        self.erros_console = []
        self.page.on('pageerror', lambda e: self.erros_console.append('JS@' + self.page.url.replace(BASE, '')[:60] + ': ' + str(e)[:110]))
        self.page.on('response', lambda r: self.erros_console.append(f'HTTP {r.status} {r.url.replace(BASE, "")[:90]}') if r.status >= 500 else None)
        self.resultados = []
    def login(self, user=None, senha=None):
        user = user or os.environ['QA_USUARIO']; senha = senha or os.environ['QA_SENHA']
        p = self.page
        p.goto(BASE + '/login'); p.wait_for_load_state('networkidle')
        p.fill('input[type="text"], input[name="email"], input[placeholder*="suário" i]', user)
        p.fill('input[type="password"]', senha)
        p.click('button[type="submit"]')
        p.wait_for_url(re.compile(r'/comercial|/hub|/$'), timeout=60000)
        return '/login' not in p.url
    def passo(self, nome, ok, detalhe=''):
        self.resultados.append((nome, ok, detalhe))
        print(('  OK    ' if ok else '  FALHA ') + nome + (f' | {detalhe}' if detalhe else ''))
    def texto(self):
        return re.sub(r'\s+', ' ', self.page.inner_text('body'))
    def fechar(self):
        self.browser.close(); self.pw.stop()
