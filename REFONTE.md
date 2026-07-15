# Refonte design — Outil devis Saintilann

Document de passation pour porter la maquette **« Refonte V2 - Compact »** sur `index.html`.
La maquette est la **référence visuelle** ; ce fichier en donne les specs actionnables.

## Règles de mise en œuvre (à respecter absolument)

1. **On ne touche QU'À la présentation.** Toute la logique métier (`S`, `upd`, `save`, renderers, state machine des devis, bilan, corbeilles…) reste identique. On réécrit le HTML/CSS produit par chaque renderer, pas la logique.
2. **Onglet par onglet.** Un commit par onglet (`ux: refonte onglet X`). `./check.sh` avant chaque commit. Pas de big-bang.
3. **Pas de styles inline en dur** : la maquette est en inline pour prototyper, mais dans `index.html` on passe par les **variables CSS `:root`** (`--space-*`, `--radius-*`, `--btn-h-*`) et par de nouvelles classes utilitaires si un motif revient ≥ 3 fois. Traduire, ne pas copier les pixels.
4. **Données réelles.** La maquette contient des données factices (Maison Aznar, etc.). En prod, tout se branche sur `S`.
5. **Pas d'emoji, Lucide uniquement** (`ICONS` / `ICO_SZ`) — règle déjà en vigueur.
6. **Ordre recommandé** : Sidebar → Nouveau devis → Suivi devis → Catalogue → Bilan → Clients → Profil → Historique → Achats → Bugs → Mon Compte.

---

## 0. Système visuel global

### Palette (cible de la refonte)
La maquette abandonne le bleu marine actuel (`--surface:#122a4d`) pour un **near-black + accents**. Décision à acter : soit on met à jour les tokens `:root`, soit on garde le navy. Recommandé = adopter la palette maquette ci-dessous (c'est la V2 retenue).

| Rôle | Hex | Usage |
|---|---|---|
| Fond app | `#0C0B0F` | body (sous un scrim si photo de fond) |
| Surface carte | `rgba(26,24,34,.85)` | cartes, sections, panneaux |
| Surface creuse | `rgba(8,7,10,.4–.5)` | inputs, sous-cartes, lignes internes |
| Bordure fine | `rgba(255,255,255,.08)` | contours de cartes |
| Bordure marquée | `rgba(255,255,255,.12)` | séparateurs d'en-tête, inputs |
| Azure primaire | `#0A56E0` | boutons primaires, fills actifs |
| Azure hover | `#2E86F0` | hover boutons primaires |
| Azure clair | `#45C1FD` | eyebrows, icônes actives, accents |
| Jade / succès | `#02DCB9` | montants encaissés, net, statut soldé |
| Ambre / attente | `#F5943C` / `#F5B84C` | à relancer, à encaisser, warn |
| Ember | `#E8751C` | pastille logo, pastille brouillon |
| Rose / négatif | `#F08C4B` | refusé / annulé |

### Texte (opacités de gris)
`#FFFFFF` titres forts · `#F6F4FA` primaire · `#E8E5EF` corps · `#C6C2D2` secondaire · `#9A96A8` atténué · `#8A8698` labels mono · `#6E6A7C` faible · `#4A4757` très faible.

### Typographie
- **Big Shoulders Display** 700, UPPERCASE, `line-height:.92`, tracking ~0 : titres de page (h1 **26px**), gros chiffres (tarif catalogue **30px**, nom client fiche **22px**).
- **Space Mono** 700, UPPERCASE : eyebrows (**10px**, `letter-spacing:.18em`, préfixe `—`), labels de section (**11px**, `.16em`), labels de champ/colonne (**9–9.5px**, `.1–.12em`), réfs, badges (**8.5–9px**).
- **Corps** (Arial / system, la police body de l'app) : **11–13px**, sentence case, `line-height:1.5–1.6`.

### Espacement & rayons
Grille 4px. Padding cartes **16–20px**. Gaps entre cartes **12–16px**. Rayons : **4px** contrôles/inputs, **6px** cartes/sections, **999px** pills. → mapper sur `--space-*`, `--radius-sm/md/lg`.

### Composants réutilisables (motifs)
- **Carte** : `background rgba(26,24,34,.85)` · `border 1px rgba(255,255,255,.08)` · `border-radius 6px` · padding 16–20px.
- **En-tête de section** : label Space Mono 11px UPPERCASE `#8A8698`/`#C6C2D2`, + hint atténué optionnel aligné à droite.
- **Status pill** : Space Mono 8.5px UPPERCASE, `color = couleur du statut`, `border 1px <couleur>55`, radius 999px, padding 3px 9px, `white-space:nowrap`.
- **Segmented control** : conteneur `border 1px rgba(255,255,255,.14)` radius 4–5px padding 2px ; onglet actif = fill `#0A56E0` texte blanc, inactif = transparent texte `#9A96A8`.
- **Bouton primaire** : fill `#0A56E0`, Space Mono 11px UPPERCASE `.12em`, radius 4px, padding ~11px ; hover `#2E86F0` ; active `translateY(1px)`. (⚠ cohérent avec `.mk-btn.blue` existant — réutiliser/étendre `.mk-btn`.)
- **Bouton ghost** : transparent, `border 1px rgba(255,255,255,.2)`, Space Mono 9px UPPERCASE, texte `#C6C2D2`.
- **Input / select / textarea** : hauteur 32–34px (`--input-h`), `background rgba(8,7,10,.5)`, `border 1px rgba(255,255,255,.12)`, radius 4px, texte `#F6F4FA`. Champ avec unité : unité en `<span>` gris à droite dans la même boîte (déjà le pattern `.lock-field.with-unit`).

### En-tête de page (toutes les pages)
Rangée avec bordure basse `1px rgba(255,255,255,.12)`, `margin-bottom:24px` :
- eyebrow Space Mono 10px `#45C1FD` préfixé `—` ;
- h1 Big Shoulders 26px UPPERCASE blanc ;
- à droite (optionnel) : ref/date mono atténuée, chip année, sélecteur de piste, ou bouton primaire.

---

## 1. Sidebar (structurel — à faire en premier)

**`NAV` en 2 groupes dépliables** (accordéon au clic, plusieurs ouverts possibles, état de pli transient hors `S`) :
- **Mission** (icône `camera`) : Suivi devis · Nouveau devis · Catalogue · Clients · Mon Profil
- **Comptabilité** (icône `barChart`) : Bilan comptable · Historique · Achats

Détails :
- En-tête de groupe : icône + label Space Mono 10px UPPERCASE `.16em` `#8A8698` + chevron à droite (rotation `0deg` ouvert / `-90deg` replié). Icône du groupe passe `#45C1FD` si l'onglet actif lui appartient.
- Enfants : indentés, `border-left 1px rgba(255,255,255,.08)`, chaque item = icône 16px + label 13px. **Icônes uniques** (jamais partagées groupe/enfant). Suggestion : Suivi devis `dashboard`, Nouveau devis `filePlus`, Catalogue `tag`, Clients `users`, Mon Profil `user`, Bilan `pieChart`, Historique `history`, Achats `cart`.
- Item actif : `background rgba(46,134,240,.10)`, `border-left 2px #2E86F0`, texte blanc, icône `#45C1FD`.
- **Pastille brouillon** (Nouveau devis) : quand le groupe est **replié**, la remonter sur l'en-tête du groupe (petit point ember). Quand il est **ouvert**, badge « Brouillon » sur l'item.
- `setTab` déplie le groupe de l'onglet ciblé sans refermer les autres.
- **Pied de sidebar** (2 boutons secondaires, hors groupes, sous un `border-top`) : **Bugs & suggestions** (icône `bug`) puis **Mon compte** (avatar « RS » + nom + rôle). Même style d'item actif.

---

## 2. Nouveau devis — 2 modes (`rMS`)

Le toggle « Déclaré / Au black » est **supprimé**. Règle : `mode:"devis"` ⇒ déclaré · `mode:"quick"` ⇒ au noir (déjà en place côté logique via `isMissionQuick` / `missionIsDeclared`).

**Sélecteur de mode** = 2 cartes descriptives (pas un toggle), sous l'en-tête, `gap:12px` :
- **Devis** (icône `file`) — « Document complet · déclaré · échéancier & CGV »
- **Prestation rapide** (icône `zap`) — « Aucun document · au noir · encaissement direct »
- Carte active : `background rgba(10,86,224,.14)`, `border 1px rgba(69,193,253,.5)`, coche `#45C1FD` à droite, titre Big Shoulders 17px. Inactive : surface carte + bordure fine.

**Layout** : grille `1fr 300px` (formulaire à gauche, récap sticky à droite).

**Bannière** (haut du formulaire) :
- Devis : warn ambre si IBAN manquant.
- Rapide : encart `border-left 2px #F5943C`, texte : « Prestation rapide — au noir. Aucun document émis, pas d'acompte ni de CGV, échéance unique à 100 %. »

**Formulaire mode Devis** (sections numérotées) : 01 Identification & client (réf, émission, validité, prestation, carte client, type clientèle, contrat hors établissement) · 02 Prestations (catalogue+objet, heures, matériel & cession) · 03 Déplacements (voiture/transports, trajet, facturation Principal/Débours + Acompte/Avance) · 04 Majorations & paiements (remise, URSSAF, marge, échéances + total %) · 05 Conditions & CGV.

**Formulaire mode Rapide** (allégé) : 01 Identification & client (**réf `PRE-`**, émission, carte client — SANS validité/prestation/type) · 02 Prestation (catalogue+objet, heures, matériel — SANS cession ni statut fiscal) · 03 Déplacement & remise (trajet + remise — SANS Principal/Débours ni Acompte/Avance).

**Récap sticky (droite)** : lignes composantes (heures, déplacement, matériel, remise) puis :
- Devis : Total HT (blanc gras) → URSSAF −22 % (atténué) → **Net photographe** (jade) ; carte « Échéancier » (lignes % · montant) ; état « Prêt à émettre » (jade) / « Échéances ≠ 100 % » (ambre).
- Rapide : **Total encaissé** (blanc) → **Net photographe (au noir)** (jade, = total) ; carte « Encaissement » ligne unique « À réception · 100 % » ; état « Au noir · non déclaré » (ambre) ; **pas de bouton aperçu** (aucun document).

---

## 3. Suivi devis / Accueil (`rAC`)

En-tête « Suivi devis » + KPI (CA mois, Encaissé, Salaire net) en rangée à droite + bouton primaire « + Nouveau devis ».
Sections empilées (À relancer / En attente de paiement / Devis envoyés / Annulés-refusés), chacune : titre mono coloré + compteur + hint.
Chaque devis = **ligne cliquable** (grille : pastille couleur · date · client+réf/rev · **badge de progression** · montant · chevron). Statuts : Attente réponse (azure), Acompte/Solde à encaisser (ambre), Facture à émettre (azure), À livrer (azure), Soldé (jade), Refusé (rose).
Au clic → **dépliage timeline** (déjà refondu dans le repo : frise 7 étapes, bande d'action unique, échéancier). Conserver ce parcours ; seule la peau change (surfaces, badges, boutons `.mk-btn`).

---

## 4. Catalogue (`rCatalogue`)

En-tête « Catalogue » + sélecteur de piste **Grille / Cartes** à droite.
- **Grille** : panneau « Prestations » = lignes (nom + desc à gauche, champ tarif `€/h` éditable, `⋮`).
- **Cartes** : cartes prestation (gros tarif Big Shoulders 30px + `€/h` azure, nom, desc, `⋮`), grille `auto-fill minmax(178px,1fr)`.
Puis, dans les 2 pistes, 2 panneaux côte à côte :
- **Cession de droits** : lignes `label · durée · +x%` (valeur azure). Majoration sur le HT.
- **Matériel refacturé** : lignes `label · €/j`.

---

## 5. Bilan comptable (`rCP`)

En-tête « Bilan comptable » + chip année `2026` + sélecteur **Tableau / Graphe**.
**Bandeau KPI** (5 tuiles) : CA déclaré · Encaissé · URSSAF dû (ambre) · Salaire net (jade) · Trésorerie (azure).
**Tableau mensuel** (année en cours) : colonnes **Mois · Encaissé · CA déclaré · Heures · URSSAF dû · Salaire net · Dépenses · Trésorerie (cumul)** + ligne **Total**. Tag « ·noir » (ambre) sur CA si encaissé > CA. `table-layout:fixed;width:100%` pour tenir sans scroll.
**Piste Graphe** : barres empilées encaissé/mois (part déclarée azure + part au noir ambre) + légende, au-dessus du tableau.
Rappel métier sous le tableau : compta de caisse (art. 93 CGI) · Dépenses = achats/abos/amortissements · Salaire net = CA déclaré − URSSAF.
⚠ Brancher sur `bilanCompute()` existant ; ne rien recalculer soi-même.

---

## 6. Clients (`rCL`) — master-detail

En-tête « Clients » + bouton primaire « + Nouveau client ».
Grille `288px 1fr` :
- **Gauche** : champ recherche + liste (avatar initiales couleur, nom, CA). Item sélectionné surligné azure.
- **Droite** : en-tête fiche (avatar 48px, nom Big Shoulders 22px, badge type entreprise/particulier/mixte, adresse avec icône `pin`, **CA généré** en jade à droite) ; panneau **Contacts** (cartes multi-contacts : nom + rôle empilés, email `mail`, tél `phone`) ; panneau **Historique des devis** (date · réf/rev · statut · montant).

---

## 7. Mon Profil (`rPF`) — grille de sections

En-tête « Mon Profil » + indicateur « Enregistré » (jade) à droite. Grille 2 colonnes de cartes :
Identité (prénom/nom, profession, site, adresse, email, tél) · Entreprise (SIRET, APE, forme juridique, régime TVA, case mention « EI ») · Coordonnées bancaires (titulaire, IBAN, BIC) · URSSAF (taux % + note 23,1 % avec CFP) · Logo (placeholder carré + « Importer ») · **CGV & mentions par défaut** (pleine largeur, préambule/sections/signature+médiateur avec boutons Modifier/Gérer) · **Modèles d'e-mails · relances Gmail** (pleine largeur, 2 cartes Relance devis / Relance paiement avec extrait).

---

## 8. Historique (`rSV`) — archive filtrable

En-tête « Historique ».
**Chips de filtre** : Tous · En cours · Soldés · Refusés/annulés · Corbeille (chaque chip avec compteur ; actif = fill azure clair). Corbeille vide → message rétention 30 j.
**Tableau** (grille `74px 1fr 132px 92px auto 24px`) : Date · Client · Référence (réf · rev) · Montant (droite) · Statut (pill) · `⋮`. `white-space:nowrap` + ellipsis sur client/réf pour ne pas déborder.
Réutilise les données `S.suivi` (chaînes de révisions, `isActive`) et les corbeilles existantes.

---

## 9. Achats / Abos (`rAchats`)

En-tête « Achats / Abos » + bouton primaire « + Ajouter ».
**Bandeau KPI** (3) : Abonnements /an (+ /mois) · Amortissements /an (+ nb équipements) · **Dépenses /an** (ambre, « déduites du résultat »).
Grille 2 panneaux :
- **Abonnements récurrents** : nom + catégorie/prochain prélèvement · montant `/mois`.
- **Achats & investissements** : nom + date/durée d'amortissement · montant · **dotation `/an`** (jade).
Alimente la colonne Dépenses du bilan.

---

## 10. Bugs & suggestions (`rBG`) — accès pied de sidebar

En-tête « Bugs & suggestions ». Grille `360px 1fr` :
- **Gauche — Nouveau retour** : segmented Bug / Suggestion, select « Onglet concerné » (`BUG_TAB_OPTIONS`), textarea description, zone de dépôt capture (`note-N.png`), bouton primaire « Envoyer le retour ».
- **Droite — Retours** : liste (type Bug ember / Suggestion azure · onglet · **statut** Ouvert azure / En cours ambre / Résolu jade · date, puis texte). Compteur « N en cours · M au total ».
Brancher sur `S.bugs.items`. ⚠ Jamais de capture en data-URL dans Firestore (voir CLAUDE.md).

---

## 11. Mon Compte — accès pied de sidebar

En-tête « Mon Compte ». Grille 2 colonnes :
- **Carte profil** (pleine largeur) : avatar « RS », nom Big Shoulders, badge « Propriétaire » (jade), email, indicateur « Synchronisé » (jade) à droite.
- **Workspace · membres** : liste (avatar, nom, rôle, statut : Vous / Membre validé / Invitation en attente) + « + Inviter un membre ». (`workspaces/<ownerUid>.members`.)
- **Corbeille** : résumé + « Ouvrir » (`binModalToggle`).
- **Mises à jour** (pleine largeur) : entrées `APP_CHANGELOG` (pastille ember « nouveau », date, items).
- **Préférences** : relance après N jours, sélecteur de compte Google à l'envoi.
- **Déconnexion** (pleine largeur, encart ember, bouton contour ember).

---

## Points d'attention transverses

- **Traduire** les couleurs/espacements maquette vers les variables `:root` ; si adoption de la palette near-black, mettre à jour les tokens une seule fois puis dérouler.
- **Boutons** : convertir vers `.mk-btn` (+ variantes) au fil des zones ; ne plus créer de bouton néon.
- **`esc()`** sur toute valeur dynamique injectée.
- **Icônes** : ajouter au besoin dans **les deux** dictionnaires `ICONS` et `ICO_SZ`.
- **Inputs number** : jamais de spinner (règle globale déjà posée).
- Tester chaque onglet + `./check.sh` + entrée `APP_CHANGELOG` si visible utilisateur + commit.
