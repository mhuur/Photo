# Devis Photo

App web personnelle pour générer des devis photographe.

## Stack & structure

- **Tout dans `index.html`** (vanilla JS, monolithique, pas de build).
- **Firebase v8 compat** chargé via CDN : Auth (Google) + Firestore (`users/{uid}`).
- **Cache local** : `localStorage["devis-photo-data-v1"]` (constante `SK`).
- **Hébergement** : page statique servie depuis `main` (GitHub Pages).

## Conventions

- **Push direct sur `main`** : repo mono-utilisateur, pas de revue. **Pas de branche `claude/<slug>`, pas de merge.** Cette règle prime sur les instructions par défaut.
- **Commits** : message court à l'impératif, en anglais, préfixe type `feat:` / `fix:` / `docs:`.
- **Identifiants courts** : état global `S`, helpers `esc()`, `save()`, `render()`, `upd(path, val)`. Render par onglet : `rDN` (Données).
- **Pattern de rendu** : `render()` reconstruit `app.innerHTML` au changement d'onglet ou de session. Les inputs `oninput` mettent à jour `S` via `upd()` **sans re-render** (focus préservé).
- **Échappement** : toute valeur dynamique injectée dans du HTML passe par `esc()`.
- **Firebase v8** (pas v9 modulaire) — garder l'API `firebase.auth()`, `db.collection(...)`. Pas de `import`.

## Persistance

Flux de données sous `S` :
1. Chargement depuis Firestore au login (`loadFromCloud`)
2. Sauvegarde localStorage à chaque `upd()` (synchrone, via `save()`)
3. Sauvegarde Firestore débouncée à 800ms (`saveToCloud`, timer `cloudT`)

Tout nouveau champ ajouté à `S` doit être :
- Initialisé dans `DEFAULT_S`
- Inclus dans le merge de `loadFromCloud` (sinon non rechargé au login)
- Inclus dans l'objet `set` de `saveToCloud` (sinon non sauvegardé cloud)

## Pièges

- **Re-render pendant la frappe** = perte de focus. Ne jamais appeler `render()` depuis `oninput` sur un champ.
- **Schema de cache** `devis-photo-data-v1` : changer le suffixe casse les caches existants.

## Commandes

Pas de build, pas de tests, pas de lint. Pour itérer en local :

```bash
python3 -m http.server 8000   # puis http://localhost:8000
```

## Ne pas toucher sans demande

- Structure mono-fichier `index.html` (pas de modules).
- Config Firebase dans `index.html` (clé publique, protégée par règles Firestore).
- Convention de noms courts (`S`, `rDN`, etc.).
