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

def parse_obj(src, i):
    """src[i] == '{' -> devolve (chaves de nível 1, índice do fecho)"""
    depth = 0; keys = []; j = i; tok = ''; expect_key = True; n = len(src)
    while j < n:
        ch = src[j]
        if ch in '"\'`':
            q = ch; k = j + 1
            while k < n and src[k] != q:
                if src[k] == '\\': k += 1
                k += 1
            s = src[j + 1:k]
            # chave com aspas: "chave":
            m = re.match(r'\s*:', src[k + 1:k + 6])
            if depth == 1 and m and expect_key: keys.append(s)
            j = k + 1; expect_key = False if depth == 1 else expect_key; continue
        if ch in '{[(':
            depth += 1
            if depth == 1: expect_key = True; j += 1; continue
        elif ch in '}])':
            depth -= 1
            if depth == 0: return keys, j
        elif ch == ',' and depth == 1: expect_key = True
        elif depth == 1 and expect_key and (ch.isalpha() or ch == '_' or ch == '.'):
            m = re.match(r'(\.\.\.)?([A-Za-z_][A-Za-z0-9_]*)(\s*[:,}\(]|\s*$)', src[j:j + 80])
            if m:
                if m.group(1): j += len(m.group(0)) - len(m.group(3)); expect_key = False; continue
                name = m.group(2)
                nxt = m.group(3).strip()
                if name in ('get', 'set', 'async') : pass
                elif nxt.startswith(':') or nxt in (',', '}', ''): keys.append(name)
                j += len(m.group(0)) - len(m.group(3)); expect_key = False; continue
        j += 1
    return keys, n

achados = {}
for raiz, _, arqs in os.walk(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src')):
    for a in arqs:
        if not a.endswith(('.ts', '.tsx')): continue
        p = os.path.join(raiz, a); src = open(p, encoding='utf-8', errors='ignore').read()
        for m in re.finditer(r"\.from\(\s*'([a-z_0-9]+)'\s*\)", src):
            tab = m.group(1)
            prox = re.search(r"\.from\(", src[m.end():])
            fim = m.end() + (prox.start() if prox else 1200)
            janela = src[m.end(): min(fim, m.end() + 1500)]
            for mm in re.finditer(r'\.(insert|update|upsert)\(\s*(\[?\s*\{|[A-Za-z_][A-Za-z0-9_]*)', janela):
                op = mm.group(1); alvo = mm.group(2).strip()
                pos = m.end() + mm.end()
                if alvo.startswith('[') or alvo.startswith('{'):
                    i = src.index('{', m.end() + mm.start()); keys, _ = parse_obj(src, i)
                else:
                    mv = None
                    for mv in re.finditer(r'(?:const|let)\s+' + re.escape(alvo) + r'(?:\s*:[^=]+)?\s*=\s*\{', src[:m.start()]): pass
                    if not mv: continue
                    i = mv.end() - 1; keys, _ = parse_obj(src, i)
                for k in keys:
                    if tab in cols and k not in cols[tab]:
                        achados.setdefault((tab, k), set()).add(os.path.relpath(p, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src')).replace('\\', '/') + f' ({op})')
if not achados: print('nenhuma coluna ausente encontrada')
for (tab, k), fs in sorted(achados.items()):
    print(f'{tab}.{k}  <- ' + '; '.join(sorted(fs))[:150])
print('\ntabelas comparadas:', len(cols))
