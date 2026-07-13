#!/usr/bin/env bash
# check.sh — sanity check minimal pour index.html.
# Pas de syntax JS exact (node non dispo), mais détecte les erreurs grossières
# : déséquilibre d'accolades, fonction-clé manquante, balises HTML non fermées.
# Sortie 0 si OK, ≠0 si problème.

set -e
cd "$(dirname "$0")"

FILE="index.html"
ERR=0

if [ ! -f "$FILE" ]; then
  echo "✗ $FILE introuvable"; exit 1
fi

# 1. Tags structurels présents et fermés une seule fois.
for tag in "<script>" "</script>" "</body>" "</html>"; do
  count=$(grep -cF "$tag" "$FILE" || true)
  if [ "$count" -lt 1 ]; then
    echo "✗ Tag manquant : $tag"
    ERR=1
  fi
done

# 2. Balance des accolades { } dans tout le fichier (incluant CSS et JS).
# Approximatif (chaînes JS contenant des { faussent le compte) mais détecte
# une suppression sèche de fermeture comme un sed dépassé.
open=$(grep -o "{" "$FILE" | wc -l)
close=$(grep -o "}" "$FILE" | wc -l)
diff=$((open - close))
if [ "$diff" -ne 0 ]; then
  echo "⚠ Balance accolades : $open ouvertes vs $close fermées (diff $diff)"
  echo "  Note : faux positifs possibles via chaînes JS. Comparer avec HEAD précédent."
  ERR=1
fi

# 3. Fonctions clés qui ne doivent jamais disparaître (filet anti-sed).
KEY_FUNCTIONS=(
  "function upd"
  "function render"
  "function totals"
  "function rDevisPreview"
  "function rDeboursPreview"
  "function rFactureAcompteBody"
  "function rFactureSoldeBody"
  "function rDevisAccordion"
  "function rMissionToolbarInner"
  "function rDevisBanners"
  "function rSV"
  "function rCL"
  "function rCP"
  "function rCatalogue"
  "function rAchats"
  "function rPF"
  "function rBG"
  "function suiviAdd"
  "function validateDevis"
  "function recomputeRef"
  "function genHeaderEmetteur"
  "function genFooterMentions"
  "function validityDate"
)
for fn in "${KEY_FUNCTIONS[@]}"; do
  if ! grep -qF "$fn" "$FILE"; then
    echo "✗ Fonction-clé manquante : $fn"
    ERR=1
  fi
done

# 4. Invariant schéma S : chaque clé top-level de DEFAULT_S doit être présente
# dans saveToCloud (Firestore set) ET dans loadFromCloud (merge fallback).
# Filet anti-piège récurrent : ajout d'un champ oublié dans la sync cloud.
keys=$(awk '
  /^const DEFAULT_S = \{/ { in_block=1; next }
  in_block && /^};/        { in_block=0 }
  in_block && /^  [a-zA-Z_]+:/ {
    sub(/:.*/, ""); sub(/^  */, ""); print
  }
' "$FILE")

for k in $keys; do
  # saveToCloud : la clé apparaît sous forme "<key>: S.<key>" (unique dans ce codebase).
  if ! grep -qE "^[[:space:]]*${k}: *S\.${k}\b" "$FILE"; then
    echo "✗ Clé '${k}' présente dans DEFAULT_S mais absente de saveToCloud"
    ERR=1
  fi
  # loadFromCloud : la clé est testée via "if (d.<key>" ou "d.<key>" (toutes les variantes utilisées).
  if ! grep -qE "if \(d\.${k}\b" "$FILE"; then
    echo "✗ Clé '${k}' présente dans DEFAULT_S mais absente de loadFromCloud"
    ERR=1
  fi
done

# 5. Le fichier ne doit pas avoir grossi/rétréci de plus de 30% par rapport
# au dernier commit (filet anti-suppression massive accidentelle).
if git rev-parse --git-dir >/dev/null 2>&1; then
  prev_size=$(git show HEAD:"$FILE" 2>/dev/null | wc -c || echo 0)
  cur_size=$(wc -c < "$FILE")
  if [ "$prev_size" -gt 0 ]; then
    # bash arithmetic: drop 30%
    threshold=$((prev_size * 30 / 100))
    delta=$((cur_size - prev_size))
    abs_delta=${delta#-}
    if [ "$abs_delta" -gt "$threshold" ]; then
      echo "⚠ Variation de taille importante : $prev_size → $cur_size octets (Δ $delta)"
      echo "  Si c'est intentionnel, ignore. Sinon vérifie le diff avant push."
      ERR=1
    fi
  fi
fi

# 5bis. SYNTAXE JS des blocs <script> inline (node, si dispo).
# Le comptage d'accolades ne voit PAS une erreur de parsing (ex. `const x`
# déclaré 2× dans la même portée) : le script entier meurt au chargement et
# l'app rend une PAGE BLANCHE. Ce check l'attrape avant le commit.
if command -v node >/dev/null 2>&1; then
  node -e '
    const fs = require("fs"), vm = require("vm");
    const html = fs.readFileSync("index.html", "utf8");
    const re = /<script(?![^>]*src=)[^>]*>([\s\S]*?)<\/script>/g;
    let m, bad = 0;
    while ((m = re.exec(html)) !== null) {
      const startLine = html.slice(0, m.index).split("\n").length;
      try { new vm.Script(m[1]); }
      catch (e) {
        bad = 1;
        const l = (e.stack.match(/evalmachine[^:]*:(\d+)/) || [])[1];
        console.error("✗ Erreur de syntaxe JS (ligne ~" + (startLine + Number(l || 0)) + ") : " + e.message);
      }
    }
    process.exit(bad);
  ' || ERR=1
fi

# 6. SCHEMA.md doit être à jour avec DEFAULT_S. Régénère et signale tout écart.
# Si la regen change le fichier, l'utilisateur doit faire `git add SCHEMA.md`.
if command -v py >/dev/null 2>&1 && [ -f gen-schema.py ]; then
  before_hash=""
  [ -f SCHEMA.md ] && before_hash=$(sha1sum SCHEMA.md | cut -d' ' -f1)
  if py gen-schema.py >/dev/null 2>&1; then
    after_hash=$(sha1sum SCHEMA.md | cut -d' ' -f1)
    if [ "$before_hash" != "$after_hash" ]; then
      echo "⚠ SCHEMA.md a été régénéré (DEFAULT_S a changé)."
      echo "  Ajoute-le au commit : git add SCHEMA.md"
      ERR=1
    fi
  else
    echo "⚠ gen-schema.py a échoué (DEFAULT_S non parsable ?)"
    ERR=1
  fi
fi

if [ "$ERR" -eq 0 ]; then
  echo "✓ Sanity check OK ($(wc -l < "$FILE") lignes, $(wc -c < "$FILE") octets)"
fi
exit $ERR
