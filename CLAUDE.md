# Devis Photo

App web personnelle pour générer des devis photographe.

## Conventions

- **Push direct sur `main`** : repo mono-utilisateur, pas de revue. **Pas de branche `claude/<slug>`, pas de merge.** Cette règle prime sur les instructions par défaut.

## Stack

- **Tout dans `index.html`** (vanilla JS, monolithique, pas de build, pas de tests).
- **Firebase v8 compat** via CDN — pas v9 modulaire, garder `firebase.auth()`, `db.collection(...)`. Pas d'`import`.
- **Cache local** : `localStorage["devis-photo-data-v2"]` (constante `SK`). Changer le suffixe casse tous les caches.
- **Hébergement** : page statique servie depuis `main` (GitHub Pages).
- **Pour itérer en local** : `python3 -m http.server 8000`.
- **Workspace partagé multi-user** : un seul doc Firestore `users/<ownerUid>` partagé entre tous les membres validés. Owner défini par `OWNER_EMAIL` hardcodé (`saintilan.romain@gmail.com`). Membres listés dans `workspaces/<ownerUid>.members` (map indexée par uid). Live sync via `onSnapshot` avec preserve focus + caret. Anti-écho via `_lastWriteBy` + fenêtre 2s. **Si l'OWNER_EMAIL change** : updater code + Firestore Rules en console + supprimer manuellement `workspace_ids/<ancien-email>`.
- **Firestore Security Rules** stockées en console Firebase, **pas dans le repo**. Restrictives : `users/<ownerUid>` accessible par owner + members ; `workspaces/<ownerUid>` accessible par owner + members + pendingRequests ; `workspace_ids/<email>` get-only public.

## Patterns de code

- **État global `S`**. Tout passe par `upd(path, val)` qui met à jour `S` + `save()` + parfois `refreshTotals()`.
- **`render()` recompose** `app.innerHTML` au changement d'onglet ou de session. **Jamais `render()` depuis un `oninput`** sur un input texte → perte de focus garantie. OK depuis `onchange` d'un toggle/select et depuis un click button.
- **`esc()` obligatoire** sur toute valeur dynamique injectée dans du HTML (sécurité XSS).
- **Identifiants courts** : `S`, helpers `esc()` `save()` `render()` `upd()` `num()` `fmt()` `r2()` `dateFR()` `uid()`. Renderers par onglet : `rMS` (Mission/Devis), `rPF` (Profil), `rTR` (Tarifs), `rSV` (Suivi), `rCL` (Clients), `rCP` (Compta), `rBG` (Notes), `rMAJ` (Mises à jour).
- **Modèle mental de `S`** : voir `SCHEMA.md` (auto-généré depuis `DEFAULT_S` par `gen-schema.py`). À lire en début de session avant de toucher au schéma.
- **Tout nouveau champ ajouté à `S`** doit être :
  1. Initialisé dans `DEFAULT_S`
  2. Inclus dans le merge de `loadFromCloud` (sinon non rechargé au login)
  3. Inclus dans l'objet `set` de `saveToCloud` (sinon non sauvegardé cloud)

  Exception : champs purement runtime posés sur des entries existantes (ex. `e.pmtTs` = timestamp de paiement, lu par `suiviDevisUndo` pour cibler le dernier paiement). Pas dans `DEFAULT_S`, pas de migration. À nettoyer (`delete e.pmtTs`) à la transition inverse pour rester propre.
- **Filtre sticky pendant l'édition** : quand l'utilisateur édite un item via un volet déplié (ex. `suiviExpandedDevis` dans rSV), l'item doit être exempté des filtres en cours pour qu'il ne disparaisse pas sous lui quand son statut change. Pattern : `g.devisId === sticky || <predicate>` dans chaque branche `.filter()`. Reset du sticky quand l'user change explicitement de filtre.
- **Dropdown ancré à un `<th>`** : dans une `<table>`, un menu `position:absolute` à l'intérieur d'un `<th>` se retrouve **sous** les cellules du `<tbody>` (stacking thead/tbody pénalisant en HTML). Solution : rendre le menu HORS de la table en `position:fixed`, avec coordonnées calculées via `getBoundingClientRect()` du `<th>` cible après render. Voir `positionThMenu()` + `suiviDateMenuHtml()` pour le template (call dans `requestAnimationFrame` après chaque action qui modifie le menu).
- **Tooltip dans une section accordéon `.edit-section`** : utiliser le pattern portal (`position:fixed` dans `<body>` via JS), pas un tooltip CSS-only en `position:absolute`. La section parente a `overflow:hidden` qui clippe les tooltips classiques. **Helper générique** : `showInfo(event, "key")` lit `INFO_HTML[key]` et affiche dans le portail partagé `_paiementTooltipEl`. Pour ajouter un tooltip d'aide : (1) ajouter une entrée dans `INFO_HTML`, (2) `<button class="lg-info-icon" onmouseenter="showInfo(event, 'maKey')" onmouseleave="hideInfo()">i</button>`. Helpers spécifiques préexistants (`showPaiementInfo`, `showRemiseInfo`) restent valides — ils calculent leur contenu dynamiquement.
- **Opacité sur cellule de tableau** : `opacity` sur un `<td>` rend la cellule **entière** translucide — si la ligne a un fond personnalisé (`tr.subtotal { background:var(--surface-2) }`, `tr.grandtotal`, etc.), la cellule devient un "trou" qui laisse passer le fond de la page. Pattern : envelopper le contenu dans un `<span>` enfant et appliquer l'opacité au span. Voir `.hist td.cp-zero > span` (cellule "—" du bilan Compta).
- **Renumérotation / rename d'un client** : si tu modifies `S.clients.entries[].num`, propage le mapping ancien→nouveau à **5 endroits** : (a) `S.mission.client.num` si la mission est liée, (b) `S.suivi.devis[].ref` (regex `^DEVIS-NUM-YYYY-MM-NNN$`), (c) `S.suivi.devis[].snapshotMission.client.num`, (d) `S.suivi.entries[].client` (legacy format `#NUM Nom`). Voir `clientsRenumberAll()` pour le pattern. Toute nouvelle référence client à introduire DOIT être ajoutée à cette propagation, sinon désync silencieux.
- **`missionNew(presetClient?)`** : démarre un nouveau devis. **Garde** la config (taux horaires, urssafPct, paiement.delai/marges, **echeances**, CGV, déplacement.mode/tauxKm). **Efface** les données spécifiques (heures, lignes, client, déplacement chiffres, autres, remise, contratHorsEtab, datePrestation, object*). Si tu ajoutes un champ à `S.mission`, décide de quelle catégorie il relève et ajoute-le à `missionNew()`.
- **Lookup client depuis devis** : `findClientForDevis(devisId)` essaie 3 stratégies en cascade — `snapshotMission.client.id`, puis `snapshotClient` cleané du préfixe `#NUM`, puis 1ère entry Suivi du devis. Robuste pour les devis legacy. Toujours utiliser ce helper, pas un lookup ad hoc.
- **Auth mobile** : `signInWithRedirect` sur mobile (détection UA), `signInWithPopup` sur desktop. Google bloque le popup OAuth sur la plupart des navigateurs mobiles (politique « secure browsers »). `isInAppWebView()` détecte les WebViews intégrées (Messenger, Instagram, FB, Twitter, etc.) et affiche un écran d'instructions « Ouvre dans Safari/Chrome » au lieu de tenter l'auth (qui échouerait avec `disallowed_useragent`).
- **Compose mail Gmail** : `buildGmailUrl(to, subject, body)` retourne URL Gmail compose qui s'ouvre **toujours en fullscreen** (limitation Google ~2018, pas contournable via URL). `mailto:` route vers le handler par défaut du navigateur — chez Edge/Windows c'est Outlook, donc à éviter pour ce cas. Pour bulk : `bcc=...` pour préserver la confidentialité (BCC = blind carbon copy). Templates relance dans `S.prefs.gmailTemplates` éditables dans Profil ; placeholders `{contact} {ref} {date} {client} {name}`.

## Schéma de données

### Top-level keys de `S`

`identite` (émetteur), `mission` (devis en cours), `suivi` (`{ entries[], devis{} }`), `clients`, `tarifs`, `compta`, `abonnements`, `investissements`, `bugs`, `devis`.

### `S.identite` (édité dans onglet Profil `rPF`)

```js
{
  prenom, nom, denomination, profession,
  adresse, cp, ville, email, telephone, siteWeb,
  formeJuridique: "micro-bnc"|"ei"|"eurl"|"sasu"|"sarl"|"artiste-auteur",
  mentionEI, siret, ape, rcs, capitalSocial,
  regimeTVA: "franchise"|"assujetti", numTvaIntra,
  rcPro: { assureur, numero, zone },
  mediateur: { nom, adresse, url },              // obligatoire B2C/mixte (L612-1 C. conso.)
  bank: { banque, titulaire, iban, bic },        // alimente devis/débours/facture
  clienteleType: "b2c"|"b2b"|"mixte"             // défaut, override par mission.client.type
}
```

### `S.mission` (devis en cours, brouillon)

Champs clés : `ref` (**`DEVIS-NUM-YYYY-MM-NNN`** si client a un n°, sinon `DEVIS-YYYY-MM-NNN` ; généré par `recomputeRef`. NUM = `S.mission.client.num`), `dateEmission`, `dureeValidite` (jours, défaut 30), `client: { type: "mixte"|"b2c"|"b2b" }`, `contratHorsEtab` (déclenche rétractation 14j), `lignes[]`, `echeances[]`, `paiement: { delai }`, `cgvSections[]`.

**`recomputeRef`** régénère la ref si elle est dans un format obsolète (ancien `DEVIS-YYYY-MM-NNN` sans num client) ou si le client courant a un num qui ne match pas le préfixe actuel. Protection : si la ref correspond à un devis archivé ET que son format reflète le client courant, on ne touche pas (évite d'écraser une ref figée). Appelé au boot (post-loadFromCloud) pour aligner les missions héritées.

### `S.mission.lignes[]` — 3 types

- **`type:"heures"`** — `{ id, intitule, duree, unit:"h"|"j", description }`. Multipliée par `totals().tarifHEff`.
- **`type:"materiel"`** — `{ id, intitule, prix, devis:"principal"|"debours", paiementType, justificatifJoint, description }`.
  - Principal → paiementType ∈ `"acompte" | "avance"`.
  - Débours → paiementType ∈ `"acompte"` (= « Refacturé ») | `"fact-direct"` (= « Direct »). **Jamais "avance" en débours.**
- **`type:"cession"`** — `{ id, intitule, prix, duree, territoire, supports, exclusivite, description }`. Conforme CPI L131-3. Forfait, contribue au total HT.

### `S.suivi.devis[id]` (snapshot d'archivage)

`{ ref, snapshotHtml, snapshotDeboursHtml, snapshotAt, snapshotTotal, snapshotDebours, snapshotClient, snapshotHash }`. Capturé par `suiviAdd` + maintenu par `suiviUpdateSnapshot`.

### `S.suivi.entries[]` (lignes d'échéance) — state machine

5 statuts possibles sur `e.statut` :

- `envoye` — devis pas encore accepté
- `attente` — paiement en attente (post-acceptation)
- `termine` — payée (« soldée »)
- `refuse` — refusé client **avant** acceptation
- `annule` — annulé **après** acceptation (mission tombée à l'eau)

Pas d'état intermédiaire `accepte` (fusionné dans `attente` lors de la refonte Suivi). Le statut devis-level est dérivé via `devisPrincipal()` qui ajoute `en_cours` quand le devis a un mix `attente` + `termine`.

**Champs invisibles à connaître sur `e`** :
- `e.pmtTs` — timestamp posé à la transition `attente → termine`. Utilisé par `suiviDevisUndo()` pour cibler le paiement le plus récent. Supprimé au revert.
- `e.statutAvantRefus` / `e.statutAvantAnnul` — snapshot du statut précédent pour permettre le revert depuis `refuse` / `annule`.

**Mapping legacy** (dans `STATUT_LEGACY`) : `paye → termine`, `accepte → attente`. Migré silencieusement par `suiviMigrate()` au prochain `loadFromCloud`.

### `S.prefs`

```js
{
  relanceJours: 7,                              // seuil "À relancer" Accueil
  gmailTemplates: {
    devis:    { subject, body },                // template relance "pas de réponse"
    paiement: { subject, body }                 // template relance "en attente paiement"
  }
}
```

Templates Gmail éditables dans Profil → « Modèles de relance Gmail ». Placeholders supportés (substitution simple) : `{contact}` (prénom), `{ref}` (réf devis), `{date}` (FR), `{client}` (nom complet), `{name}` (toi, depuis `S.identite`).

## Débours

Toggle par ligne (matériel) et sur le déplacement : `devis: "principal" | "debours"`. Pour les lignes en `debours`, deux modes :

- **Refacturé** (`paiementType:"acompte"`) — tu avances le frais, le client te rembourse au centime près. Apparaît sur la **feuille débours** dans le bloc principal « Total à rembourser ».
- **Direct** (`paiementType:"fact-direct"`) — le client règle directement le fournisseur. Hors devis fiscal (CGI 267-II). Listé pour info dans un bloc séparé « À régler directement au fournisseur » sur la feuille débours, pas dans le total.

⚠ **Frais de déplacement** engagés par le photographe = fiscalement des **frais accessoires** (CGI 267-I-2°, soumis à TVA), **pas des débours**, sauf cas rare où le client paie directement. Le toggle Débours reste possible mais à utiliser avec précaution.

Feuille débours : `rDeboursPreview()`. Bloc dans le devis principal : `.dp-debours-block`.

## Compta & au noir vs déclaré

L'app distingue deux flux d'argent par entry Suivi :

- `e.montant` = total réellement encaissé (toujours rempli)
- `e.ca` = part **déclarée** uniquement (0 si au noir)
- `e.ursaf` = 0 sur les entries au noir
- `e.salaire` / `e.tresorerie` = remplis quel que soit le statut fiscal (le photographe encaisse / met de côté la même chose)

Dans `bilanCompute()`, deux colonnes distinctes :
- **Payé** = somme de `e.montant` (déclaré + au noir)
- **CA** = somme de `e.ca` (déclaré seulement, sert aux seuils micro-BNC / TVA)

⚠ **Ne jamais utiliser `montant - frais` comme fallback pour `ca` quand `ca = 0`**. Une entry avec `ca=0` et `montant>0` = volontairement au noir, pas une donnée manquante. Promouvoir ça en CA déclaré = faute fiscale.

Chaque devis a `S.mission.declare` (true par défaut, false = au noir). `suiviAdd()` câble automatiquement la décomposition à l'archivage :
- URSSAF = `montant × urssafPct` (0 si au noir)
- Trésorerie = `montant × (tauxAvecSecurite / tarifH)` — fraction du tarif horaire qui finance matos+abos+sécurité
- Salaire net = `montant − URSSAF − Trésorerie`
- CA = `montant` si déclaré, `0` si au noir

**Plage de mois affichée** : `bilanCompute()` génère TOUS les mois entre la première activité (entry / début abo / achat matériel) et aujourd'hui — pas seulement les mois avec entries Suivi. Sinon les mois sans encaissement mais avec abos/amort actifs sont oubliés et le sous-total annuel des charges fixes est faux. Filtre final élide uniquement les mois "vraiment vides" (zéro partout).

## Archivage et impression

- **Un seul bouton d'archivage** : `rDevisPaneFooterInner` (sticky en bas de l'onglet Devis). Aucun bouton dans les previews. Le bouton enregistre **devis + débours** en une seule action.
- `suiviAdd()` (nouveau devis) → crée 2 entries Suivi (acompte + reste) + 2 snapshots HTML (`snapshotHtml` + `snapshotDeboursHtml`).
- `suiviUpdateSnapshot()` (devis existant modifié) → met à jour les 2 snapshots + recrée les entries si manquantes.
- **Impression UNIQUEMENT depuis Suivi**. Modal `rViewDevisModal` avec onglets *Devis | Débours* (Débours visible si `snapshotDeboursHtml` non vide). Le bouton imprimer adapte son label et le nom de fichier PDF (`computePrintFilename`).
- Pas de bouton « Imprimer » dans les previews live (`rDevisPreview` / `rDeboursPreview`).

## Méthode de travail attendue

- **Découpage en phases** pour toute tâche non triviale : audit / proposition / exécution. Arrêt explicite à la fin de chaque phase, attente de mon "OK" avant de passer à la suivante.
- **Audit en UI pour les grosses refontes** : pour les phases d'audit (Phase 1) sur des features complexes, injecter aussi le diagramme/audit **dans l'app** (bloc `<details>` collapsible). Permet à l'utilisateur de valider visuellement le diagnostic avant Phase 2. Le bloc se retire à la fin de la refonte (étape dédiée).
- **Audit + proposition obligatoires (même en auto mode)** pour toute opération qui : touche la navigation/menu · modifie le schéma de `S` · supprime > 50 lignes · utilise `sed` ou un Edit multi-zones. Pas d'exécution sans "OK" explicite.
- **Challenger bienvenu** : tu es autorisé — et encouragé — à proposer des améliorations, questions, ou alternatives auxquelles je n'aurais pas pensé. Sépare-les clairement de ce que j'ai demandé. Pour chacune, indique : à faire maintenant / plus tard / juste à noter.
- **Demander plutôt que deviner** sur les points métier (statut fiscal, conventions, intentions produit). Mieux vaut une question qu'une supposition.
- **Sanity check après gros édit** : lancer `./check.sh` après tout `sed` ou Edit multi-zones, **avant** `git commit`.
- **Navigation par ancres** dans `index.html` : pour localiser une fonction, `grep "^// ▼ <nom>"` plutôt que les numéros de ligne du TOC. Lister toutes les ancres : `grep -n "^// ▼ " index.html`. Quand tu ajoutes une fonction-clé (renderer `rXX`, helper exposé, modal), pose une ancre au format `// ▼ <nom> — <description courte>` au-dessus.
- **Grep avant Edit sur `index.html`** : avant tout `Edit`, vérifier l'unicité de `old_string` (`grep -c` ou `grep -n`). Sur un fichier de 9 000 lignes, beaucoup de patterns courts collisionnent (`esc(...)`, `${...}`, `S.mission.client.name`). Si non unique, élargir le contexte ou cibler via une ancre voisine.
- **Reads serrés via ancres** : ne pas `Read` 200 lignes par sécurité. Pour bosser sur une fonction, `grep -n "^// ▼ <nom>"` puis `Read offset=<L> limit=80`. Ne charger plus large QUE si la fonction appelle des helpers que je ne connais pas.

## Commandes utiles

À utiliser au lieu de redécouvrir l'incantation à chaque session.

```bash
./check.sh                                # sanity check (regen SCHEMA.md inclus)
py gen-schema.py                          # régénère SCHEMA.md depuis DEFAULT_S
grep -n "^// ▼ " index.html               # liste toutes les ancres (renderers, helpers, modals)
grep -nE "^function r[A-Z]" index.html    # liste tous les renderers (rXX)
grep -n "TABLE DES MATIÈRES" index.html   # localise le TOC
python3 -m http.server 8000               # serveur local pour itérer
```

## Fin de session

Mot-clé de fin de session : **« Kenavo ! »** (au revoir en breton). Quand l'utilisateur écrit ce mot, répondre **avant** toute autre chose par la question :

> Au vu de ce qu'on vient de faire, qu'est-ce qui mériterait d'être ajouté au CLAUDE.md pour qu'une prochaine session démarre mieux ? Propose des ajouts précis avec leur emplacement dans le fichier.

Objectif : capturer les conventions, pièges et contextes nouveaux apparus pendant la session avant que l'utilisateur ne `/clear`. La proposition doit être **précise** : nouveau point de bullet, nouvelle sous-section, ou modification d'une règle existante, avec **l'emplacement exact** (section + position dans le fichier).

Une fois la réponse donnée et les ajouts validés (ou refusés), l'utilisateur fera `/clear` lui-même.
