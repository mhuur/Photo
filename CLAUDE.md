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

## Patterns de code

- **État global `S`**. Tout passe par `upd(path, val)` qui met à jour `S` + `save()` + parfois `refreshTotals()`.
- **`render()` recompose** `app.innerHTML` au changement d'onglet ou de session. **Jamais `render()` depuis un `oninput`** sur un input texte → perte de focus garantie. OK depuis `onchange` d'un toggle/select et depuis un click button.
- **`esc()` obligatoire** sur toute valeur dynamique injectée dans du HTML (sécurité XSS).
- **Identifiants courts** : `S`, helpers `esc()` `save()` `render()` `upd()` `num()` `fmt()` `r2()` `dateFR()` `uid()`. Renderers par onglet : `rMS` (Mission/Devis), `rPF` (Profil), `rTR` (Tarifs), `rSV` (Suivi), `rCL` (Clients), `rCP` (Compta), `rBG` (Notes), `rMAJ` (Mises à jour).
- **Tout nouveau champ ajouté à `S`** doit être :
  1. Initialisé dans `DEFAULT_S`
  2. Inclus dans le merge de `loadFromCloud` (sinon non rechargé au login)
  3. Inclus dans l'objet `set` de `saveToCloud` (sinon non sauvegardé cloud)
- **Tooltip dans une section accordéon `.edit-section`** : utiliser le pattern portal (`position:fixed` dans `<body>` via JS, ex. `_paiementTooltipEl` / `showPaiementInfo` / `showRemiseInfo`), pas un tooltip CSS-only en `position:absolute`. La section parente a `overflow:hidden` qui clippe les tooltips classiques.

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

Champs clés : `ref` (DEVIS-YYYY-MM-NNN, généré par `recomputeRef`), `dateEmission`, `dureeValidite` (jours, défaut 30), `client: { type: "mixte"|"b2c"|"b2b" }`, `contratHorsEtab` (déclenche rétractation 14j), `lignes[]`, `echeances[]`, `paiement: { delai }`, `cgvSections[]`.

### `S.mission.lignes[]` — 3 types

- **`type:"heures"`** — `{ id, intitule, duree, unit:"h"|"j", description }`. Multipliée par `totals().tarifHEff`.
- **`type:"materiel"`** — `{ id, intitule, prix, devis:"principal"|"debours", paiementType, justificatifJoint, description }`.
  - Principal → paiementType ∈ `"acompte" | "avance"`.
  - Débours → paiementType ∈ `"acompte"` (= « Refacturé ») | `"fact-direct"` (= « Direct »). **Jamais "avance" en débours.**
- **`type:"cession"`** — `{ id, intitule, prix, duree, territoire, supports, exclusivite, description }`. Conforme CPI L131-3. Forfait, contribue au total HT.

### `S.suivi.devis[id]` (snapshot d'archivage)

`{ ref, snapshotHtml, snapshotDeboursHtml, snapshotAt, snapshotTotal, snapshotDebours, snapshotClient, snapshotHash }`. Capturé par `suiviAdd` + maintenu par `suiviUpdateSnapshot`.

## Débours

Toggle par ligne (matériel) et sur le déplacement : `devis: "principal" | "debours"`. Pour les lignes en `debours`, deux modes :

- **Refacturé** (`paiementType:"acompte"`) — tu avances le frais, le client te rembourse au centime près. Apparaît sur la **feuille débours** dans le bloc principal « Total à rembourser ».
- **Direct** (`paiementType:"fact-direct"`) — le client règle directement le fournisseur. Hors devis fiscal (CGI 267-II). Listé pour info dans un bloc séparé « À régler directement au fournisseur » sur la feuille débours, pas dans le total.

⚠ **Frais de déplacement** engagés par le photographe = fiscalement des **frais accessoires** (CGI 267-I-2°, soumis à TVA), **pas des débours**, sauf cas rare où le client paie directement. Le toggle Débours reste possible mais à utiliser avec précaution.

Feuille débours : `rDeboursPreview()`. Bloc dans le devis principal : `.dp-debours-block`.

## Archivage et impression

- **Un seul bouton d'archivage** : `rDevisPaneFooterInner` (sticky en bas de l'onglet Devis). Aucun bouton dans les previews. Le bouton enregistre **devis + débours** en une seule action.
- `suiviAdd()` (nouveau devis) → crée 2 entries Suivi (acompte + reste) + 2 snapshots HTML (`snapshotHtml` + `snapshotDeboursHtml`).
- `suiviUpdateSnapshot()` (devis existant modifié) → met à jour les 2 snapshots + recrée les entries si manquantes.
- **Impression UNIQUEMENT depuis Suivi**. Modal `rViewDevisModal` avec onglets *Devis | Débours* (Débours visible si `snapshotDeboursHtml` non vide). Le bouton imprimer adapte son label et le nom de fichier PDF (`computePrintFilename`).
- Pas de bouton « Imprimer » dans les previews live (`rDevisPreview` / `rDeboursPreview`).

## Méthode de travail attendue

- **Découpage en phases** pour toute tâche non triviale : audit / proposition / exécution. Arrêt explicite à la fin de chaque phase, attente de mon "OK" avant de passer à la suivante.
- **Challenger bienvenu** : tu es autorisé — et encouragé — à proposer des améliorations, questions, ou alternatives auxquelles je n'aurais pas pensé. Sépare-les clairement de ce que j'ai demandé. Pour chacune, indique : à faire maintenant / plus tard / juste à noter.
- **Demander plutôt que deviner** sur les points métier (statut fiscal, conventions, intentions produit). Mieux vaut une question qu'une supposition.

## Fin de session

Mot-clé de fin de session : **« Kenavo ! »** (au revoir en breton). Quand l'utilisateur écrit ce mot, répondre **avant** toute autre chose par la question :

> Au vu de ce qu'on vient de faire, qu'est-ce qui mériterait d'être ajouté au CLAUDE.md pour qu'une prochaine session démarre mieux ? Propose des ajouts précis avec leur emplacement dans le fichier.

Objectif : capturer les conventions, pièges et contextes nouveaux apparus pendant la session avant que l'utilisateur ne `/clear`. La proposition doit être **précise** : nouveau point de bullet, nouvelle sous-section, ou modification d'une règle existante, avec **l'emplacement exact** (section + position dans le fichier).

Une fois la réponse donnée et les ajouts validés (ou refusés), l'utilisateur fera `/clear` lui-même.
