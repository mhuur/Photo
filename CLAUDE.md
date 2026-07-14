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

**Navigation — `NAV` = source unique** : sidebar en 2 groupes dépliables (`Mission` : Suivi devis / Nouveau devis / Catalogue / Clients / Mon Profil — `Comptabilité` : Bilan comptable / Historique / Achats). `TABS` en est **dérivé** (`NAV.flatMap`), et `pageTitle()` en découle → renommer un label dans `NAV` propage à la sidebar, au h1 de la page ET au select « onglet concerné » des Notes (`BUG_TAB_OPTIONS`, dérivé lui aussi). ⚠ Les **clés** d'onglet (`accueil`, `mission`, `compta`, `suivi`…) ne changent JAMAIS : tous les `setTab('suivi')` du code en dépendent. Seuls les labels et le regroupement bougent. Les `id` de groupe sont préfixés `nav-` car le groupe « Mission » contient un onglet dont la clé est aussi `mission`. Onglet secondaire (menu user, hors sidebar) → `TABS_AUX_LABELS`.

- **Accordéon au CLIC** (`.sb-group.open`), le groupe reste ouvert jusqu'au clic suivant ; plusieurs groupes peuvent l'être. `setTab` déplie le groupe de l'onglet ciblé (navigation programmatique : `missionTerminer` → Historique) sans refermer les autres. ⚠ **Jamais de dépliage au `:hover` sur un accordéon inline** : le contenu pousse les groupes du dessous, donc sortir d'un groupe le referme, tout remonte et la souris se retrouve dans le vide (reflow). Les vraies apps réservent le survol aux **panneaux flottants** (position absolue, qui ne poussent rien) — VS Code / Notion / Linear utilisent le clic pour l'inline.
- **État de pli TRANSIENT** (`_navGroupOpen`, variable module, **jamais dans `S`**) : il survit à la navigation mais pas au reload. ⚠ **Ne JAMAIS le persister** : passer par `S` + `save()` faisait clignoter « Enregistré » (le flash vient de `saveToCloud`) à chaque dépliage et polluait le doc Firestore. Règle générale : **toute interaction purement visuelle reste hors de `S`**.
- **Icônes uniques** : chaque icône n'apparaît qu'UNE fois dans la sidebar, groupes compris (une icône partagée entre un groupe et l'un de ses enfants rend le menu illisible).
- **Repère « brouillon » = un POINT ember, jamais un mot** (`.brouillon-tag`, mot conservé en `title`). La sidebar fait 216 px : une pastille texte « BROUILLON » faisait passer « Nouveau devis » sur 2 lignes, et sur l'en-tête de groupe replié elle poussait le chevron hors du cadre. Il est remonté sur l'en-tête tant que le groupe est replié, sinon il serait invisible.
- **Pied de sidebar (`.sb-foot`)** : « Bugs & suggestions » (onglet de 1ᵉʳ niveau) + « Mon compte » (menu inline). Le menu résiduel (Templates, Paramètres, Mises à jour, Corbeille, Déconnexion) sera absorbé par l'onglet `compte` en phase 6.
- **« Nouveau devis » (`missionOpen`)** : l'onglet Mission est désormais TOUJOURS visible, alors qu'il était masqué hors brouillon. Le clic ne doit ni écraser un brouillon, ni rouvrir le DERNIER DEVIS ARCHIVÉ (qui reste chargé dans `S.mission` après `suiviAdd` → il serait rouvert en mode « mise à jour »). Règle : brouillon ou édition/révision en cours (`editDevisId`/`revisesDevisId`/`majTrameDevisId`) → on ouvre tel quel ; sinon → `missionNew()` (table rase).

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
### Charte V2 — palette Saintilann (refonte 2026-07, maquette `Refonte V2 - Compact.dc.html`)

L'ancienne palette navy/indigo est **révoquée**. Base near-black + 3 accents échantillonnés sur les photos de la marque. Tous les tokens sont dans le 1ᵉʳ `:root` d'`index.html` — **ne jamais réintroduire de littérale de couleur hors de ce bloc** si un token existe.

- **Ink** (neutres) `--ink-950 #08070A` → `--ink-000 #F6F4FA`. **Azure** (accent primaire) `#042480 → #45C1FD`. **Jade** (positif) `#03665E → #02DCB9`. **Ember** (alerte) `#8A1E06 → #F5943C`.
- ⚠ **`--primary` = `#45C1FD` (azure-300), un cyan CLAIR** : il est utilisé ~220× en couleur de **texte/bordure** sur near-black et seulement ~10× en fill. **Ne JAMAIS s'en servir comme remplissage sous un texte blanc** (contraste cassé) → utiliser **`--azure-fill` `#0A56E0`** (hover `--azure-fill-hi` `#2E86F0`). Les simples pastilles colorées sans texte (`.pst`, `.dv-dot`) gardent `--primary`.
- `--surface` reste **OPAQUE** (dropdowns, modales, `<option>` en dépendent). Pour un panneau translucide qui laisse respirer la photo de fond → **`--surface-glass`** (`rgba(26,24,34,.85)`) ou la classe `.v2-panel`.
- **Typo** : `--font-display` = **Big Shoulders Display** (titres, UPPERCASE, `line-height:.92`, pas de glow — le néon Tilt Neon est **abandonné**) ; `--font-mono` = **Space Mono** (eyebrows, labels de section, métadonnées, tracking `.16em`) ; **Inter** pour le corps et les chiffres tabulaires. Primitives : `.v2-display`, `.v2-eyebrow` (commence par un tiret cadratin), `.v2-label`, `.v2-meta`, `.v2-page-head`, `.v2-panel`.
- **Fond photo** : `body` porte la photo de marque (`assets/*.jpg`) sous un voile. Piloté par `S.prefs.bgPhoto` + `S.prefs.bgScrim` → `applyBgPhoto()` pose `html[data-bg]` et `--bg-scrim` (appelé depuis `render()`, donc couvre boot + merge cloud + live sync). Console : `setBgPhoto("azure-helmet"|"ember-parking"|"jade-portrait"|"none")`, `setBgScrim(0.78)`. **Aucune image en data URL** (limite Firestore 1 MB) — ce sont des fichiers servis.
  - ⚠ **Le voile ne peut descendre que si le contenu est en panneaux.** Défaut `.84` : c'est un compromis tant que Profil / Catalogue / Compta affichent du contenu « nu » directement sur la photo. Une fois toutes les vues passées en `.v2-panel` (phases 3→6), on pourra descendre vers `.75` sans perdre en lisibilité.
  - **`--field-bg` (quasi opaque)** : tout fond de champ de saisie passe par ce token. Un input translucide posé sur la photo laisse l'image transparaître au travers et devient illisible.

- **En-tête de page = `v2PageHead(tabKey, { titleHtml?, actions? })`** — SOURCE UNIQUE, plus aucun `<h1 class="page-title">` en dur. Le surtitre vient de `TAB_EYEBROW`, le titre de `pageTitle()` (donc de `NAV`). Le flash « Enregistré » (`#savedFlash`) est toujours injecté dans la zone d'actions — plusieurs renderers le ciblent **par id**, ne pas le retirer.

- **Boutons d'action = famille unique `.mk-btn`** (le néon `.btn-neon` reste du legacy, converti au fil des zones touchées ; **ne plus créer de bouton néon**) :
  - `.mk-btn.green` (`--success-dark` = jade `#0E9E86`, texte blanc) — valider une étape positive (« Accepté », « Paiement reçu »).
  - `.mk-btn.blue` / `.mk-btn.azure` (`--azure-fill` `#0A56E0`, texte blanc) — action primaire / jalon neutre.
  - `.mk-btn.subtle` (`--surface-sunken` + bordure `--border`) — action secondaire (« Envoyer », « Relancer », « Devis PDF »).
  - `.mk-btn.ghost` (transparent + bordure/texte ember `#F08C4B`) — action négative (« Refusé »).
  - `.mk-btn.cta` — variante mono uppercase pour les CTA d'en-tête (« + Nouveau devis »).
  - `.mk-iconbtn.sm` / `.md` — boutons icône carrés (↺, ⋮). Hover = `filter:brightness(1.09)`, active = `translateY(1px)`, `:disabled` = 45 %.
- **Néon = legacy, pas de big-bang** — `.btn-neon` / `.btn-add-neon` et les toggles `.seg-neon` restent en place ; on les convertit à `.mk-btn` **au fil des zones touchées**, jamais en masse. Ils ont déjà la bonne palette (ils lisent les tokens), seule leur forme (halo, glow) est datée. Les segmented controls `.seg-neon` (Mixte/Particulier/Entreprise, Voiture/Transports, Acompte/Avance, variante `.violet`) ne sont pas couverts par la bascule boutons — à traiter séparément.
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

### `S.mission.mode` — Devis vs Prestation rapide

`"devis"` (défaut, absence = devis → aucune migration) | `"quick"`. Figé à l'archivage dans `snapshotMission.mode` ET `S.suivi.devis[id].mode`. Lu via `isMissionQuick()` (brouillon courant) / `isDevisQuick(devisId)` (archivé).

Le mode rapide = **aucun document** (ni devis, ni feuille débours, ni facture), pas d'acompte, pas de cession, pas de CGV. Il ne court-circuite RIEN d'autre : mêmes entries Suivi, même bilan, même compta de caisse.

**Statut fiscal : plus AUCUN choix dans le formulaire.** Le toggle « Déclaré / Au black » a été supprimé (avec `updMissionDeclare` / `updBlackMode`). Règle : **devis ⇒ toujours déclaré**, **prestation rapide ⇒ toujours au noir**.

- `missionIsDeclared(m)` est la **source unique** : renvoie `false` dès que `mode === "quick"`, sans muter `m.declare`. ⚠ **Tout code qui teste `declare !== false` doit passer par elle** — sinon une prestation rapide serait déclarée dans une moitié de l'app (CA fantôme) et au noir dans l'autre.
- `m.declare = true` est **reforcé** dans `missionNew` / `missionSetMode(devis)` / `missionCancel`. Indispensable : `S.mission` conserve le `declare:false` d'un ancien devis au black rouvert en Éditer/Réviser, et sans ce reset **tous les devis suivants seraient au noir en silence** (plus aucun toggle pour s'en apercevoir).
- **Les devis archivés au black gardent leur statut** (`snapshotMission.declare = false` ⇒ entries `ca=0`, historique fiscal immutable). Rouverts en édition, ils affichent un bandeau `.black-warning` en LECTURE SEULE — jamais de bascule proposée.

**Prix = catalogue brut − remise, zéro majoration.** L'au-noir neutralise déjà `margeAvancePct`/`margeUrssafPct` (la « majoration URSSAF » = gonflement inverse `prix / (1 − 22 %)` appliqué au matériel/déplacement principal dans `ligneDisplayInfo`). Il restait 2 leviers qui auraient modifié le tarif horaire au noir : `blackMode === "reduit"` (× 0,78) et `remiseNoirePct` — **neutralisés pour `quick` dans `totals()`** (`_quick`). Un matériel à 100 € se facture donc 100 € en rapide, contre 128,21 € en devis déclaré.

Formulaire rapide (allégé au maximum) : réf, date d'émission, client, catalogue + tarif, heures, matériel, déplacement, remise. **Retirés** : durée de validité, date de prestation, type de clientèle, contrat hors établissement, statut fiscal, taux URSSAF, marge sur avances, toggles Principal/Débours et Acompte/Avance (sans majoration, ils ne pilotent plus rien).

- **Échéancier forcé** : `QUICK_ECHEANCES` = 1 ligne `ech-full` à 100 % ⇒ `buildEcheanceLines` produit une entry unique (`isSolde`) ⇒ **zéro étape acompte**, sans code dédié. `missionNew`/`missionSetMode`/`missionCancel` restaurent l'échéancier par défaut au retour en mode devis (`isQuickEcheancier` détecte l'héritage) — sinon l'acompte disparaît silencieusement du devis suivant.
- **Parcours** : `isDevisSansFacture(devisId)` = `isDevisAuNoir || isDevisQuick` = **source unique** du saut des étapes facture. Combiné à l'échéance unique, `devisParcoursSteps` produit exactement envoyé → accepté → réalisée → payée → livrée. ⚠ **Cette condition doit être respectée par les gardes d'ordre** (`suiviLigneTogglePaiement`, `suiviMarkLivree`) : exiger une facture de solde qui ne peut pas exister rend l'encaissement **définitivement impossible** (bug attrapé en test).
- **Refs `PRE-YYYYMM-NNN`**, séquence indépendante des `DEV-`. Tout code qui *valide* un format de ref doit connaître `PRE-` — sinon il la réécrit : `recomputeRef`, `formatRef(ref, "presta")`, **`suiviRecomputeRefs`** (tourne au boot : sans le motif `PRE-`, chaque prestation rapide était renommée en `DEV-` au démarrage suivant), `ensureLegacySnapshot`.
- **`DEVIS_DOC_BLOCKS`** (`cgv, cgvPreambule, cgvSections, signatureBlock, conditionsPaiement`) sont **strippés du snapshot** en mode rapide (~10 KB/presta sur un doc Firestore plafonné à 1 MB). Contrepartie obligatoire : `editDevisStart`/`reviseDevisStart` les **restaurent** depuis la mission courante (`devisBlocksPick` avant écrasement → `devisBlocksRestore` après), sinon les CGV disparaissent de S.mission et du prochain devis rédigé.
- Le mode est **immuable après archivage** (barre de mode masquée si `devisCurrentSuiviEntry()`).

### Au noir vs déclaré (CRITIQUE — faute fiscale possible)

Par entry : `e.montant` = encaissé total (toujours rempli). `e.ca` = part déclarée (0 si au noir). `e.ursaf` = 0 si au noir. `e.salaire`/`e.tresorerie` = remplis quel que soit le statut.

`bilanCompute()` : colonne **Payé** = Σ `montant`, colonne **CA** = Σ `ca` (seuils micro-BNC/TVA). **Ne jamais utiliser `montant - frais` comme fallback pour `ca`** : `ca=0 ∧ montant>0` est volontaire. Promouvoir = faute fiscale.

`S.mission.declare` (true par défaut) câble la décomposition à `suiviAdd()`. Pas de facture sur devis au noir : `isDevisAuNoir(devisId)` bloque `isFactureApplicable` + `viewFactureOpen` + UI.

**Plage mois bilan** : `bilanCompute()` génère TOUS les mois entre 1ʳᵉ activité (entry/abo/matériel) et aujourd'hui, sinon les mois sans encaissement mais avec abos/amort actifs sont oubliés.

### Rattachement des recettes = date d'ENCAISSEMENT (compta de caisse)

Micro-BNC = **comptabilité de caisse** (art. 93 CGI) : une recette est rattachée à la date où l'argent arrive, JAMAIS à celle de la prestation ni de la facture. `bilanCompute()` ne prend que les entries `termine` et les range via **`entryEncaissementDate(e)`** — cascade : `e.datePaiement` (saisie/corrigée par l'user, source de vérité) → `e.pmtTs` (horodatage du clic « payé », backfillé par `migrateDatePaiement`) → `e.date` (repli legacy : entries encaissées avant l'existence des 2 champs — garde leur rattachement historique, on ne re-attribue PAS des exercices déjà déclarés).

- `e.date` reste la date de **prestation/devis** — ne jamais l'utiliser pour du fiscal.
- `e.datePaiement` (YYYY-MM-DD) : posée par `suiviLigneTogglePaiement`, éditable via l'input date de la ligne d'échéance (`suiviSetDatePaiement`). **Invariant : `statut ≠ "termine"` ⇒ pas de `datePaiement`/`pmtTs`** — nettoyés à toutes les transitions arrière (`suiviLigneTogglePaiement`, `suiviDevisUndo`, `suiviDevisAccepter`, revert d'acceptation).
- Les colonnes non monétaires (heures) suivent l'argent : une ligne du bilan décrit l'activité qui a produit l'encaissé de CE mois.
- **`isoDateLocal(d)` et PAS `toISOString()`** pour dater un paiement : `toISOString` décale d'un jour le soir (UTC) — un encaissement du 31/07 à 23 h basculerait en août, donc de mois, voire d'année.
- **Ne JAMAIS recréer une entry Suivi existante** — toute fonction qui « recalcule les entries » d'un devis (`suiviUpdateSnapshot`) doit **muter** les entries appariées (par `echId`, repli positionnel), pas les remplacer par des objets neufs. Un `mkLine()` qui ne reporte que `statut` efface `datePaiement`/`pmtTs` ⇒ `entryEncaissementDate` retombe sur le repli `e.date` (= mois du **devis**) et re-rattache au mauvais mois une recette déjà déclarée. **Faute fiscale silencieuse** (le champ date de la ligne affiche le repli, donc rien ne se voit). État de paiement à préserver : `statut, pmtTs, datePaiement, dateRemboursement, statutAvantRefus, statutAvantAnnul, commentaires`. Corollaire : une entry `entryEncaisse()` ne doit jamais être supprimée par une édition (garde-fou `orphansPaid` → `uiAlert` bloquant).
- Tout ce qui somme des recettes (KPI Accueil, bilan, jauges seuils micro-BNC/TVA) passe par `bilanCompute` → suit automatiquement.

**Annulation d'un devis avec acompte encaissé** : l'argent est entré, il RESTE dans le CA de son mois — `entryEncaisse(e)` compte aussi les entries `annule` dont `statutAvantAnnul === "termine"`. (Avant, `suiviDevisAnnuler` les faisait disparaître du bilan → sous-déclaration.) Le sort de l'acompte est demandé à l'annulation (`uiChoice` : client se désiste = conservé / tu annules = remboursé) :
- **conservé** → rien, la recette est acquise ;
- **remboursé** → `e.dateRemboursement` (YYYY-MM-DD) ⇒ `bilanCompute` émet une contribution **négative** sur le mois de CETTE date (régularisation URSSAF), jamais sur le mois d'origine. Les **heures ne sont pas négativées** (seul l'argent se régularise). Modifiable après coup (`suiviToggleRemboursement` / `suiviSetDateRemboursement`), nettoyé par `suiviDevisRevertAnnul`.
- ⚠ Le filtre de fin de `bilanCompute` teste `!== 0` et **pas `> 0`** : un mois ne contenant qu'un remboursement n'a que des valeurs négatives et doit rester visible.

### Arrondi commercial (`S.mission.arrondi`)

`{ mode: "none"|"palier"|"cible", palier: "1"|"5"|"10"|"50"|"100", sens: "proche"|"inf"|"sup", cible }`. Calculé par `computeArrondi(m, totalAvantArrondi)` → `{ montant, step, target }`, appliqué dans `totals()` **après la remise** : `total = subtotal − remise + arrondi`. Figé dans `snapshotMission` (archives immuables), remis à zéro par `missionNew`/`missionCancel` (c'est un choix propre au devis, pas une config).

**L'arrondi porte sur le TOTAL, jamais poste par poste** — 3 raisons, toutes contre-intuitives :
1. Arrondir chaque ligne ne donne PAS un total rond (412 + 388 + 387 = 1187). Le client demande un total rond.
2. **Ne jamais tordre `tarifH`** pour tomber juste : `suiviAdd` dérive la trésorerie de `tauxAvecSecurite / tarifH` → un tarif bricolé décale silencieusement la répartition salaire/trésorerie/URSSAF de toutes les entries.
3. **Jamais sur les débours** : refacturés au centime près sur justificatif (CGI 267-II) — les arrondir leur fait perdre leur nature juridique. `computeArrondi` ne touche que `total`, `debours` est calculé à part → protégé par construction.

**Échéances = source unique `buildEcheanceLines`** (signature : `(echeances, total, hoursTotal, step)`). ⚠ `totals().echeances` était un **second calcul parallèle** (`total × pct / 100`) : le devis imprimé pouvait annoncer un acompte de 358,47 € pendant que la compta enregistrait 360 €. Il en dérive désormais. Le `step` arrondit les ACOMPTES au même palier, **le solde absorbe l'écart** ⇒ `Σ montants = total exact` (invariant vital : CA, seuils micro-BNC). Les **heures ne sont pas arrondies** (seul l'argent l'est). `echeancesTotal` reste lu sur la CONFIG, pas sur les lignes — sinon le fallback « ligne unique à 100 % » ferait passer à tort la validation « les échéances totalisent 100 % ».

Garde-fou marge : la **remise EFFECTIVE** (`(subtotal − total) / subtotal`, donc remise + arrondi) est comparée au point mort `computeRemiseInfo().remiseMaxPct` — warning dans `validateDevis` et dans le bloc.

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
- **Icônes : une seule source `ICO_PATHS`** — `ICONS` (`${ICONS.eye}`, 18 px) et `ICO_SZ` (`${ICO_SZ('eye', 14)}`, taille libre) en **dérivent** tous les deux. Ajouter une icône Lucide **dans `ICO_PATHS` et nulle part ailleurs**. (Avant 2026-07 c'était 2 maps séparées et `ICO_SZ.map` un sous-ensemble d'`ICONS` : toute icône ajoutée d'un seul côté rendait un SVG **vide**, sans erreur. `ICO_SZ` loggue désormais un warn sur clé inconnue.)
- **Conteneur print en `display:flex`** — `.devis-preview`/`.view-devis-snapshot` sont en flex column à l'impression (pour `dp-spacer` qui pousse la signature en bas de page du devis). **Chrome ne fragmente pas correctement un conteneur flex : il IGNORE les `break-inside:avoid` de ses enfants** → encadrés coupés entre 2 pages. Sur les documents sans spacer/signature (factures : `.view-facture` en `display:block`), repasser le conteneur en bloc pour retrouver une pagination fiable. Si un nouveau type de doc imprimable apparaît sans signature → même traitement.
- **`#app` est en `display:flex`** — tout écran « plein page » (login, pending, denied, loading) doit poser **`flex:1;width:100%`**, sinon il ne s'étire pas et ne couvre qu'une bande large comme son contenu. Le bug était invisible tant que ces écrans recopiaient le fond du `body` ; il saute aux yeux depuis que le `body` porte la photo. Corollaire : leur fond doit rester **transparent** (ils laissent voir la photo).
- **`gen-schema.py` : commentaires dans `DEFAULT_S`** — le scanner d'accolades saute désormais les `//` (corrigé 2026-07). Avant, une **apostrophe française dans un commentaire** (« l'app ») ouvrait une fausse chaîne, l'équilibrage des accolades partait en vrille et `SCHEMA.md` échouait avec un « Extra data » cryptique. Si un jour un `/* … */` apparaît dans `DEFAULT_S`, il faudra l'ajouter au scanner.
- **Bordures du devis imprimé** — la règle `.devis-preview *, .view-devis-snapshot * { color:#1a1a1a !important }` ne couvre **pas** `border-color`. Filet posé dans le bloc print : `.devis-preview *, .view-devis-snapshot * { border-color:#ccc !important }` (spécificité 0,1,1 → toutes les règles print ciblées `.devis-preview .dp-…` = 0,2,0 gardent la main). Indispensable depuis que `--border*` est en **blanc translucide** : sans lui, les encadrés imprimeraient une bordure invisible.
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

## Refonte V2 — état d'avancement

Maquette de référence : **`Refonte V2 - Compact.dc.html`** (racine). Refonte en 7 phases, validation utilisateur entre chaque.

- [x] **Phase 0 — Socle graphique** : tokens `:root`, typos, fond photo, `.mk-btn` recalé, filet print. Cf. § Charte V2.
- [x] **Phase 1 — Coquille** : sidebar 216 px (wordmark, groupes mono, footer Bugs + Mon compte), en-tête `v2PageHead()`, `ICO_PATHS` unifié.
- [ ] **Phase 2 — Accueil** : KPI dans le header + **timeline VERTICALE** du parcours devis (remplace la frise horizontale `suiviParcoursHtml` ; toujours générée depuis `devisParcoursSteps`, actions sur l'étape active uniquement).
- [ ] **Phase 3 — Mission** : mode cards Devis/Rapide, sections 01→06, **récap sticky à droite** (remplace la toolbar), aperçu devis à la demande.
- [ ] **Phase 4 — Historique + Clients** : table à chips de filtre **avec volet déplié conservé** (partagé avec l'Accueil) ; Clients en master-detail.
- [ ] **Phase 5 — Compta + Achats** : bandes de KPI, table reskinnée, toggle Tableau/Graphe.
- [ ] **Phase 6 — Profil + Bugs + Mon Compte** : nouvel onglet `compte` qui absorbe `rMAJ` + `rParametres` + `binModal` + backup/partage (le menu user disparaît). Sélecteur de photo de fond ici. Templates Gmail → Profil.
- [ ] **Phase 7 — Cleanup** : convergence des derniers boutons néon, styles morts, archivage de la maquette.

**Décisions actées** (ne pas re-litiger) : timeline verticale partout · Historique garde son volet (sinon plus d'accès au rewind / dates d'encaissement / remboursements sur les devis clos) · page Mon Compte consolidée · Catalogue en piste « Grille » (drag & drop + groupes conservés), les barèmes cession/matériel de la maquette sont une **feature future** hors refonte.

## Méthode de travail

- **Refonte UX multi-zones en N étapes** : pour toute refonte qui touche plusieurs sections (ex. in-place editing CGV), proposer un plan en 3-4 étapes avec validation entre chaque (« étape 1 schéma + helpers / étape 2 zones simples / étape 3 cas complexes / étape 4 cleanup »). Évite les commits monstres et permet à l'utilisateur de tester progressivement.
- **Découpage en phases** pour toute tâche non triviale : audit / proposition / exécution. Stop explicite à la fin de chaque phase, attente "OK".
- **Audit en UI pour grosses refontes** : injecter aussi le diagramme/audit dans l'app (bloc `<details>` collapsible). Retirer à la fin.
- **Audit + proposition obligatoires (même en auto mode)** pour : navigation/menu, schéma `S`, suppression > 50 lignes, `sed` ou Edit multi-zones.
- **Challenger** bienvenu : propose alternatives/questions, sépare clairement de ce que je demande, indique : maintenant / plus tard / juste à noter.
- **Demander plutôt que deviner** sur les points métier (statut fiscal, conventions, intentions produit).
- **Smoke test hors navigateur (flux métier)** : `check.sh` ne valide que la syntaxe. Pour un flux à plusieurs étapes (archivage, parcours, gardes d'ordre, bilan), charger le `<script>` inline d'`index.html` dans un contexte `vm` Node avec DOM/Firebase/localStorage bouchonnés (Proxy permissif + `firebase.auth.Auth.Persistence`), puis piloter `S` directement. ⚠ Les `const`/`let` top-level vivent dans la portée **lexicale** du contexte, PAS sur l'objet sandbox → les récupérer par `vm.runInContext("({S, totals, ...})")`. Les `function` top-level, elles, sont des props du global → `save = () => {}` les neutralise. A attrapé un bug bloquant (solde inencaissable) qu'aucune relecture n'avait vu. Script jetable dans le scratchpad, pas dans le repo.
- **Sanity check** : `./check.sh` après tout `sed` ou Edit multi-zones, **avant** `git commit`. Il inclut désormais un **parse JS réel** (node + `vm.Script` sur chaque `<script>` inline) : une erreur de syntaxe tue le script entier → **page blanche**, et le comptage d'accolades ne la voit pas. Cas typique attrapé : `const x` redéclaré dans la même portée (ex. réutiliser un nom déjà destructuré en tête de fonction — `isAnnule` dans `suiviParcoursHtml`). **Avant de déclarer une variable dans un renderer long, vérifier que le nom est libre** (`grep -n "const <nom>"`).
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
