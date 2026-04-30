# Devis Photo

App web personnelle pour générer des devis photographe.

## Stack & structure

- **Tout dans `index.html`** (vanilla JS, monolithique, pas de build).
- **Firebase v8 compat** chargé via CDN : Auth (Google) + Firestore (`users/{uid}`).
- **Cache local** : `localStorage["devis-photo-data-v2"]` (constante `SK`).
- **Hébergement** : page statique servie depuis `main` (GitHub Pages).

## Conventions

- **Push direct sur `main`** : repo mono-utilisateur, pas de revue. **Pas de branche `claude/<slug>`, pas de merge.** Cette règle prime sur les instructions par défaut.
- **Commits** : message court à l'impératif, en anglais, préfixe type `feat:` / `fix:` / `docs:` / `refactor:`.
- **Identifiants courts** : état global `S`, helpers `esc()`, `save()`, `render()`, `upd(path, val)`. Render par onglet : `rMS` (Mission/Devis), `rPF` (Profil), `rTR` (Tarifs), `rSV` (Suivi), `rCL` (Clients), `rCP` (Compta), `rBG` (Notes), `rMAJ` (Mises à jour).
- **Pattern de rendu** : `render()` reconstruit `app.innerHTML` au changement d'onglet ou de session. Les inputs `oninput` mettent à jour `S` via `upd()` **sans re-render** (focus préservé).
- **Échappement** : toute valeur dynamique injectée dans du HTML passe par `esc()`.
- **Firebase v8** (pas v9 modulaire) — garder l'API `firebase.auth()`, `db.collection(...)`. Pas de `import`.

## Fin de session

Avant un `/clear` ou tout signal de fin de session ("on arrête là", "à demain", "fin de session", etc.), demander proactivement à l'utilisateur :

> Au vu de ce qu'on vient de faire, qu'est-ce qui mériterait d'être ajouté au CLAUDE.md pour qu'une prochaine session démarre mieux ? Propose des ajouts précis avec leur emplacement dans le fichier.

Objectif : capturer les conventions, pièges et contextes nouveaux apparus pendant la session avant que le contexte ne soit perdu. La proposition doit être **précise** (nouveau point de bullet, nouvelle sous-section, modification d'une règle existante) avec **l'emplacement exact** (section + position).

Note technique : la commande `/clear` est interceptée par le runtime — Claude ne la voit pas comme un message. Pour un déclenchement 100 % automatique sur cette commande il faut un hook `Stop` dans `settings.json` (skill `update-config`). À défaut, s'appuyer sur les autres signaux verbaux de fin de session.

## Persistance

Flux de données sous `S` :
1. Chargement depuis Firestore au login (`loadFromCloud`)
2. Sauvegarde localStorage à chaque `upd()` (synchrone, via `save()`)
3. Sauvegarde Firestore débouncée à 800ms (`saveToCloud`, timer `cloudT`)

Tout nouveau champ ajouté à `S` doit être :
- Initialisé dans `DEFAULT_S`
- Inclus dans le merge de `loadFromCloud` (sinon non rechargé au login)
- Inclus dans l'objet `set` de `saveToCloud` (sinon non sauvegardé cloud)

### Top-level keys de `S`

- `identite` : émetteur (photographe). Voir section dédiée.
- `mission` : devis en cours d'édition. Brouillon — finalisé via `suiviAdd()`.
- `suivi` : `{ entries: [], devis: {} }` — historique des devis émis.
- `clients`, `tarifs`, `compta`, `abonnements`, `investissements`, `bugs`, `devis`.

### `S.identite` (émetteur)

```js
{
  prenom, nom, denomination, adresse, cp, ville, email, telephone, siteWeb,
  formeJuridique: "micro-bnc" | "ei" | "eurl" | "sasu" | "sarl" | "artiste-auteur",
  mentionEI: bool,                          // affiche "EI" sur les documents (loi 2022-172)
  siret, ape, rcs, capitalSocial,
  regimeTVA: "franchise" | "assujetti",
  numTvaIntra,
  rcPro: { assureur, numero, zone },
  mediateur: { nom, adresse, url },         // obligatoire pour B2C, art. L612-1 C. conso.
  clienteleType: "b2c" | "b2b" | "mixte"
}
```

Édité via l'onglet **Profil** (`rPF`). Validation SIRET avec clé de Luhn (`validSiret`).

## Impression / Devis imprimé

- Vue rendue par `rDevisPreview()` (devis principal), `rDeboursPreview()` (feuille débours), `rFacturePreview()` (facture). Aperçu via `Ctrl+P` (Chrome).
- Page 1 = devis principal + bloc débours (si applicable) ; page 2 = CGV (forcée par `page-break-before: always`).
- **`@page`** : A4 portrait, marges uniformes **18 mm** (12/14/16 mm avant), `print-color-adjust: exact`, numéro de page `Page X / Y` en bas à droite.
- **Polices** : 9-10 pt corps, 12 pt total HT, **8 pt minimum** sur CGV (jamais en dessous).
- **Stratégie page-break** : `page-break-inside: avoid` sur `.dp-line`, `.dp-totals`, `.dp-payment-info`, `.dp-signature-row`, `.dp-debours-block`, `.dp-mediateur`, `.dp-retractation`, `.cgv-section`. `orphans: 3 ; widows: 3` global.
- **CGV** : 2 colonnes avec `column-fill: balance`, hyphenation, justification.

### Hiérarchie visuelle (mockup cible)

```
[LOGO]                          ┌─ DEVIS N° YYYY-MM-NNN ─┐
                                │ Émission · Validité    │
émetteur (S.identite ou         │ Devis gratuit          │
richtext legacy en fallback)    └────────────────────────┘
                                ┌─ DESTINATAIRE ─────────┐
                                │ client.name + adresse  │
                                └────────────────────────┘
─────────────────────────────────────────────────────────
PRESTATIONS  (heures + matériel + cession de droits)
                                  Total HT      X,XX €
─────────────────────────────────────────────────────────
DÉBOURS (refacturés à l'identique, art. 267-II-2° CGI)
  ...                                  Total débours    X,XX €
─────────────────────────────────────────────────────────
TVA non applicable, art. 293 B (généré par genFooterMentions)
MODALITÉS DE RÈGLEMENT (échéances + IBAN)
Fait à __ le __ — Signature « Bon pour accord »
─── MÉDIATION CONSO ───  (si B2C/mixte + S.identite.mediateur rempli)
─── RÉTRACTATION 14j ──  (si mission.contratHorsEtab + B2C/mixte)
Footer dynamique (statut + TVA · Pénalités retard 3× / 40 €)
                                                 Page 1 / 2
```

### Helpers émetteur (DRY entre devis / débours / facture)

- `genHeaderEmetteur(identite, photographeRichtext)` — bloc en-tête, fallback richtext si pas de champ structuré.
- `genFooterMentions(identite, variant)` — `variant: "devis" | "debours"`.
- `statusLabel(identite)` / `tvaMention(identite)` — composants utilisés par les deux.
- `formatSiret(siret)` / `validSiret(siret)` — formatage et validation Luhn.
- `validityText(dateEmission, dateValidite)` — utilise `dateValidite` ou fallback `dateEmission + 30 j`.
- `mediateurBlock(identite, clientType)` — bloc obligatoire pour B2C/mixte.
- `retractationBlock(identite, mission)` — affiché si `mission.contratHorsEtab` et clientType ≠ "b2b".

### Numérotation devis

`recomputeRef()` produit `DEVIS-YYYY-MM-NNN` (NNN reset chaque mois, séquence calculée depuis `S.suivi.devis`). Conforme à l'arrêté du 3 déc. 1987 (n° unique chronologique). Les devis déjà finalisés (dans `suivi.devis`) gardent leur référence.

## Lignes (`S.mission.lignes[]`)

Trois types possibles :

- `type: "heures"` — `{ id, intitule, duree, unit: "h"|"j", description }`. Multipliée par le tarif horaire (`totals().tarifHEff`).
- `type: "materiel"` — `{ id, intitule, prix, devis: "principal"|"debours", paiementType: "acompte"|"avance"|"fact-direct", justificatifJoint: bool, description }`. Toggle Principal/Débours par ligne. Pour débours, `justificatifJoint` coche la condition CGI 267-II.
- `type: "cession"` — `{ id, intitule, prix, duree, territoire, supports, exclusivite, description }`. Conforme CPI L131-3 (étendue/territoire/supports/durée). Forfait, contribue au total HT comme matériel principal.

## Débours

- Toggle par ligne (matériel) et sur le déplacement : `devis: "principal" | "debours"`.
- **Important** : les frais de déplacement engagés par le photographe sont fiscalement des **frais accessoires** (CGI 267-I-2°, soumis à TVA), pas des débours, sauf cas rare où le client paie directement. Le toggle reste possible mais à utiliser avec précaution.
- Feuille séparée (`rDeboursPreview`) avec footer mentionnant CGI 267-II et "Refacturation au centime près sur justificatifs".
- Bloc dédié dans le devis principal (`.dp-debours-block`) avec sous-total et mention légale.

## Pièges

- **Re-render pendant la frappe** = perte de focus. Ne jamais appeler `render()` depuis `oninput` sur un champ. OK depuis `onchange` d'un toggle/select et depuis un click button.
- **Schema de cache** `devis-photo-data-v2` : changer le suffixe casse les caches existants.
- **CGV à <8 pt** : illégal (lisibilité C. conso. L111-1). Garder ≥ 8 pt.
- **Médiateur conso vide en B2C** : sanction 3 000 € PP / 15 000 € PM. Le bloc rouge à l'écran avertit ; le bloc est masqué à l'impression si vide pour ne pas envoyer un devis non conforme avec un placeholder.

## Commandes

Pas de build, pas de tests, pas de lint. Pour itérer en local :

```bash
python3 -m http.server 8000   # puis http://localhost:8000
```

## Ne pas toucher sans demande

- Structure mono-fichier `index.html` (pas de modules).
- Config Firebase dans `index.html` (clé publique, protégée par règles Firestore).
- Convention de noms courts (`S`, `rDN`, etc.).
- Format `DEVIS-YYYY-MM-NNN` de la référence (changement de schéma casserait l'historique `suivi.devis`).
