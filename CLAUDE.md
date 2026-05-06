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

**Auto-commit** : à la fin de chaque tâche validée par l'utilisateur (« ok », « parfait », un nouveau sujet qui suppose la précédente terminée…), Claude commit + push **automatiquement sans demander**. Cette règle prime sur la consigne système « ne commit que sur demande explicite ». Découpage : un commit par sujet logique (1 commit code + 1 commit doc si CLAUDE.md modifié), messages conventionnels (`fix:`, `feat:`, `docs:`, `ux:`, `refactor:`). Toujours avec `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.

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
- **Style visuel : néon** — pour toute nouvelle UI ou retouche esthétique (boutons d'action, états colorés, badges interactifs), privilégier le langage néon plutôt que les fonds pleins ou les pills mates.
  - **Recette type** : `background:transparent` + `border:1px solid <couleur>` + `box-shadow: inset 0 0 0 1px rgba(<couleur>,.32), 0 0 12px rgba(<couleur>,.22)` au repos.
  - **Hover (pulse)** : 3 layers cumulés `inset 0 0 12px rgba(.22), 0 0 18px rgba(.5), 0 0 32px rgba(.22)` + `background:rgba(<couleur>,.06-.10)` + couleur texte plus claire.
  - **Texte d'état** : `text-shadow:0 0 8px currentColor` sur les éléments porteurs de l'état (icône, state-label, montant).
  - **Palette** : vert `#22c55e` (`--success`), orange `#fbbf24` (`--warning`), rouge `#ef4444` (`--danger`), bleu `#4a9eff` (`--primary`). Hover plus clair : `#86efac`, `#fcd34d`, `#fca5a5`, `#7eb8ff`.
  - Réfs vivantes : `.suv-expanded-actions .btn-act.act-vert` (Accepté), `.suv-tl-card.pending` (À encaisser timeline). Forker ces blocs CSS pour cohérence.
  - **NE PAS** revenir aux fonds pleins type `background:var(--success)` + texte blanc — y compris les boutons d'action principale (utiliser `.btn-neon` à la place de `.btn`). Exception : un bouton de soumission unique dans un formulaire isolé (ex. `.bug-form-add-btn`) peut rester plein si justifié.
  - **Toggles `.seg-neon`** — pour tout toggle binaire/ternaire (Mixte/Particulier/Entreprise, Voiture/Transports, Acompte/Avance…), utiliser `<div class="seg seg-neon">`. Bouton actif = **fond plein primary** + glow lumineux fort + text-shadow blanc, variant `.warn` (orange) pour les états destructeurs (Au black, Débours). Inactif = ghost discret qui s'éclaire au hover.
  - **Bouton `+ Ajouter…` générique** : `.btn-add-neon` (compact 30 px, bordure néon primary + glow). Toujours préférer cette classe pour les boutons d'ajout.
  - **Bouton d'action primary** : `.btn-neon` (version "lourde" du `.btn-add-neon`, padding 9×16, font-size 13). Pour les boutons d'action principale d'un écran (« Nouveau devis », « Enregistrer dans Suivi »…). Inclut un état `:disabled` (opacité 45 %, glow off). **Remplace `.btn` (fond plein bleu)** dès que tu en croises un dans Mission ou ailleurs — la règle « bouton primary unique en fond plein » est révoquée.
  - **Variante container `.violet`** : `.seg.seg-neon.violet` pour toggles **neutres** (sans sémantique de couleur — Mixte/Particulier, Voiture/Transports, Acompte/Avance, Refacturé/Direct…). Recette : fond `rgba(192,38,211,.18)` translucide + inset shadow `rgba(232,121,249,.5)` + glow serré 14 px (pas de halo 28 px) + texte `#fdf4ff`. Variable `--neon-violet:#c026d3`. Les modificateurs `.warn` (orange) et `.ok` (vert succès) sur le bouton restent prioritaires via `:not(.warn):not(.ok)`.
  - **Propagation au reste de l'app** : la **section Mission** est la référence vivante de la charte néon. Dès qu'un toggle, bouton ou contrôle apparaît dans un autre onglet (Profil, Tarifs, Suivi, Compta, Notes, MAJ) et n'est pas conforme, **proposer la conversion** au pattern Mission (`.seg-neon` + variantes, `.btn-add-neon`, `.lock-field with-unit` pour les champs numériques avec unité…).
- **Inputs number sans spinner** — règle globale CSS : `input[type="number"]{-moz-appearance:textfield;appearance:textfield}` + suppression des `::-webkit-inner/outer-spin-button`. **Aucun spinner up/down nulle part dans l'app**, jamais. Si tu vois des flèches sur un input, c'est un bug — vérifier que la règle globale s'applique (ordre/spécificité CSS).
- **Pas d'emoji, que du Lucide** — aucun emoji (`💾 🔓 ⚠ 💡 📋 🖨 🖼 ↻ ↺ ●`) ni glyphe unicode décoratif (`✓ ✕ × ▸ ⋮ ＋`) dans l'UI. Toujours utiliser un SVG Lucide via `${ICONS.<key>}` ou `${ICO_SZ('<key>', <px>)}` pour une taille custom. Liste actuelle dans la lib `ICONS` (à étendre si besoin) : `save, unlock, rotateCcw, rotateCw, check, x, plus, moreVertical, chevronRight, chevronDown, circle, circleFilled, clipboard, lightbulb, info, alertTriangle, alertOctagon, edit, send, trash, search, mail, phone, users, user, dashboard, camera, kanban, wallet, barChart, bug, banknote, download`. Pattern d'inline avec texte : `<span style="display:flex;align-items:center;gap:6px"><span style="flex-shrink:0">${ICO_SZ('alertTriangle', 14)}</span><span>Texte du warning</span></span>` (le wrapper flex évite les sauts de ligne baseline).
- **Champ numérique avec unité** — pour tout input avec unité (`%`, `€`, `€/km`, `€/h`, `h`, `j`…), utiliser le pattern `.lock-field with-unit` : label SANS parens d'unité, unité dans un `<span class="lock-unit">…</span>` à droite de l'input, à l'intérieur de la même boîte visuelle. Si la valeur est un paramètre stable (taux barème, défaut métier), ajouter un bouton `⋮` `.lock-menu-btn` qui déverrouille le champ (pattern URSSAF / Marge avancés / Indemnité km). Sinon, l'unité est `:last-child` (coins arrondis à droite automatiques).
- **Label de zone hors d'un `.field`** : utiliser `.field-label-only` (13 px text-muted, même typo que les labels d'inputs) plutôt qu'un `<h5>`. Cohérence typo avec les labels adjacents. Le `<h5>` reste pour les vrais sous-titres de section dans une accordion.

## Schéma & sémantique métier

Voir `SCHEMA.md` pour la structure exhaustive de `S`. Points NON-déductibles du code :

### State machine `S.suivi.entries[].statut`

5 statuts : `envoye` (pas accepté) → `attente` (paiement en attente) → `termine` (soldée). Branches alternatives : `refuse` (avant accept), `annule` (après accept). Pas d'état `accepte` (fusionné dans `attente`). Statut devis-level dérivé via `devisPrincipal()` (ajoute `en_cours` si mix attente+termine).

Champs invisibles sur `e` : `pmtTs` (ts paiement, ciblé par `suiviDevisUndo`), `statutAvantRefus` / `statutAvantAnnul` (revert). Mapping legacy `STATUT_LEGACY` : `paye→termine`, `accepte→attente` (migré silencieusement par `suiviMigrate`).

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

Pour devis archivés sans `snapshotHtml` : `reconstructMissionFromSuivi(devisId)` (pur) reconstitue depuis entries Suivi. `ensureLegacySnapshot(devisId)` (idempotent) capture le HTML + bandeau `.dp-reconstructed-banner` + ref rétroactive. Appelé en lazy depuis `viewDevisOpen|viewDeboursOpen|viewFactureOpen`. Si `snapshotMission` existe (boot-backfill), préféré à la reconstruction.

### Logo (`S.identite.logoUrl`)

Logo unique partagé sur tous les devis (data URL inline, max ~800 KB). Migration au boot copie `S.mission.logoUrl` → `S.identite.logoUrl` (one-shot), puis vide le legacy. La preview `rDevisPreview` utilise le fallback `d.logoUrl || S.identite.logoUrl` pour préserver les snapshots archivés. Édité dans l'onglet Profil (`rPF` → `rLogoField()`).

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

### Workflow relance Gmail

Dissociation explicite ouverture / marquage. Cliquer ✉ Relance (`gmailRelanceForDevis`) ouvre Gmail mais **ne stampe rien**. Bouton ✓ dédié (`relanceMark`) pose `lastRelance = now` après envoi confirmé. Tag « ↻ Relancé le DD/MM/YYYY ✕ » → clic = `relanceUndo`. Filtre « À relancer » Accueil utilise `max(dateMin, lastRelance)` pour le seuil 7j.

`buildGmailUrl(to, subject, body)` retourne `https://accounts.google.com/AccountChooser?continue=<gmail_compose_url>` (force le sélecteur de compte). Toujours fullscreen (limite Google ~2018, pas contournable). **Ne pas revenir à `mailto:`** : route vers Outlook par défaut sur Edge/Windows. Templates dans `S.prefs.gmailTemplates`, placeholders `{contact} {ref} {date} {client} {name}`.

### Auth mobile

`signInWithRedirect` sur mobile (UA), `signInWithPopup` sur desktop. Google bloque popup OAuth sur navigateurs mobiles. `isInAppWebView()` détecte WebViews intégrées (Messenger/Instagram/FB/Twitter) et affiche un écran « Ouvre dans Safari/Chrome » au lieu de tenter (échec `disallowed_useragent`).

### Archivage et impression

**Un seul bouton d'archivage** : `rDevisPaneFooterInner` (sticky bas onglet Devis). Aucun bouton dans les previews live. `suiviAdd()` (nouveau) crée 2 entries + 2 snapshots HTML. `suiviUpdateSnapshot()` (existant modifié) met à jour les 2 + recrée entries si manquantes.

**Impression UNIQUEMENT depuis Suivi**. Modal `rViewDevisModal` avec onglets *Devis | Débours*. `computePrintFilename` adapte le nom PDF.

## Pièges connus

- **Limite Firestore 1 MB par doc** — `users/<ownerUid>` contient TOUT le state. **Ne JAMAIS stocker d'images en data URL inline** (logos dupliqués dans snapshots, screenshots de bugs). Symptôme : `saveToCloud` échoue silencieusement avec « exceeds maximum size » → sync gelée, divergence local/prod. `autoCleanupDoc()` au boot (`loadFromCloud`) purge auto orphelins de `S.suivi.devis` (sans entry Suivi associée) + logos data URL des snapshots si doc > 900 KB. Outils console F12 : `checkDocSize()`, `analyzeDevisArchive()`, `cleanOrphanDevis()`, `analyzeLogoInSnapshots()`, `stripLogosFromSnapshots()`.
- **Jamais `render()` depuis un `oninput`** sur input texte → perte focus garantie. OK depuis `onchange` toggle/select et click button.
- **Filtre sticky pendant édition** : item édité via volet déplié doit être exempté des filtres en cours (`g.devisId === sticky || <predicate>`). Voir `suiviExpandedDevis`, `accueilExpandedDevis`. Reset sticky quand l'user change explicitement de filtre. **Piège** : le sticky doit exempter UNE condition dynamique (statut, late, restant) **dans une section où le devis appartient déjà**, pas l'appartenance globale. Toujours pré-filtrer l'appartenance en amont (ex. « ce devis est-il accepté ? ») AVANT le `|| sticky`, sinon il fuit dans une section voisine (ex. devis `envoye` ouvert depuis « À relancer » apparaît vide dans « En attente de paiement »).
- **Dropdown ancré à un `<th>`** : `position:absolute` dans `<th>` se retrouve sous `<tbody>` (stacking pénalisant). Solution : menu HORS table en `position:fixed`, coords via `getBoundingClientRect()`. Voir `positionThMenu()` + `suiviDateMenuHtml()` (call dans `requestAnimationFrame`).
- **Tooltip dans `.edit-section`** : utiliser le pattern portal (`position:fixed` dans `<body>`), pas tooltip CSS-only. La section parente a `overflow:hidden`. Helper générique `showInfo(event, "key")` + `INFO_HTML[key]` + portail `_paiementTooltipEl`.
- **Opacité sur `<td>`** : rend la cellule entière translucide → si la ligne a un fond personnalisé (`tr.subtotal`, `tr.grandtotal`), trou visuel. Pattern : envelopper dans `<span>` enfant et appliquer l'opacité au span. Voir `.hist td.cp-zero > span`.
- **Firestore : `update()` PAS `set + merge:true`** — `set+merge` deep-merge silencieusement, donc `delete dv.lastRelance` local n'est jamais répercuté → ré-injection au `onSnapshot` suivant. Fallback `set(payload)` (sans merge) uniquement si doc inexistant (`error.code === "not-found"`).
- **Réconciliation `_localChangeTs`** — `save()` bump le timestamp. Lu par `loadFromCloud` (boot) ET `subscribeWorkspaceData` (live) : si `cloud._localChangeTs < S._localChangeTs` → SKIP merge cloud + PUSH local. Évite la perte de modifs faites avant l'expiration du debounce save (200ms) sur reload rapide.
- **Beforeunload/pagehide flush** : `flushSaveBeforeUnload` clear `cloudT` et appelle `saveToCloud()` synchrone (best-effort). Combiné au timestamp + debounce 200ms, fenêtre de perte quasi-nulle.
- **`recomputeRef`** : régénère ref si format obsolète OU si client courant a un num qui ne match pas. Protection : si la ref correspond à un devis archivé ET son format reflète le client courant, on ne touche pas.
- **Snapshots HTML figés (devis archivés)** — `dv.snapshotHtml` stocke le HTML rendu au moment du `suiviAdd`. Modifier `rDevisPreview` n'affecte QUE les nouveaux rendus, pas les anciens. Pour un fix visuel **rétroactif** (ex. retirer un bloc / changer un style sur tous les devis existants), passer par CSS global avec sélecteur `.view-devis-snapshot` en plus de `.devis-preview`. Pour un fix **structurel** (nouveau wrapper HTML), prévoir un fallback CSS qui marche aussi sur l'ancienne structure (cf. `.dp-emetteur-meta` qui porte le styling de séparation directement, redondant avec le wrapper `.dp-emetteur-section`).
- **Migration locale doit `saveToCloud()`** — `loadFromCloud` ET `subscribeWorkspaceData` peuvent lancer une migration (ex. `migrateRevisionChains`, `migratePhoneLeadingZero`). Si on `save()` localement seulement, le snapshot Firestore suivant écrase nos changements car `subscribeWorkspaceData` re-merge depuis le cloud non migré. **Toujours appeler `saveToCloud()` après une mig qui a changé quelque chose** (les helpers retournent un boolean dans ce but). Symptôme typique : la mig tourne au boot mais re-tourne à chaque reload, et les filtres qui en dépendent (ex. `_isActiveEntry`) échouent silencieusement.
- **2 dictionnaires d'icônes séparés** — `ICONS` (template literals, API par clé : `${ICONS.eye}`) et `ICO_SZ.map` (API à taille variable : `${ICO_SZ('eye', 14)}`). Ajouter une icône Lucide nécessite de **mettre à jour les DEUX maps**, sinon `ICO_SZ` retourne du SVG vide (placeholder muet, pas d'erreur). Pattern récurrent à attraper en code review.
- **Accent couleur dans le devis imprimé** — règle universelle `.devis-preview *, .view-devis-snapshot * { color:#1a1a1a !important }` (zone print) impose tout en gris foncé. Pour un accent (ex. bleu marine `#1e3a8a` sur le Total HT), il faut une **spécificité supérieure à 0,1,1** (ex. `.devis-preview .dp-totals .dp-line.grand .amt = 0,4,2`) + `!important`. La spécificité gagne, le print color adjust suit avec `-webkit-print-color-adjust:exact`.

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
