import os
import sys, io, re, json, os, urllib.request
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
env = {}
for l in open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env.local'), encoding='utf-8'):
    if '=' in l: k, v = l.strip().split('=', 1); env[k] = v
U, K = env['NEXT_PUBLIC_SUPABASE_URL'], env['SUPABASE_SERVICE_ROLE_KEY']
r = urllib.request.Request(U + '/rest/v1/', headers={'apikey': K, 'Authorization': 'Bearer ' + K})
defs = json.load(urllib.request.urlopen(r, timeout=60))['definitions']
cols = {t: set(d.get('properties', {}).keys()) for t, d in defs.items()}
def split_top(s):
    out, depth, cur = [], 0, ''
    for ch in s:
        if ch == '(': depth += 1
        if ch == ')': depth -= 1
        if ch == ',' and depth == 0: out.append(cur); cur = ''
        else: cur += ch
    out.append(cur); return [x.strip() for x in out if x.strip()]
achados = {}
for raiz, _, arqs in os.walk(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src')):
    for a in arqs:
        if not a.endswith(('.ts', '.tsx')): continue
        p = os.path.join(raiz, a); src = open(p, encoding='utf-8', errors='ignore').read()
        rel = os.path.relpath(p, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src')).replace(chr(92), '/')
        for m in re.finditer(r"\.from\(\s*'([a-z_0-9]+)'\s*\)", src):
            tab = m.group(1)
            if tab not in cols: continue
            prox = re.search(r"\.from\(", src[m.end():])
            janela = src[m.end(): m.end() + min(prox.start() if prox else 1500, 1500)]
            usados = []
            for mm in re.finditer(r"\.select\(\s*(['`\"])((?:\.|(?!\1).)*)\1", janela, re.S):
                for item in split_top(mm.group(2)):
                    if item == '*' or '(' in item or '!' in item: continue
                    item = item.split(':')[-1].strip()
                    if re.fullmatch(r'[a-z_0-9]+', item): usados.append(('select', item))
            for mm in re.finditer(r"\.(eq|neq|in|gte|lte|gt|lt|is|ilike|like|not|order|contains)\(\s*'([a-z_0-9]+)'", janela):
                usados.append((mm.group(1), mm.group(2)))
            for op, col in usados:
                if col not in cols[tab]: achados.setdefault((tab, col), set()).add(f'{rel} ({op})')
for (t, c), fs in sorted(achados.items()): print(f'{t}.{c}  <- ' + '; '.join(sorted(fs))[:170])
print('\nverificadas:', len(cols), 'tabelas;', 'achados:', len(achados))
