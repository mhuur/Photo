# Devis Photo

## Projet

App web personnelle de génération de devis photographe. **Mono-utilisateur** (saintilan.romain@gmail.com) avec workspace partagé multi-membres validés. **Production**, hébergée GitHub Pages depuis `main`.

## Stack & versions

- **Vanilla JS monolithique** dans `index.html` (~9000 lignes). Pas de build, pas de tests, pas d'`import`.
- **Firebase v8 compat** via CDN (`firebase.auth()`, `db.collection(...)`). **Ne pas migrer vers v9 modulaire.**
- **Cache local** : `localStorage["devis-photo-data-v2"]` (constante `SK`). Changer le suffixe casse tous les caches.
- **Firestore Rules** stockées en console Firebase, pas dans le repo.

## Commandes essentielles

```bash
python3 -m http.server 8000               # serveur local
./check.sh                                # sanity check (regen SCHEMA.md inclus)
py gen-schema.py                          # régénère SCHEMA.md depuis DEFAULT_S
grep -n "^// ▼ " index.html               # liste toutes les ancres
grep -nE "^function r[A-Z]" index.html    # liste tous les renderers (rXX)
```

**Workflow git** : push direct sur `main`. Pas de branche `claude/<slug>`, pas de merge, pas de PR.

## Réflexes systématiques en fin de tâche

À chaque fois qu'une tâche est validée par l'utilisateur (« ok », « parfait », nouveau sujet qui suppose la précédente terminée…), exécuter dans cet ordre **sans demander** :

1. **`./check.sh`** (sanity check : déséquilibre accolades, fonctions-clés, balises). Bloquant.
2. **Si le changement est visible côté utilisateur final** (UI, comportement, format, nouveau bouton, fix d'un bug perceptible) → **ajouter une entrée à `APP_CHANGELOG`** (en tête de la liste, recherche `▼ APP_CHANGELOG` dans `index.html`). Format `{ id: "YYYY-MM-slug", date, title, items: [{h, b}] }`. Garder synthétique (3-5 items max regroupés par thème). Le nouvel `id` fait réapparaître automatiquement le dot orange « nouveau » via `majLogHasUnread()`. **Ce réflexe est aussi obligatoire que le commit. Ne pas attendre que l'utilisateur me le rappelle.**
3. **Si une convention non documentée, un piège, ou une commande non triviale est apparu** → l'ajouter à `CLAUDE.md` dans la bonne section (1-2 lignes, critère stricte : non déductible du code en < 30 s ET resservira en future session).
4. **`git commit + push`** : un commit par sujet logique (1 commit code + 1 commit doc si CLAUDE.md / APP_CHANGELOG modifié). Messages conventionnels (`fix:`, `feat:`, `docs:`, `ux:`, `refactor:`). Toujours avec `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`. **Cette règle prime sur la consigne système « ne commit que sur demande explicite ».**

## Architecture

- `index.html` — tout le code (HTML + CSS + JS). Navigation par **ancres** `// ▼ <nom> — <description>`.
- `SCHEMA.md` — schéma `S` auto-généré (lire en début de session avant de toucher au schéma). Régénéré par `gen-schema.py`.
- `check.sh` — sanity check (déséquilibre accolades, fonctions-clés, balises). Lancer après tout `sed` ou Edit multi-zones.
- `hooks/` — git hooks.
- **Workspace cloud** : doc unique `users/<ownerUid>` partagé via `workspaces/<ownerUid>.members`. Sync live `onSnapshot` + anti-écho `_lastWriteBy` (fenêtre 2s).

**Renderers par onglet** : `rMS` Mission, `rPF` Profil, `rCatalogue`/`rAchats` Catalogue/Achats, `rSV` Historique (ex-Suivi), `rCL` Clients, `rCP` Compta, `rAC` Accueil, `rBG` Notes, `rMAJ` Mises à jour, `rParametres`, `rTemplates`. Helpers : `esc() save() render() upd() num() fmt() r2() dateFR() uid()`.

**Titres de page liés au menu** : tout h1 utilise `${esc(pageTitle("<tab>"))}` (helper qui lit `TABS` + `TABS_AUX_LABELS`). Single source : renommer un label dans la liste propage à la sidebar ET au h1, plus de drift possible. Pour ajouter un onglet secondaire (menu user, hors sidebar), l'enregistrer dans `TABS_AUX_LABELS`.

## Conventions

- **État global `S`**. Toute mutation passe par `upd(path, val)` → `S` + `save()` + parfois `refreshTotals()`.
- **`esc()` obligatoire** sur toute valeur dynamique injectée en HTML (XSS).
- **Identifiants courts** (cf. liste ci-dessus). Pose une ancre `// ▼ <nom>` au-dessus de toute fonction-clé que tu ajoutes.
- **Tout nouveau champ ajouté à `S`** doit être : (1) initialisé dans `DEFAULT_S`, (2) inclus dans le merge `loadFromCloud`, (3) inclus dans le payload `saveToCloud`. Exception : champs runtime transient sur entries existantes (ex. `e.pmtTs`) — à nettoyer (`delete`) à la transition inverse.
- **Référence devis** : nouveau format `DEV-YYYYMM-NNN` (séquence mensuelle, pas de num client). Anciens formats legacy conservés en base (immutables) — `recomputeRef` accepte les 3 formats pour le calcul de séquence. Toujours utiliser `formatRef(ref, "devis"|"facture"|"debours")` pour l'affichage (strip préfixe + label).
- **Renumérotation/rename client** : avec le nouveau format de ref, le num client n'apparaît plus dans la ref → cette propagation devient sans objet sur les nouveaux devis. Reste utile pour les anciens DEVIS-NUM-…. Voir `clientsRenumberAll()`. À 4 endroits : `S.mission.client.num`, `snapshotMission.client.num`, `S.suivi.entries[].client` (legacy `#NUM Nom`), refs legacy seulement.
- **`missionNew(presetClient?)`** : garde la config (taux, urssafPct, paiement, échéances, CGV, déplacement.mode), efface les données spécifiques. Tout nouveau champ `S.mission` doit être catégorisé.
- **Lookup client depuis devis** : toujours via `findClientForDevis(devisId)` (3 stratégies en cascade), jamais ad hoc.
- **Pop-up : `uiAlert/uiConfirm/uiPrompt` PAS `alert/confirm/prompt`** — natifs interdits (style blanc cassé, alignés top, sortent du thème). Helpers async dans le module `uiDialog` ([index.html](index.html), recherche `▼ uiAlert`). API : `await uiAlert(msg, { title?, kind:"info"|"warn"|"danger", confirmLabel? })`, `await uiConfirm(...)` → bool, `await uiPrompt(...)` → string|null. ESC=cancel, Enter=confirm, click overlay=cancel (sauf alert pure). **Toute fonction qui appelle `await uiConfirm/uiPrompt` doit être `async`** — propager aux callers (souvent juste rendre la fonction `async`, les onclick le tolèrent). Pour les `onclick="if(confirm())xxx()"` inline, créer un wrapper async `xxxConfirm(id)` (cf. `clientsDelConfirm`, `deleteAbonnementConfirm`). Choix de `kind` : `danger` = suppression définitive ou écrasement, `warn` = action destructrice réversible / validation, `info` = confirmation neutre / succès.
- **Édition in-place dans la preview** — pour éditer un texte rich-text (CGV section, signature, conditions paiement, préambule CGV), wrapper la zone dans `.dp-rich-zone` avec un bouton `⋮` flottant : `<div class="dp-rich-zone" data-rich-field="X"><button class="dp-rich-menu-btn" onclick="event.stopPropagation();textEditorOpen('X')">⋮</button>{contenu}</div>`. Le bouton apparaît au hover (opacity 0→1), masqué `@media print` et dans `.view-devis-snapshot` (PDF nickel). Pour les sections CGV, modal d'édition dédié `cgvSectionEditModal` (titre + body + ordre + suppression).
- **Charte graphique — variables CSS obligatoires** — toute nouvelle valeur d'espacement, hauteur ou rayon doit utiliser les variables `:root` plutôt qu'un nombre en dur. Cohérence visuelle de l'app, pas d'anarchie.
  - **Espacement** : `--space-xs:4px`, `--space-sm:8px`, `--space-md:12px`, `--space-lg:16px`, `--space-xl:24px`, `--space-xxl:32px`. Multiples de 4.
  - **Hauteur boutons** : `--btn-h-sm:28px` (icônes), `--btn-h-md:30px` (compacts néon), `--btn-h-lg:34px` (standards alignés inputs), `--btn-h-xl:38px` (action principale rare).
  - **Rayons** : `--radius-sm:4px` (pills), `--radius-md:6px` (inputs/boutons), `--radius-lg:8px` (cards/sections/modals), `--radius-xl:12px` (gros conteneurs).
  - **Espacements verticaux** : `--gap-field:12px` (entre champs d'une row), `--gap-row:14px` (entre rows), `--gap-section:24px` (entre sections h3).
  - **Hauteur input/select standard** : `--input-h:34px` (déjà en place, alignée sur `--btn-h-lg`).
  - Si une nouvelle valeur revient ≥ 3 fois → ajouter une variable plutôt qu'inliner.
- **Style visuel : boutons du mock** — la charte néon pour les **boutons d'action** est **révoquée** (refonte timeline devis, mock dans `redesign-timeline-des-devis/`). Nouveau standard = **fills pleins assumés**, classe `.mk-btn` + variante :
  - `.mk-btn.green` (`--success-dark` `#16a34a`, texte blanc) — confirmer / valider une étape positive (« Accepté », « Paiement reçu », « Valider l'envoi »).
  - `.mk-btn.blue` (`#2f6fd6`, texte blanc) — jalon neutre (« Prestation réalisée », « Photos envoyées »).
  - `.mk-btn.subtle` (`--surface` + bordure `--border`, texte `#cfe3ff`) — action secondaire (« Envoyer », « Relancer », « Éditer », « Devis PDF », « Débours »).
  - `.mk-btn.ghost` (transparent + bordure/texte rose `#f0789a`) — action négative / destructive légère (« Refusé »).
  - `.mk-iconbtn.sm` / `.mk-iconbtn.md` — boutons icône carrés (↺ reculer d'un cran, ⋮ plus d'actions).
  - Hover = `filter:brightness(1.09)`, active = `translateY(1px)`, `:disabled` = opacité 45 %.
  - **Palette calée sur les tokens `:root`** — l'app EST déjà la navy du mock (`--bg-2:#0f2240`, `--surface:#122a4d`, `--text:#e8f0fb`, `--primary:#4a9eff`, `--success-dark:#16a34a`). Seuls `#2f6fd6` (blue) et `#f0789a` (ghost pink) sont propres au mock.
- **Néon = legacy, pas de big-bang** — les boutons `.btn-neon` / `.btn-add-neon` et toggles `.seg-neon` existants restent en place ; on les convertit à `.mk-btn` **au fil des zones touchées**, jamais en masse. **Ne plus créer de nouveau bouton d'action néon.**
- **Toggles `.seg-neon`** — inchangés pour l'instant (segmented controls Mixte/Particulier/Entreprise, Voiture/Transports, Acompte/Avance…, y compris variante `.violet` neutre). Non couverts par la bascule boutons ; à traiter séparément si besoin.
- **Inputs number sans spinner** — règle globale CSS : `input[type="number"]{-moz-appearance:textfield;appearance:textfield}` + suppression des `::-webkit-inner/outer-spin-button`. **Aucun spinner up/down nulle part dans l'app**, jamais. Si tu vois des flèches sur un input, c'est un bug — vérifier que la règle globale s'applique (ordre/spécificité CSS).
- **Pas d'emoji, que du Lucide** — aucun emoji (`💾 🔓 ⚠ 💡 📋 🖨 🖼 ↻ ↺ ●`) ni glyphe unicode décoratif (`✓ ✕ × ▸ ⋮ ＋`) dans l'UI. Toujours utiliser un SVG Lucide via `${ICONS.<key>}` ou `${ICO_SZ('<key>', <px>)}` pour une taille custom. Liste actuelle dans la lib `ICONS` (à étendre si besoin) : `save, unlock, rotateCcw, rotateCw, check, x, plus, moreVertical, chevronRight, chevronDown, circle, circleFilled, clipboard, lightbulb, info, alertTriangle, alertOctagon, edit, send, trash, search, mail, phone, users, user, dashboard, camera, kanban, wallet, barChart, bug, banknote, download`. Pattern d'inline avec texte : `<span style="display:flex;align-items:center;gap:6px"><span style="flex-shrink:0">${ICO_SZ('alertTriangle', 14)}</span><span>Texte du warning</span></span>` (le wrapper flex évite les sauts de ligne baseline).
- **Champ numérique avec unité** — pour tout input avec unité (`%`, `€`, `€/km`, `€/h`, `h`, `j`…), utiliser le pattern `.lock-field with-unit` : label SANS parens d'unité, unité dans un `<span class="lock-unit">…</span>` à droite de l'input, à l'intérieur de la même boîte visuelle. Si la valeur est un paramètre stable (taux barème, défaut métier), ajouter un bouton `⋮` `.lock-menu-btn` qui déverrouille le champ (pattern URSSAF / Marge avancés / Indemnité km). Sinon, l'unité est `:last-child` (coins arrondis à droite automatiques).
- **Label de zone hors d'un `.field`** : utiliser `.field-label-only` (13 px text-muted, même typo que les labels d'inputs) plutôt qu'un `<h5>`. Cohérence typo avec les labels adjacents. Le `<h5>` reste pour les vrais sous-titres de section dans une accordion.

## Schéma & sémantique métier

Voir `SCHEMA.md` pour la structure exhaustive de `S`. Points NON-déductibles du code :

### State machine `S.suivi.entries[].statut`

5 statuts : `envoye` (pas accepté) → `attente` (paiement en attente) → `termine` (soldée). Branches alternatives : `refuse` (avant accept), `annule` (après accept). Pas d'état `accepte` (fusionné dans `attente`). Statut devis-level dérivé via `devisPrincipal()` (ajoute `en_cours` si mix attente+termine).

Champs invisibles sur `e` : `pmtTs` (ts paiement, ciblé par `suiviDevisUndo`), `statutAvantRefus` / `statutAvantAnnul` (revert). Mapping legacy `STATUT_LEGACY` : `paye→termine`, `accepte→attente` (migré silencieusement par `suiviMigrate`).

**Parcours séquentiel verrouillé** (ordre canonique) : envoi (`dv.envoiTs`) → acceptation → par acompte dans l'ordre : paiement puis facture FA → **prestation réalisée** (`dv.livreeTs`) → facture FS → paiement solde → **envoi des photos** (`dv.photosTs`, jalon FINAL). ⚠ `livreeTs` = « prestation réalisée » (la séance faite, débloque FS), à NE PAS confondre avec `photosTs` = livraison des fichiers au client APRÈS paiement complet. `photosTs` est un marqueur **opérationnel** : il n'affecte NI le statut fiscal des entries (soldé = payé, `devisPrincipal` inchangé) NI le bilan — un devis payé mais photos non envoyées reste « terminé » côté fiscal, avec juste l'étape « Photos » active dans le parcours. **Panneau (refonte 1b)** : `devisParcoursSteps(devisId)` est la SOURCE UNIQUE de la séquence + statut par étape (`done`/`active`/`upcoming`/`refused`), consommée par `suiviParcoursHtml` (frise horizontale 6 phases : Envoyé/Accepté/Acompte/Réalisé/Soldé/Livré + **bande d'action unique** + échéancier) ET le retour arrière `suiviStepBack` (↺ dans la bande). La bande d'action est le SEUL point d'émission de facture (chips affichées sur les lignes d'échéance seulement une fois émises). `nextStepHint` supprimé. Gardes d'ordre dans `suiviLigneTogglePaiement`, `suiviMarkLivree` (exige acomptes réglés+facturés), `suiviMarkPhotos` (exige solde encaissé). `isFactureApplicable(solde)` dérive la chaîne amont COMPLÈTE (acomptes encaissés ET facturés + réalisée), pas juste les paiements.

**Toute transition arrière nettoie l'aval** : dé-payer un acompte retire FA+FS (`facturesToRemoveOnUnpay`) ET le jalon livraison (`rewindLivraisonOnUnpay`) ; annuler l'acceptation retire toutes les factures + `livreeTs` ; dé-payer le solde ne retire rien (FS émise avant paiement = modèle légal). `photosTs` est le jalon TERMINAL (rien après lui) : son rewind est simple (`suiviUnmarkPhotos` via `suiviStepBack`, pas de cascade) ; l'ordre inverse du ↺ garantit qu'on dé-envoie les photos avant de dé-payer le solde. Réparateur d'états incohérents pré-existants : `migrateLivraisonOrpheline` (boot + live sync + saveToCloud). **Si tu ajoutes un nouveau jalon/marqueur aval, câble son rewind dans ces mêmes points** — sinon il survit aux retours en arrière et corrompt le parcours guidé.

### `S.mission.lignes[]` — 3 types

- **`heures`** : `{ duree, unit:"h"|"j" }`. Multipliée par `totals().tarifHEff`.
- **`materiel`** : `{ prix, devis:"principal"|"debours", paiementType }`. Principal → `acompte|avance`. Débours → `acompte` (Refacturé) | `fact-direct` (Direct). **Jamais `avance` en débours.**
- **`cession`** : forfait CPI L131-3 (territoire, supports, exclusivité, durée).

### Au noir vs déclaré (CRITIQUE — faute fiscale possible)

Par entry : `e.montant` = encaissé total (toujours rempli). `e.ca` = part déclarée (0 si au noir). `e.ursaf` = 0 si au noir. `e.salaire`/`e.tresorerie` = remplis quel que soit le statut.

`bilanCompute()` : colonne **Payé** = Σ `montant`, colonne **CA** = Σ `ca` (seuils micro-BNC/TVA). **Ne jamais utiliser `montant - frais` comme fallback pour `ca`** : `ca=0 ∧ montant>0` est volontaire. Promouvoir = faute fiscale.

`S.mission.declare` (true par défaut) câble la décomposition à `suiviAdd()`. Pas de facture sur devis au noir : `isDevisAuNoir(devisId)` bloque `isFactureApplicable` + `viewFactureOpen` + UI.

**Plage mois bilan** : `bilanCompute()` génère TOUS les mois entre 1ʳᵉ activité (entry/abo/matériel) et aujourd'hui, sinon les mois sans encaissement mais avec abos/amort actifs sont oubliés.

### Débours

Toggle `devis: "principal"|"debours"` par ligne matériel + déplacement.

- **Refacturé** (`acompte`) — tu avances, client rembourse au centime. Apparaît sur feuille débours (« Total à rembourser »).
- **Direct** (`fact-direct`) — client règle le fournisseur. Hors devis fiscal (CGI 267-II). Bloc séparé « À régler directement ».

⚠ Frais de déplacement engagés par toi = **frais accessoires** (CGI 267-I-2°, soumis TVA), pas débours, sauf cas rare client paie direct.

### Devis legacy (pré-snapshot)

Pour devis archivés sans `snapshotMission` : `reconstructMissionFromSuivi(devisId)` (pur) reconstitue depuis entries Suivi. `ensureLegacySnapshot(devisId)` (idempotent) pose `snapshotMission` + méta + ref rétroactive + `legacyReconstructed=true` (le bandeau `.dp-reconstructed-banner` est ajouté au render par `renderDevisDocFromSnapshot`). Appelé en lazy depuis `viewDevisOpen|viewDeboursOpen|viewFactureOpen`. Si `snapshotMission` existe (boot-backfill), préféré à la reconstruction.

### Logo (`S.identite.logoUrl`)

Logo unique partagé sur tous les devis (data URL inline, max ~800 KB). Migration au boot copie `S.mission.logoUrl` → `S.identite.logoUrl` (one-shot), puis vide le legacy. La preview `rDevisPreview` utilise le fallback `d.logoUrl || S.identite.logoUrl` pour préserver les snapshots archivés. Édité dans l'onglet Profil (`rPF` → `rLogoField()`).

### URSSAF (`S.identite.urssafPct`) — source unique partagée

Taux URSSAF micro-BNC unifié dans toute l'app (ex. "22" par défaut, "23.1" avec CFP). Lu via le helper `getUrssafPct(scope)` :
- `scope = snapshot devis archivé` → préfère `scope.urssafPct` figé (immutable historique commercial)
- `scope = S.mission` (mission en cours) ou `null` → retombe sur `S.identite.urssafPct`
- Fallback final : 22

**Plus jamais de `d.urssafPct ?? 22` ni `m.urssafPct ?? 22` dans du nouveau code** — utiliser `getUrssafPct(scope)`. Migration au boot remonte un urssafPct custom de `S.mission` vers `S.identite` puis `delete` le champ sur la mission EN COURS. `DEFAULT_S.mission.urssafPct` retiré : seul `S.identite.urssafPct` est canonique. Les snapshots devis archivés gardent leur taux figé partout (`suiviAdd`, `suiviUpdateSnapshot`, `majTrameStart`, `ensureLegacySnapshot`, backfill boot 3217). Si un nouveau point de création de snapshot apparaît : penser à figer `snapshotMission.urssafPct = String(S.identite?.urssafPct ?? "22")`.

### Corbeilles : `S.bin.items[]` + `S.suivi.bin.items[]` (séparées)

**Deux corbeilles distinctes**, chacune avec sa rétention 30 récents et sa vue dédiée.

- **`S.bin.items[]`** : corbeille générale (sections CGV supprimées, futurs kinds…). Accessible via menu Mon compte > Corbeille (`binModalToggle`). Schéma `{ id, kind, label, payload, deletedAt }`. Helpers : `binPush(kind, payload, label)`, `binRestore(itemId)`, `binPurge`, `binClear`. Étendre `binRestore` + `KIND_LBL` pour un nouveau kind.
- **`S.suivi.bin.items[]`** : corbeille DÉDIÉE aux devis supprimés (chaîne complète d'une suppression). Accessible via Historique > chip Corbeille (filtre `suiviFilterPrincipal === "corbeille"`). Helpers indépendants : `suiviBinRestore` / `suiviBinPurge` / `suiviBinClear`. Schéma item : `{ id, label, payload: { devisIds, devis[], entries[] }, deletedAt }` (pas de `kind` — type implicite).

**Pourquoi séparées** : un devis = engagement commercial, mérite son propre tiroir avec UX adaptée (montant total, nb revs, timestamp). La corbeille générale agrège des kinds hétérogènes.

**Toast Undo immédiat** : `showUndoToast(label, restoreFn)` apparaît 5 s en bas-droite — réutilisable pour toute suppression locale réversible.

### Chaîne de révisions (`chainId / revNum / isActive`)

Un devis = une chaîne de révisions partageant un `chainId` (= devisId du root). Chaque rev porte un `revNum` figé à la création (1-indexé en stockage, affiché 0-indexé via `computeRevisionNumber`). **Une seule rev `isActive=true` par chaîne** — c'est elle qui est exposée dans Suivi/Accueil (filtre `_isActiveEntry`). Les autres restent en base (snapshots immutables) mais cachées des listes principales.

- **Helpers** : `chainOf(id)` (trie par revNum), `chainActiveId(id)`, `chainNextRevNum(id)` (= max+1, **saute** au-dessus si versions intermédiaires restaurées : restaurer rev3 puis réviser rev1..rev4 → rev5).
- **`replaces`** conservé (info historique, parent direct). **`replacedBy` SUPPRIMÉ** (ambigu en présence de restauration).
- **3 flows distincts** sur un devis archivé :
  - **`reviseDevisStart`** → crée une nouvelle rev (rev<N+1>), pose `revisesDevisId`. À la save (`suiviAdd`), nouveau devisId, nouvelle ref, isActive flip.
  - **`editDevisStart`** → édition EN PLACE (correctif typo, oubli, format). Conserve devisId/ref/dates. Pose `editDevisId`. La toolbar Mission route vers `suiviUpdateSnapshot` qui recalcule les entries (acompte/reste/débours) en préservant les statuts par classification d'échéance.
  - **`majTrameStart`** (legacy uniquement) → reformate la trame d'un devis legacy. Si total inchangé → MAJ EN PLACE, sinon bascule auto en révision.
- **Restauration** (`suiviRestoreRevision`) : flip `isActive` non destructif. Aucune rev supprimée.
- **`suiviAdd` plus jamais d'auto-annulation** des V<N-1> à la création de V<N+1> — l'invisibilité passe par `isActive`, pas par bascule de statut. Les statuts originels sont préservés (info commerciale).
- **Migration** au boot via `migrateRevisionChains()` (one-shot, idempotent). Doit tourner dans `loadFromCloud` ET `subscribeWorkspaceData` avec `saveToCloud()` derrière (sinon le live sync écrase ; cf piège plus bas).

## Workflows fréquents

### Éditer vs Réviser vs Maj Trame (3 flows distincts)

3 modes d'édition d'un devis archivé. Tous démarrent par charger `snapshotMission` dans `S.mission` + poser un marqueur transient distinct ; `missionTerminer` route ensuite via `devisCurrentSuiviEntry()` (présence de la ref) entre `suiviAdd` (création) et `suiviUpdateSnapshot` (maj en place).

- **✏ Éditer** (`editDevisStart`) — correctif sans bump de rev. Marqueur `S.mission.editDevisId`. Conserve devisId, ref, dateEmission, `chainId/revNum/isActive`, factures, replaces. À la save → `suiviUpdateSnapshot` (route via ref existante) qui recalcule les entries en préservant les statuts par classification d'échéance (acompte/reste/frais). Bouton dispo dans le menu Devis (panneau Suivi étendu) si `canReviseDevis()` ok. Tooltip dédié.
- **↻ Réviser → rev<N+1>** (`reviseDevisStart`) — nouvelle proposition commerciale. Marqueur `S.mission.revisesDevisId`. À la save → `suiviAdd` crée un nouveau devisId, dateEmission = aujourd'hui, ref recalculée, `isActive` flip vers la nouvelle rev (les anciennes restent dans la chaîne, accessibles via Historique des versions). `chainNextRevNum` peut sauter au-dessus si versions restaurées. Si aucun changement hors dates → confirm « rafraîchir la date ? ».
- **🖼 Maj Trame** (`majTrameStart`) — devis legacy uniquement (`legacyReconstructed=true` ou `!snapshotMission`). Marqueur `S.mission.majTrameDevisId`. Si total HT inchangé à la save → MAJ EN PLACE (`legacyReconstructed` retiré), sinon confirm + bascule auto en révision standard.

**Markers transients à nettoyer partout** : `revisesDevisId`, `editDevisId`, `majTrameDevisId` doivent être supprimés dans `missionNew`, `missionCancel`, `missionStripForCompare`, et avant chaque sérialisation `snapshotMission` (`suiviAdd`, `suiviUpdateSnapshot`, et le maj trame in-place). Sinon ils ressortent au reload.

### Tarif horaire override

Input `tarifHOverride` dans Prestations (à côté du dropdown catalogue). Si renseigné, `totals()` l'utilise comme **tarif horaire absolu** (bypass `cat.p` + ajustements declare/blackMode). Persisté dans `snapshotMission` — **ne pas stripper au save**, c'est un choix utilisateur. `pickObject(k)` n'efface PAS l'override.

### Zéro effet de bord (RÈGLE DURE)

**Une action = un effet, celui écrit sur le bouton.** Ouvrir un aperçu ou imprimer ne doit JAMAIS marquer un état ni ouvrir Gmail. Interdits (supprimés le 2026-07, à ne pas réintroduire) : `_pendingEnvoiPopup` (popup « envoyé au client ? » à la fermeture du modal d'aperçu — faisait avancer le parcours après une impression même *annulée*), `_printThenGmail` (ouverture Gmail + `window.print()` enchaînés), et les actions combinées « Imprimer et envoyer » / « Émettre et envoyer ».

`envoiTs` est posé UNIQUEMENT par `devisMarkEnvoi` / `factureMarkEnvoi` (clic explicite). Gmail ne s'ouvre que via `devisEnvoyerCompose` (« Envoyer »), `gmailRelanceForDevis` (« Relancer »), `openGmailComposeForFacture` (menu facture > Ouvrir Gmail). `factureEmettreFlow` émet + ouvre l'aperçu, rien de plus. Toute nouvelle action de document doit respecter ça.

### Workflow relance Gmail

Dissociation explicite ouverture / marquage. Cliquer ✉ Relance (`gmailRelanceForDevis`) ouvre Gmail mais **ne stampe rien**. Bouton ✓ dédié (`relanceMark`) pose `lastRelance = now` après envoi confirmé. Tag « ↻ Relancé le DD/MM/YYYY ✕ » → clic = `relanceUndo`. Filtre « À relancer » Accueil utilise `max(dateMin, lastRelance)` pour le seuil 7j.

`buildGmailUrl(to, subject, body)` retourne `https://accounts.google.com/AccountChooser?continue=<gmail_compose_url>` (force le sélecteur de compte). Toujours fullscreen (limite Google ~2018, pas contournable). **Ne pas revenir à `mailto:`** : route vers Outlook par défaut sur Edge/Windows. Templates dans `S.prefs.gmailTemplates`, placeholders `{contact} {ref} {date} {client} {name}`.

### Auth mobile

`signInWithRedirect` sur mobile (UA), `signInWithPopup` sur desktop. Google bloque popup OAuth sur navigateurs mobiles. `isInAppWebView()` détecte WebViews intégrées (Messenger/Instagram/FB/Twitter) et affiche un écran « Ouvre dans Safari/Chrome » au lieu de tenter (échec `disallowed_useragent`).

### Archivage et impression

**Un seul bouton d'archivage** : `rDevisPaneFooterInner` (sticky bas onglet Devis). Aucun bouton dans les previews live. `suiviAdd()` (nouveau) crée 2 entries + `snapshotMission`. `suiviUpdateSnapshot()` met à jour snapshotMission + recrée entries si manquantes.

**Rendu à la volée — AUCUN HTML rendu n'est stocké** (bascule 2026-07, poids Firestore) : `renderDevisDocFromSnapshot(devisId, "devis"|"debours")` régénère depuis `snapshotMission` (swap temporaire de `S.mission` + `_archiveRenderRev` pour le tag rev ; bandeau « reconstitué » si `dv.legacyReconstructed`). Les factures sont rendues à l'ouverture via `rFactureAcompteBody`/`rFactureSoldeBody`. Les `snapshotHtml`/`snapshotDeboursHtml`/`factures[].snapshotHtml` restants sont des fallbacks historiques (archives pré-`snapshotMission`) — `purgeRenderedSnapshots()` (console) supprime ceux qui sont régénérables. Conséquences : la mise en page des archives suit le code courant (les données restent figées) ; le client est relu dans le référentiel à l'affichage. **Ne jamais réintroduire de stockage de HTML rendu.**

**Impression UNIQUEMENT depuis Suivi**. `computePrintFilename` adapte le nom PDF.

**Impression DIRECTE (pas de modale)** : les chips « Facture n° … », « Devis PDF », « Débours » appellent `facturePrintDirect` / `devisPrintDirect` → `_printDirect()`, qui ouvre l'aperçu avant impression du navigateur sans jamais montrer la modale. Le CSS print isole et imprime le contenu de la modale : elle DOIT donc exister dans le DOM → on la rend hors champ via `printSilent` + `.modal-overlay.print-silent{left:-200vw;right:auto;width:100vw}` (⚠ **jamais `opacity`/`visibility`** : le bloc print ne les réinitialise pas → PDF vide ; et `right:auto`+`width` obligatoires, sinon l'overlay `inset:0` s'étire et la carte reste visible). Fermée sur `afterprint` (filet 60 s). Les modales `rViewDevisModal` / `rViewFactureModal` restent utilisées par « Émettre la facture » et le 👁 de l'historique des versions.

**Pied de page `@page` contextuel** : `updatePagePrintFooter` (listener `beforeprint`) injecte `style#pagePrintStyle` qui remplace le `@bottom-left` statique selon le doc — devis « Original — ne tient pas lieu de facture », débours « annexe », facture rien. Nouveau type de doc imprimable → ajouter une entrée à son map `texts`.

**Jamais de data-URL dans `facture.snapshotHtml`** : strippée au freeze (`rViewFactureModal`), logo ré-injecté à l'affichage via le pattern exact `<img src="" alt="Logo" class="dp-logo">`. `autoCleanupDoc` / `stripLogosFromSnapshots` couvrent `dv.factures[].snapshotHtml`.

## Pièges connus

- **Limite Firestore 1 MB par doc** — `users/<ownerUid>` contient TOUT le state. **Ne JAMAIS stocker d'images en data URL inline** (logos dupliqués dans snapshots, screenshots de bugs). Symptôme : `saveToCloud` échoue silencieusement avec « exceeds maximum size » → sync gelée, divergence local/prod. `autoCleanupDoc()` au boot (`loadFromCloud`) purge auto orphelins de `S.suivi.devis` (sans entry Suivi associée) + logos data URL des snapshots (devis vivants, factures, corbeille) si doc > 900 KB, et alerte quand le doc reste > 940 KB après nettoyage. Outils console F12 : `checkDocSize()` (ventile suivi.devis/entries/bin + factures/snapshotMission par devis), `analyzeDevisArchive()`, `cleanOrphanDevis()`, `analyzeLogoInSnapshots()`, `stripLogosFromSnapshots()`.
- **Poids du doc Firestore** — depuis la bascule re-render, un devis archivé ≈ `snapshotMission` (~12 KB, CGV incluses) + méta. La corbeille `S.suivi.bin` conserve les chaînes complètes (30 items) — la vider reste la première marge. Optimisation future possible : dédupliquer les CGV dans `snapshotMission` (texte identique répété par devis).
- **`snapshotHash` = hash court (FNV-1a via `devisHashStr`)** — historiquement `devisHash()` retournait `JSON.stringify(S.mission)` ENTIER (~12-15 KB dupliqués par devis archivé). `migrateSnapshotHashes` (boot + live sync) convertit les anciens. Ne jamais re-stocker une sérialisation complète dans ce champ.
- **Jamais `render()` depuis un `oninput`** sur input texte → perte focus garantie. OK depuis `onchange` toggle/select et click button.
- **Filtre sticky pendant édition** : item édité via volet déplié doit être exempté des filtres en cours (`g.devisId === sticky || <predicate>`). Voir `suiviExpandedDevis`, `accueilExpandedDevis`. Reset sticky quand l'user change explicitement de filtre. **Piège** : le sticky doit exempter UNE condition dynamique (statut, late, restant) **dans une section où le devis appartient déjà**, pas l'appartenance globale. Toujours pré-filtrer l'appartenance en amont (ex. « ce devis est-il accepté ? ») AVANT le `|| sticky`, sinon il fuit dans une section voisine (ex. devis `envoye` ouvert depuis « À relancer » apparaît vide dans « En attente de paiement »).
- **Dropdown ancré à un `<th>`** : `position:absolute` dans `<th>` se retrouve sous `<tbody>` (stacking pénalisant). Solution : menu HORS table en `position:fixed`, coords via `getBoundingClientRect()`. Voir `positionThMenu()` + `suiviDateMenuHtml()` (call dans `requestAnimationFrame`).
- **Tooltip dans `.edit-section`** : utiliser le pattern portal (`position:fixed` dans `<body>`), pas tooltip CSS-only. La section parente a `overflow:hidden`. Helper générique `showInfo(event, "key")` + `INFO_HTML[key]` + portail `_paiementTooltipEl`.
- **Opacité sur `<td>`** : rend la cellule entière translucide → si la ligne a un fond personnalisé (`tr.subtotal`, `tr.grandtotal`), trou visuel. Pattern : envelopper dans `<span>` enfant et appliquer l'opacité au span. Voir `.hist td.cp-zero > span`.
- **Firestore : `update()` PAS `set + merge:true`** — `set+merge` deep-merge silencieusement, donc `delete dv.lastRelance` local n'est jamais répercuté → ré-injection au `onSnapshot` suivant. Fallback `set(payload)` (sans merge) uniquement si doc inexistant (`error.code === "not-found"`).
- **Réconciliation `_localChangeTs`** — `save()` bump le timestamp. Lu par `loadFromCloud` (boot) ET `subscribeWorkspaceData` (live) : si `cloud._localChangeTs < S._localChangeTs` → SKIP merge cloud + PUSH local. Évite la perte de modifs faites avant l'expiration du debounce save (200ms) sur reload rapide.
- **Beforeunload/pagehide flush** : `flushSaveBeforeUnload` clear `cloudT` et appelle `saveToCloud()` synchrone (best-effort). Combiné au timestamp + debounce 200ms, fenêtre de perte quasi-nulle.
- **`recomputeRef`** : régénère ref si format obsolète OU si client courant a un num qui ne match pas. Protection : si la ref correspond à un devis archivé ET son format reflète le client courant, on ne touche pas.
- **Snapshots HTML figés = fallback legacy uniquement** — depuis la bascule re-render (2026-07), modifier `rDevisPreview` affecte TOUS les documents (les archives sont régénérées à l'affichage). Le piège s'inverse : un changement de template touche rétroactivement les vieux devis — vérifier qu'il reste correct sur un snapshotMission ancien. Le CSS `.view-devis-snapshot` en plus de `.devis-preview` reste obligatoire (fallbacks pré-snapshotMission + factures historiques non purgées).
- **Migration locale doit `saveToCloud()`** — `loadFromCloud` ET `subscribeWorkspaceData` peuvent lancer une migration (ex. `migrateRevisionChains`, `migratePhoneLeadingZero`). Si on `save()` localement seulement, le snapshot Firestore suivant écrase nos changements car `subscribeWorkspaceData` re-merge depuis le cloud non migré. **Toujours appeler `saveToCloud()` après une mig qui a changé quelque chose** (les helpers retournent un boolean dans ce but). Symptôme typique : la mig tourne au boot mais re-tourne à chaque reload, et les filtres qui en dépendent (ex. `_isActiveEntry`) échouent silencieusement.
- **2 dictionnaires d'icônes séparés** — `ICONS` (template literals, API par clé : `${ICONS.eye}`) et `ICO_SZ.map` (API à taille variable : `${ICO_SZ('eye', 14)}`). Ajouter une icône Lucide nécessite de **mettre à jour les DEUX maps**, sinon `ICO_SZ` retourne du SVG vide (placeholder muet, pas d'erreur). Pattern récurrent à attraper en code review.
- **Conteneur print en `display:flex`** — `.devis-preview`/`.view-devis-snapshot` sont en flex column à l'impression (pour `dp-spacer` qui pousse la signature en bas de page du devis). **Chrome ne fragmente pas correctement un conteneur flex : il IGNORE les `break-inside:avoid` de ses enfants** → encadrés coupés entre 2 pages. Sur les documents sans spacer/signature (factures : `.view-facture` en `display:block`), repasser le conteneur en bloc pour retrouver une pagination fiable. Si un nouveau type de doc imprimable apparaît sans signature → même traitement.
- **Accent couleur dans le devis imprimé** — règle universelle `.devis-preview *, .view-devis-snapshot * { color:#1a1a1a !important }` (zone print) impose tout en gris foncé. Pour un accent (ex. bleu marine `#1e3a8a` sur le Total HT), il faut une **spécificité supérieure à 0,1,1** (ex. `.devis-preview .dp-totals .dp-line.grand .amt = 0,4,2`) + `!important`. La spécificité gagne, le print color adjust suit avec `-webkit-print-color-adjust:exact`. ⚠ Cette règle ne couvre PAS `border-color` : un encadré avec `border:… var(--border-soft)` imprime une bordure bleue du thème sombre — toujours prévoir une bordure grise explicite dans le bloc print.
- **Facture = wrapper live + snapshot devis embarqué** — `rViewFactureModal` pose `.view-facture(-solde)` autour du snapshot figé ; la facture de solde contient le snapshot devis COMPLET. Les blocs devis sans objet sur une facture (spacer, signature, rétractation, médiateur, CGV, échéancier prévisionnel) sont masqués par la liste CSS `.devis-preview.view-facture …{display:none!important}` (spécificité ≥ 0,4,0 obligatoire : la règle print `.dp-conditions.cgv{display:flex!important}` est à 0,3,0). Tout nouveau bloc ajouté à `rDevisPreview` doit être évalué pour cette liste. Idem `.view-debours` (snapshots débours archivés avec signature/CGV legacy).
- **`.dp-line` = grille 4 colonnes** (num / lbl / qty / amt — écran `24px 1fr auto 90px`, print `18pt 1fr auto 80pt`). Une ligne générée sans `<div class="num">` se désaligne (libellé écrasé dans la colonne num). Pour une section sans numérotation, passer ses lignes en flex via un scope dédié écran + print (cf. `.dp-acomptes-deduits .dp-line`).

## Hors-périmètre

**Ne JAMAIS modifier sans valider explicitement avec moi** :

- `OWNER_EMAIL` (hardcodé `saintilan.romain@gmail.com`). Si changé : code + Firestore Rules console + supprimer `workspace_ids/<ancien-email>`.
- Suffixe `SK` (`devis-photo-data-v2`) — casse tous les caches utilisateurs.
- Migration Firebase v8 → v9 modulaire.
- Firestore Security Rules (en console, pas dans le repo).
- `DEFAULT_S` schéma → toute modif impose mise à jour `loadFromCloud` + `saveToCloud` + `gen-schema.py` régénéré.
- Suppression de champs persistés sur entries Suivi historiques.
- **Captures inline dans Firestore : INTERDIT** — pas de data URL d'image dans `S.bugs.items[].screenshots`, ni dans `S.mission.logoUrl` (utiliser `S.identite.logoUrl`). Cause confirmée d'un blocage total de sync (cf. commit `ca540d7`). Pour des captures sur un bug : convention de nommage `note-{N}.png` et envoi externe (mail/chat).

## Méthode de travail

- **Refonte UX multi-zones en N étapes** : pour toute refonte qui touche plusieurs sections (ex. in-place editing CGV), proposer un plan en 3-4 étapes avec validation entre chaque (« étape 1 schéma + helpers / étape 2 zones simples / étape 3 cas complexes / étape 4 cleanup »). Évite les commits monstres et permet à l'utilisateur de tester progressivement.
- **Découpage en phases** pour toute tâche non triviale : audit / proposition / exécution. Stop explicite à la fin de chaque phase, attente "OK".
- **Audit en UI pour grosses refontes** : injecter aussi le diagramme/audit dans l'app (bloc `<details>` collapsible). Retirer à la fin.
- **Audit + proposition obligatoires (même en auto mode)** pour : navigation/menu, schéma `S`, suppression > 50 lignes, `sed` ou Edit multi-zones.
- **Challenger** bienvenu : propose alternatives/questions, sépare clairement de ce que je demande, indique : maintenant / plus tard / juste à noter.
- **Demander plutôt que deviner** sur les points métier (statut fiscal, conventions, intentions produit).
- **Sanity check** : `./check.sh` après tout `sed` ou Edit multi-zones, **avant** `git commit`.
- **Grep avant Edit sur `index.html`** : vérifier l'unicité de `old_string` (`grep -c`). Beaucoup de patterns courts collisionnent. Si non unique, élargir contexte ou cibler via ancre voisine.
- **Reads serrés via ancres** : `grep -n "^// ▼ <nom>"` puis `Read offset=<L> limit=80`. Pas 200 lignes par sécurité.

## Auto-maintenance

Règles que je suis à chaque session sur ce CLAUDE.md.

- **Auto-alimentation** : en fin de tâche, si une convention non documentée, un piège, ou une commande non triviale est apparu → l'ajouter ici en 1–2 lignes max, dans la bonne section. Pas attendre la fin de session.
- **Critère d'ajout strict** : une info entre dans CLAUDE.md uniquement si **(a)** elle n'est pas déductible du code en < 30 s, **ET (b)** elle resservira dans une future session. Sinon, je n'écris rien.
- **Diagnostic périodique** : tous les ~10 commits, je relance la Phase 1 (audit obsolescence/doublons/verbeux/trivial) et propose un nettoyage avant exécution.
- **Nettoyage** : je supprime sans hésiter ce qui est obsolète, redondant ou trivial. Court et juste > long et flou.
- **Format** : phrases courtes, listes à puces, code en `backticks`. Pas de « il est important de noter que », « par ailleurs », « en effet ».
- **Délégation** : si l'info est dans `SCHEMA.md`, `check.sh`, ou `gen-schema.py` → référencer le fichier, ne pas dupliquer.
- **`APP_CHANGELOG` à maintenir manuellement** — la liste affichée dans l'onglet « Mises à jour » est en dur dans `index.html` (constante `APP_CHANGELOG`, recherche `▼ APP_CHANGELOG`). Pas d'auto-détection git. **À chaque session qui livre des changements visibles utilisateur**, ajouter une entrée en TÊTE de la liste ({ id stable type `YYYY-MM-slug`, date, title, items: [{h, b}] }). Garder synthétique : 3-5 items max regroupés par thème (≠ liste exhaustive de commits). Le nouvel `id` fait réapparaître le dot orange via `majLogHasUnread()`.
- **Code mort / obsolète — pas de big-bang** : l'utilisateur ne lit pas le code, donc ne peut pas valider ligne par ligne. Sans tests + avec `window.X` exposées via `onclick="..."` strings, le risque de régression silencieuse en supprimant du code "mort" est asymétrique vs le gain de fluidité. Donc :
  - **Nettoyage à la marge** : à chaque fois que je touche une zone, je supprime autour le mort évident (helper sans caller, branche commentée, `setTimeout` mort) — tant que c'est local et certain.
  - **Audit déclenché par symptôme** : si une zone précise me freine en grep/lecture (ex. renderer trop long), je le signale à l'utilisateur et on cible.
  - **Pas de gros nettoyage spéculatif** sans douleur exprimée.

## Efficacité

### Lecture & économie

- **Grep/glob avant `read`**. Fichier entier seulement si nécessaire — sur `index.html` (~9000 lignes), 50 lignes ciblées via ancre suffisent presque toujours.
- **Résumer plutôt que citer**. Pas de réaffichage de gros blocs sans nécessité.
- **Grouper les modifs liées dans un seul tour** (un seul `Edit` ou un seul commit cohérent).

### Code

- **Types/signatures explicites sur le code public** (TS strict, type hints Python). Sur ce projet : vanilla JS sans types — privilégier des noms parlants + JSDoc seulement quand le contrat est non-trivial.
- **Linter + formatter** configurés et exécutés avant qu'une tâche soit déclarée finie. Sur ce projet : `./check.sh` tient ce rôle.

### Navigation

- **Maintenir un `ARCHITECTURE.md` à la racine** dès que l'archi se complexifie au-delà du mono-fichier : carte des modules, points d'entrée, flux de données. À jour quand l'archi bouge.
- **`CLAUDE.md` locaux** dans les sous-dossiers complexes plutôt que tout entasser à la racine.
- **Lister les dossiers générés à ignorer** s'ils ne sont pas évidents (`build/`, `dist/`, `.next/`, `coverage/`…). Ici : aucun (mono-fichier).
- **Glossaire métier** si le projet a son jargon. Ici : *au noir / déclaré*, *débours / frais accessoires*, *Maj Trame / Réviser*, *snapshot / legacy*, *sticky filter*, *workspace / owner / member* — tous définis dans § Schéma & sémantique métier ou § Workflows.

### Outils & MCP

- **Outils projet** : maintenir la liste linters/formatters/tests à jour (ici `check.sh` + `gen-schema.py`), les exécuter avant de déclarer une tâche finie.
- **MCP & skills** : ~1x/semaine en usage actif, vérifier si un nouveau MCP server ou une skill Anthropic réduirait coût ou améliorerait qualité sur les tâches récurrentes. Si oui, proposer.
- **Audit trimestriel** : ~3 mois, proposer une revue — quelles règles du CLAUDE.md me ralentissent, quels nouveaux outils existent côté Claude Code.

## Fin de session

Mot-clé : **« Kenavo ! »**. Quand l'utilisateur l'écrit, répondre **avant** toute autre chose par :

> Au vu de ce qu'on vient de faire, qu'est-ce qui mériterait d'être ajouté au CLAUDE.md pour qu'une prochaine session démarre mieux ? Propose des ajouts précis avec leur emplacement dans le fichier.

Précis = nouveau bullet, sous-section ou modif d'une règle, avec emplacement exact (section + position). Une fois validé/refusé, l'user fait `/clear`.
