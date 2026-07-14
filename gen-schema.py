# -*- coding: utf-8 -*-
"""
gen-schema.py — Régénère SCHEMA.md depuis le bloc DEFAULT_S de index.html.

Source de vérité : DEFAULT_S (chemin, type, valeur par défaut).
Sortie : SCHEMA.md, arbre Markdown, à lire en début de session pour avoir
le modèle mental de l'état global S sans relire 50 lignes de code.

Lancement : `py gen-schema.py`
"""
import io, json, os, re, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC  = os.path.join(ROOT, "index.html")
OUT  = os.path.join(ROOT, "SCHEMA.md")

with io.open(SRC, "r", encoding="utf-8") as f:
    src = f.read()

# 1. Localiser le bloc DEFAULT_S = { ... };
m = re.search(r'^const DEFAULT_S = \{', src, re.MULTILINE)
if not m:
    sys.exit("✗ DEFAULT_S non trouvé dans index.html")
i = m.end()
depth = 1
in_str = False; str_ch = None; escape = False
end = None
while i < len(src):
    c = src[i]
    if escape:
        escape = False
    elif in_str:
        if c == '\\': escape = True
        elif c == str_ch: in_str = False
    # Les commentaires `//` doivent être sautés ICI aussi, pas seulement à
    # l'étape 2 : sans ça, une apostrophe française dans un commentaire de
    # DEFAULT_S (« l'app ») ouvre une fausse chaîne, les accolades ne sont plus
    # comptées et le bloc extrait s'arrête au mauvais endroit.
    elif c == '/' and i + 1 < len(src) and src[i+1] == '/':
        while i < len(src) and src[i] != '\n':
            i += 1
        continue
    elif c in '"\'':
        in_str = True; str_ch = c
    elif c == '{':
        depth += 1
    elif c == '}':
        depth -= 1
        if depth == 0:
            end = i; break
    i += 1
if end is None:
    sys.exit("✗ Fin du bloc DEFAULT_S non trouvée (accolade non équilibrée)")
body = src[m.end():end]

# 2. Convertir le JS en JSON exploitable.
#    - Cas particulier : JSON.parse(JSON.stringify(DEFAULT_CATALOG))
#    - Strip line comments (//...) hors strings
#    - Quote unquoted keys
#    - Strip trailing commas
def strip_line_comments(s):
    out = []; in_str = False; ch = None; esc = False; i = 0
    while i < len(s):
        c = s[i]
        if esc: out.append(c); esc = False; i += 1; continue
        if in_str:
            out.append(c)
            if c == '\\': esc = True
            elif c == ch: in_str = False
            i += 1; continue
        if c in '"\'':
            in_str = True; ch = c; out.append(c); i += 1; continue
        if c == '/' and i+1 < len(s) and s[i+1] == '/':
            while i < len(s) and s[i] != '\n': i += 1
            continue
        out.append(c); i += 1
    return ''.join(out)

j = strip_line_comments(body)
j = j.replace('JSON.parse(JSON.stringify(DEFAULT_CATALOG))', '"<DEFAULT_CATALOG>"')
j = "{" + j + "}"  # wrap d'abord pour que la regex de quoting voie le { initial
j = re.sub(r'([\{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)(\s*:)', r'\1"\2"\3', j)
j = re.sub(r',(\s*[}\]])', r'\1', j)

try:
    data = json.loads(j)
except Exception as e:
    sys.exit("✗ JSON parse failed (DEFAULT_S non parsable) : " + str(e))

# 3. Rendu Markdown
def type_of(v):
    if isinstance(v, bool):         return "boolean"
    if isinstance(v, (int, float)): return "number"
    if isinstance(v, str):          return "string"
    if v is None:                   return "null"
    if isinstance(v, list):
        if not v: return "array (empty)"
        first = v[0]
        if isinstance(first, dict):
            return "array<{ " + ", ".join(first.keys()) + " }>"
        return "array<" + type_of(first) + ">"
    if isinstance(v, dict):         return "object"
    return type(v).__name__

def short(v):
    s = json.dumps(v, ensure_ascii=False)
    return s if len(s) <= 60 else s[:57] + "…"

def render(d, indent=0):
    out = []
    for k, v in d.items():
        pre = "  " * indent + "- "
        if isinstance(v, dict):
            out.append(f"{pre}**{k}** _(object)_")
            out.extend(render(v, indent+1))
        elif isinstance(v, list):
            out.append(f"{pre}**{k}** _({type_of(v)})_")
            if v and isinstance(v[0], dict):
                sub_pre = "  " * (indent+1) + "- "
                for sk, sv in v[0].items():
                    out.append(f"{sub_pre}{sk}: {type_of(sv)} _(default `{short(sv)}`)_")
        else:
            out.append(f"{pre}**{k}**: {type_of(v)} _(default `{short(v)}`)_")
    return out

lines = [
    "# Schéma de `S` — auto-généré depuis `DEFAULT_S`",
    "",
    "_Régénéré par `py gen-schema.py`. **Ne pas éditer à la main** — modifier `DEFAULT_S` dans `index.html` puis relancer le script._",
    "",
    "Source : `index.html` (bloc `const DEFAULT_S = { ... };`).",
    "",
]
lines.extend(render(data))
lines.append("")

with io.open(OUT, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(lines))

print(f"OK SCHEMA.md generated ({len(data)} top-level keys, {sum(1 for l in lines if l.startswith('-') or l.startswith('  '))} entries)")
