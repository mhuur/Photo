# REFONTE-SUIVI — divergences V2 restantes & plan d'action

> **Fichier de travail temporaire** (à supprimer à la fin du chantier). Contient l'audit
> des divergences entre l'app livrée et la maquette/`Refonte.md`, le plan de correction
> et l'état d'avancement. Si la session redémarre : lire ce fichier, reprendre à la
> première ligne non cochée de « Plan de travail ».
>
> Audit réalisé le 2026-07-14 sur commit `ade1855` (7 agents en parallèle, 1 interrompu).
> ⚠ Les numéros de ligne `index.html:NNNN` datent de ce commit — ils dérivent à chaque édition.
> Les écarts assumés de `refonte-v2/README.md` sont déjà exclus.

## État d'avancement

| # | Sujet | Audit | Corrigé | Validé user |
|---|-------|-------|---------|-------------|
| 0 | Bugs fonctionnels (indépendants du style) | ✅ | ✅ 2026-07-14 | ☐ |
| 1 | Arbitrages transverses (questions ci-dessous) | ✅ | ☐ décisions | ☐ |
| 2 | Socle transverse (néon, couleurs hors palette, .btn→.mk-btn, typo labels) | ✅ | ✅ TERMINÉ 2026-07-14/15 (Q5 halos, Q4 labels, Q11 ⋮, pills, rayons, purge Q14, toggles Q2 — reste : typo inter-onglets §14 à lisser par onglet) | ☐ |
| 3 | Mission (`rMS`) | ✅ | ✅ 2026-07-15 | ☐ |
| 4 | Accueil / Suivi devis (`rAC`) | ✅ | ✅ 2026-07-15 | ☐ |
| 5 | Catalogue (`rCatalogue`) | ✅ | ☐ | ☐ |
| 6 | Bilan comptable (`rCP`) | ✅ | ☐ | ☐ |
| 7 | Clients (`rCL`) | ✅ | ☐ | ☐ |
| 8 | Profil (`rPF`) | ✅ | ☐ | ☐ |
| 9 | Historique (`rSV`) | ✅ | ☐ | ☐ |
| 10 | Achats (`rAchats`) | ✅ | ☐ | ☐ |
| 11 | Bugs & suggestions (`rBG`) | ✅ | ☐ | ☐ |
| 12 | Mon Compte (`rCompte`) | ✅ | ☐ | ☐ |
| 13 | Sidebar + en-têtes + audit CSS global | ✅ (2ᵉ passe) | ✅ 2026-07-14 (reste : cosmétiques « à trancher » + Q13 libellés NAV) | ☐ |

**Méthode par session** : 1 onglet = re-vérifier les lignes citées (elles dérivent) → corriger →
`./check.sh` → vérif visuelle → APP_CHANGELOG si visible → commit `ux: refonte-suivi <onglet>` →
cocher ici → push.

---

## QUESTIONS OUVERTES — ✅ TOUTES ARBITRÉES (2026-07-14)

**Décisions :**
1. Mission : ~~accordéon conservé~~ **RENVERSÉ 2026-07-15** → sections empilées toujours ouvertes (maquette). Accordéon + machinerie supprimés.
2. Toggles : **fill azure sur les toggles de 1ᵉʳ niveau**, secondaires restent en creux.
3. Rayons : **aligner sur la maquette** (tokens : contrôles 4px, cartes 6px).
4. Labels de champ : **densifier** (11px, labels de zone en mono).
5. Halos focus/hover des champs : **supprimer partout** (bordure + fond teinté).
6. Lignes de devis : **conteneur unique** à séparateurs (maquette).
7. Onglet Bugs : **refonte complète** (grille 2 col + champs `type` et statut ternaire dans
   `S.bugs.items[]`, migration `validated` → Résolu, quick-add préservé).
8. Profil : **ajouter les cartes CGV & mentions + URSSAF**.
9. Badge type client : **abandonné** (écart assumé → README).
10. KPI Bilan : **composition actuelle conservée + couleurs** (Salaire jade, Trésorerie/Marge azure).
11. `⋮` : **Lucide `moreVertical` partout** + corriger la convention dans CLAUDE.md.
12. Encaissé fiche client : **net des remboursements**.
13. Libellés NAV : **libellés actuels conservés** (« Missions / Devis en cours / Achats & Abonnements »)
    → CLAUDE.md à mettre à jour.
14. Purge ancienne table Suivi (~150 l.) : **tout supprimer** (filtre année recréable en chips si besoin).

*(questions d'origine ci-dessous pour mémoire)*

1. **Mission — accordéon vs sections ouvertes** : la maquette montre 5 cartes toutes ouvertes ;
   l'app a un accordéon (1 volet ouvert), validé en phase 3. Garder l'accordéon (= consigner
   l'écart) ou passer aux sections empilées ? → **Réponse :**
2. **Segmented controls** : les 12 toggles de Mission portent `.seg-neon.violet` (sélection « en
   creux » azure) alors que la spec veut un fill `#0A56E0` texte blanc pour les toggles de 1ᵉʳ
   niveau (CLAUDE.md dit d'ailleurs que Mixte/…, Voiture/…, Acompte/… se lisent « à leur fond
   plein » — dérive doc/code). Quels toggles passent au fill ? → **Réponse :**
3. **Rayons** : l'app est un cran au-dessus de la maquette partout (sections 8px vs 6, inputs
   6px vs 4, `.mk-btn` 9px vs 4). Aligner globalement sur la maquette (gros chantier visuel,
   1 changement de tokens) ou garder l'échelle actuelle ? → **Réponse :**
4. **Labels de champ** : 13px Inter actuellement, maquette 11px (et labels de zone en mono).
   Densifier globalement ? → **Réponse :**
5. **Halo néon au focus/hover des inputs** (`0 0 12px/24px` azure — index.html:317-318, 1415,
   3019-3022, 986-988) : la phase 7 a tué les halos boutons mais pas ceux des champs. Supprimer
   partout (bordure azure simple au focus) ? → **Réponse :**
6. **Lignes de devis (Accueil/Historique)** : cartes séparées espacées (actuel) vs conteneur-carte
   unique à séparateurs internes (maquette). Assumer ou basculer ? → **Réponse :**
7. **Onglet Bugs** : le seul non refondu. La maquette veut : grille 360px/1fr, type Bug/Suggestion,
   statut ternaire Ouvert/En cours/Résolu → nécessite 2 champs de schéma `S.bugs.items[]`
   (`type`, statut) = décision produit, pas juste de la peau. Refonte complète, ou reskin
   minimal (pills/couleurs/panneaux) sans toucher au schéma ? → **Réponse :**
8. **Profil — cartes manquantes** : ajouter la carte « CGV & mentions par défaut » (pleine
   largeur, boutons Modifier/Gérer) et la carte « URSSAF » (taux + note CFP) prévues par
   Refonte.md §7 ? → **Réponse :**
9. **Clients — badge type entreprise/particulier** : le schéma client n'a pas de champ `type`.
   Dériver du SIRET (présent ⇒ entreprise) ou ajouter un champ ? Ou abandonner le badge ?
   → **Réponse :**
10. **Bilan — bandeau KPI** : actuel = CA mois · CA cumulé · Salaire net cumulé · URSSAF ·
    Marge nette ; spec = CA déclaré · Encaissé · URSSAF (ambre) · Salaire net (jade) ·
    Trésorerie (azure). Recomposer ou garder la composition actuelle (en ajoutant au moins les
    couleurs jade/azure) ? → **Réponse :**
11. **Glyphe `⋮` des `.lock-menu-btn`** : la règle « que du Lucide » l'interdit mais la
    convention `.lock-field` de CLAUDE.md le prescrit. Trancher (Lucide `moreVertical`
    partout + corriger CLAUDE.md ?) → **Réponse :**
12. **Clients — « Encaissé » et remboursements** : `clientsStats` compte un acompte remboursé
    dans l'encaissé du client (le bilan, lui, le régularise). Déduire les remboursements de la
    fiche client ? (point métier) → **Réponse :**

---

## 0. BUGS FONCTIONNELS (à corriger en priorité, indépendants du style)

> **✅ SESSION FAITE (2026-07-14)** — tout corrigé sauf le focus `refreshTauxMatos` (différé,
> cas marginal : seul Entrée-sans-blur perd le focus). Notes :
> - **B3 était plus grave qu'audité** : `validityDate` et `computeDateEcheance` construisaient
>   une date locale puis la sérialisaient en UTC → **fin de validité et échéance de paiement
>   systématiquement 1 jour trop tôt** (pas seulement la nuit). Vérifié par test node
>   (Europe/Paris) : validité 14/07+30j rendait 12/08 au lieu du 13/08, « 30j fin de mois »
>   rendait le 30/08 au lieu du 31/08. Balayage complet : plus AUCUN `toISOString().slice`
>   dans le fichier ; les `toISOString()` restants sont des horodatages complets (légitimes).
> - **B2** : `window.signIn` (mort, aucun appelant) supprimé avec le `window.signOut` fautif.
> - **B6** : le pied de sidebar dérive maintenant de `TABS_AUX_LABELS` (plus de double source).
> - **B7** : la classe de base `.bug-tab-badge` porte un repli neutre → couvre aussi les clés
>   legacy (`parametres`, `majlog`, `templates`) des vieilles notes.
> - **B9** : helper `aboActifNow(e)` = source unique, consommé par `tauxMatos` ET `rAchats`.

- [x] **B1 — CRASH : `ri` non déclaré dans `rDevisArrondiBlock`** (index.html:12671, 12676 :
  `effRemisePct > ri.remiseMaxPct`). Si arrondi « palier »/« cible » actif avec écart ≥ 0.005,
  le render de la section Majorations plante (ReferenceError). Fix : `const ri = computeRemiseInfo();`
  en tête de fonction. ⚠ À re-vérifier avant fix (trouvé par agent).
- [x] **B2 — `window.signOut` écrasé** (index.html:18680 : `window.signOut = () => auth.signOut()`)
  écrase la vraie fonction (4310-4321) qui désabonne `wsUnsubscribeData`/`wsUnsubscribeMeta` et
  reset `workspaceState` → listeners Firestore vivants après déconnexion (erreurs permission).
  Fix : supprimer la ligne 18680.
- [x] **B3 — Dates en UTC (piège `toISOString` documenté CLAUDE.md)** :
  - mois courant KPI/graphe : `toISOString().slice(0,7)` en 16768, 17106, 17555 → entre minuit
    et ~2h le 1ᵉʳ du mois, « CA <mois> » affiche les chiffres du mois précédent. Fix :
    `isoDateLocal(today).slice(0,7)`.
  - dates de jalons timeline : `dateOf` dans `suiviParcoursHtml` (14735) → « Envoyé le J-1 » la
    nuit. Fix : slicer une date locale. (Affichage seul, pas fiscal.)
- [x] **B4 — `backupExportAll` n'exporte pas `S.bin`** (18256-18274) — la corbeille générale est
  perdue au cycle export/import ; `backupImport` ne la restaure pas non plus.
- [x] **B5 — `clientsOpenDevis` vs chip Corbeille** (15999-16002) : si `suiviFilterPrincipal ===
  "corbeille"`, le clic depuis la fiche client ouvre la Corbeille et le devis est invisible.
  Fix : reset `suiviFilterPrincipal = "all"` dans `clientsOpenDevis`.
- [x] **B6 — h1 « Notes » vs sidebar « Bugs & suggestions »** : `TABS_AUX_LABELS.bugs = "Notes"`
  (4043) alimente le h1, le footer sidebar hardcode « Bugs & suggestions » (9278). Aligner (et
  dériver le footer de la constante).
- [x] **B7 — Badge d'onglet Notes sans couleur pour `achats` et `compte`** : `BUG_TAB_OPTIONS`
  (6909-6913) les propose, les variants CSS s'arrêtent avant (1357-1365). Ajouter les variants
  + couleur de repli sur `.bug-tab-badge`.
- [x] **B8 — Compteurs des chips Notes faux quand « validées » affichées** : `bugTabCounts()`
  exclut les validées (6879) alors que la liste peut les montrer.
- [x] **B9 — Achats : deux définitions d'« actif » divergent** : compteur KPI et total tfoot
  testent `!e.dateFin` (17368-17369, 17427, 17506) ; le montant KPI vient de
  `tauxMatos().mensuelActif` qui teste les dates réelles (16631-16633) → incohérences si abo à
  date future. Unifier sur la définition par dates.
- [x] **B10 — mineurs** : avatar Mon Compte sans fallback `onerror` (18016 ; le sidebar l'a, 9262) ·
  hint logo « ~500 KB » vs contrôle 800 KB (10877 vs 10884) · copy Gmail périmée « ✉ Relance
  devis » (18159) · hint capture « #6 » vs convention `note-6.png` (18487-18490 vs 18522) ·
  commentaire périmé lightbox (18685) · `cellCA` : « — » plein contraste quand ca=0 + tag noir
  (17052-17053, `.cp-zero > span` ne s'applique pas) · `refreshTauxMatos` restaure le focus par
  `id` mais les inputs de lignes n'en ont pas (16696-16710 vs 17374-17377).

## 2. SOCLE TRANSVERSE (une passe globale, avant les onglets)

> **✅ PARTIE NON AMBIGUË FAITE (2026-07-14)** : couleurs hors palette → tokens (y compris §14),
> halos décoratifs supprimés (hors focus inputs = Q5), `.btn`→`.mk-btn` partout sauf login
> (`ws-google-btn`, volontaire), glyphes → Lucide (icônes `calendar` + `arrowRight` ajoutées à
> `ICO_PATHS` ; restent les `⋮` = Q11), CSS mort certain purgé (`.ac-cta`, `.ws-row .btn`,
> `.page-title`). **RESTE (arbitrages)** : Q5 halos focus/hover des champs, Q4 typo labels,
> Q11 `⋮`, motif pills unifié, typo inter-onglets (§14 dernier bloc), h3 Inter vs mono,
> grosse purge Q14. Le CSS `.btn`/`.btn-rouge`/`.btn-danger-ghost` reste vivant pour le login —
> à purger quand le login sera reskinné.

- [ ] **Couleurs littérales hors palette V2** (règle : aucun littéral hors `:root`) :
  `#fcd34d`, `#86efac` (Catalogue, 1617-1618 — aussi 2915) · `#8A63D2`/`#22d3ee`/`#ec4899`
  (badges Notes, 1254-1258, 1359-1363) · `#4ade80` (frais & débours volet, 633) ·
  `#a7e8c0`/`#f3c4a2` (bandes terminales, 603-605) · `#c0392b` (SIRET invalide, 17836 →
  `var(--danger)`).
- [ ] **Glows néon résiduels** (phase 7 incomplète) : input Cible + focus (1589-1591),
  `.tarif-final-cell`/`.net-cell` text-shadows (1596-1604), bouton suppression (1553),
  `.bin-item-restore` (2914-2915), champ recherche Clients (986-988), focus inputs global
  (317-318, 1415, 3019-3022 — selon arbitrage Q5).
- [ ] **Famille `.btn` → `.mk-btn`** (phase 7 incomplète) : tout l'onglet Clients (16423-16430,
  16363-16372, 16445-16446), boutons « + Ajouter … » Achats (17489, 17513), corbeille Historique
  (15708-15725), « Historique des versions » du volet (15106, 15112), « Restaurer les modèles »
  Profil (18189). Ensuite : supprimer le CSS `.btn` s'il n'a plus d'usager.
- [ ] **Glyphes unicode → Lucide** : `▸` (472 et 243, `::before` CSS) · `📅` + `●` dans
  `rDateOrEnCoursCell` (16582-16588 ; ajouter `calendar` à `ICO_PATHS`) · `✉` `↺` `✗` (18159,
  18189, 17842) · `⋮` lock-menu-btn + `→` arrondi (12543, 12673, 12718, 12733 — selon Q11).
- [ ] **Titres de section `h3` Inter 15px vs mono** : convention app-wide actuelle (1105, 288,
  17164…) vs spec §0 mono 11px. Décision globale (lié Q4). Au minimum : « Bilan mensuel » (288)
  s'aligne sur `.cp-chart-title` mono voisin.
- [ ] **Pills de statut** : `.dv-stage` = fond teinté 9.5px sans bordure (849-853) vs motif §0
  (mono 8.5px, fond transparent, bordure `<couleur>55`, radius 999). Décision unique — se
  propage à Accueil/Historique/Clients ; `.bug-tab-badge`/`.bug-status-pill` (1351, 1368),
  `.tr-badge` Achats (1620-1623), `.cpt-role-pill` à aligner sur le même motif.
- [ ] **CSS/code mort à purger (local, certain)** : `.ac-cta` (855) · `.ws-row .btn` (353-354) ·
  machinerie ancienne table Suivi : `arr()` ↕▲▼ (15617-15620), `suiviExpandedRowHtml`
  (15123-15130), `suiviDateMenuHtml`/`positionThMenu`/`suiviHeaderMenu*` (15402-15508) + CSS
  `.th-menu` — conséquence : `suiviFilterYears`/`suiviSort` inatteignables → soit re-brancher un
  filtre année en chips, soit tout retirer.

## 3. MISSION (`rMS`) — corrections de peau

> **✅ SESSION FAITE (2026-07-15)** — bannière quick (+ lien Profil sur l'IBAN), titres de
> section mono, fusion « Déplacement & remise » en quick + « Prestation » singulier,
> Annuler en `.mk-btn.outline` (nouvelle variante neutre, documentée CLAUDE.md), bordures
> d'inputs `--border`, récap recoloré, icône `zap`, mode-pill ember, échéance quick
> « À réception ». Toggles fill + arrondi ri + ⋮ + rayons : déjà couverts par le socle.
> Validé par smoke test vm 18/18 (scratchpad). **Non repris (assumés)** : bouton retour
> dans l'en-tête (la sidebar assure le retour) · réf d'en-tête reste en `.v2-meta` 10px
> (primitive partagée).

- [ ] Bannière quick absente : encart `border-left:2px #F5943C` « Prestation rapide — au noir.
  Aucun document émis, pas d'acompte ni de CGV, échéance unique à 100 % » dans `rDevisBanners`
  (12823-12837).
- [ ] `.edit-section-title` Inter 13px → Space Mono 11px 700 `.16em` uppercase `#C6C2D2` (297, 304).
- [ ] Segmented `.violet` → fill azure sur toggles de 1ᵉʳ niveau (selon Q2).
- [ ] Mode rapide : fusionner « Déplacement & remise » et renommer « 02 Prestation » (12288-12292)
  — ou acter.
- [ ] Bannière IBAN : texte gris + icône ember seule colorée, bg `rgba(232,117,28,.07)`, lien
  vers Profil (3133, 11820).
- [ ] Annuler en ghost transparent bordure `.24` au lieu de `subtle` (12251).
- [ ] Bouton retour 32px dans l'en-tête (maquette l.164) — à arbitrer (sidebar rend l'omission
  défendable).
- [ ] Cosmétique : bordure inputs `--border-soft`→`--border` (316, 3017-3023) · récap composantes
  `#C6C2D2`/URSSAF `#9A96A8` au lieu de tout-muted (12206-12218) · icône quick `zap` (à ajouter
  à `ICO_PATHS`) au lieu de `camera` (12168) · réf en-tête 11px/.1em · libellé échéance quick
  « À réception » (4771) · padding sections si accordéon abandonné (Q1).
- [ ] Amélioration : `mode-pill` quick en ember (3086, 12134) — cohérence sémantique « au noir » ambre.

## 4. ACCUEIL (`rAC`)

> **✅ SESSION FAITE (2026-07-15)** — vérifiée par 3 captures headless (Accueil listes, Accueil
> volet déplié, Historique). Titres de section colorés (warn/dim) + hint à droite + compteur
> `(N)` · pastille de ligne colorée par `devisStageLabel().kind` (dot-info/warn/done/refused,
> late garde l'override ember) · **conteneur unique** `.ac-list` (carte glass + séparateurs
> `.ac-row-wrap`, lignes plates) — **profite aussi à l'Historique** (year-seps en sous-en-têtes
> internes) · volet aplati (`--surface-sunken`, `border-top`, plus de shadow/radius élevé) +
> `.ac-row-panel .suv-expanded-panel{padding:0}` · chip facture mono 10px sunken · rev tag
> discret `· revN` sur les lignes (badge jade conservé en Historique des versions + corbeille) ·
> chevron `chevronDown` → rotate 180° · `st` calculé une fois dans `devisRowHtml` (dot + chip).
> **Non repris (cosmétique assumé)** : pill « à encaisser » reste `--ember-300` (les deux teintes
> sont admises par la palette).

- [x] Titres de section colorés : « À relancer » `--warning`, « Annulés/refusés » `--text-dim`
  (814 + classes dans rAC 17696-17720).
- [x] Hint de section aligné à droite de la ligne de titre (11px `#4A4757`), pas en dessous.
- [x] Pastille de ligne colorée par état : dériver du `kind` de `devisStageLabel` (834-835 ;
  paiement azure, refusé `#F08C4B`, envoyé `#4A4757`, relance ember).
- [x] Padding cumulé du volet : `.ac-row-panel .suv-expanded-panel{padding:0}` (826 + 454) —
  corrige Accueil ET Historique.
- [x] Chip facture en mono 10px `--surface-sunken` bordure `--border-soft` padding 2px 7px (663-665).
- [x] Tag rev discret sur les lignes : « · revN » mono `--text-dim` au lieu du badge jade (466,
  14711) — le badge jade reste OK dans Historique des versions. (Ou garder partout — trancher.)
- [x] Volet « carte élevée » (shadow + radius 12, 821-826) vs sous-panneau translucide maquette —
  choix de phase 2, confirmer ou passer en `--surface-sunken` sans shadow.
- [x] Conteneur unique vs cartes séparées (816, 832) — selon Q6.
- [ ] Cosmétique : radius CTA `--radius-sm` (515) · grille/gap ligne (832) · chevron bas→180°
  (845-846, 14716) · compteur avec parenthèses (17695) · pill « à encaisser » `#F5B84C` vs
  `#F5943C` (851) · micro-écarts pastilles timeline (559-563).

## 5. CATALOGUE (`rCatalogue`)

- [ ] `#fcd34d`→`var(--warning)`, `#86efac`→`var(--success)` (1617-1618).
- [ ] Supprimer glows (1589-1604, 1553).
- [ ] Headers de colonnes 13-14px → 9.5-10px mono cohérents avec le reste (1611-1614 ;
  sous-titres 11px→9px).
- [ ] Unité `€/h` DANS la boîte de l'input tarif (pattern `.lock-field.with-unit`) (17290-17293,
  1513-1517).
- [ ] Bouton info « i » texte → `ICO_SZ('info', 14)` (17318-17319, 3034).
- [ ] Cosmétique : `table.hist` glass (`--surface-glass` + `--border-soft`) — décision globale
  (touche Compta/Historique aussi) · libellé de groupe en mono (1575).

## 6. BILAN (`rCP`)

- [ ] Couleurs par colonne : URSSAF ambre (avec « − »), Salaire net jade, Trésorerie azure
  (17181-17204) ; KPI selon Q10.
- [ ] Rappel métier sous le tableau : « Compta de caisse (art. 93 CGI) · Dépenses = achats/abos/
  amortissements · Salaire net = CA déclaré − URSSAF » (11px text-dim, après 17204).
- [ ] « Bilan mensuel » h3 → mono comme `.cp-chart-title` (288 vs 874).
- [ ] Tag noir : préfixe « · » (17050) ; `cellCA` zéro atténué (cf. B10).
- [ ] Chip année dans l'en-tête (actions `v2PageHead`) ou acter le filtre chips actuel (17166-17179).
- [ ] Cosmétique : `.cp-seuil` + `table.hist` en glass (916, 363) · `.cp-chart-val` en mono (888).

## 7. CLIENTS (`rCL`)

- [ ] **Table posée nue sur la photo** : wrapper `.v2-panel` ou fond glass sur lignes (990, 1000,
  16455).
- [ ] Bouton « + Nouveau client » en `.mk-btn azure cta` dans l'en-tête (16420, 16423).
- [ ] `.btn` → `.mk-btn` partout (cf. socle).
- [ ] En-tête du volet fiche : avatar 48px + nom Big Shoulders 22px uppercase + encaissé jade à
  droite (16356-16360, 1027) ; badge type selon Q9.
- [ ] Labels de section volet en mono (`.cli-section h4` 1042, `.cli-dl dt` 1055).
- [ ] Inputs du volet sur `--field-bg` + radius tokens (1034, 1058, 1066) ; recherche sans halo
  + radius token (986-988).
- [ ] Cosmétique : icône contacts `mail` au lieu de `send` (16311) · tag revN sur devis du client
  (16382) · fond volet `--surface-glass` (1024).
- [ ] Améliorations : contacts en sous-cartes `--surface-sunken` · icône `pin` devant l'adresse.

## 8. PROFIL (`rPF`)

- [ ] Cartes « CGV & mentions » et « URSSAF » selon Q8.
- [ ] Carte Modèles d'e-mails : retirer le h3 redondant (18157), h4 → `.v2-label` (18164, 18176),
  `.btn ghost`→`.mk-btn subtle` (18189), glyphes (cf. socle), copy périmée (cf. B10).
- [ ] Logo : placeholder carré pointillés + icône camera + « Importer » (10875-10878).
- [ ] `#c0392b` → `var(--danger)` (17836) ; « ✗ » SIRET → `ICO_SZ('x',12)` pattern flex (17842).
- [ ] Labels 13px → selon Q4.

## 9. HISTORIQUE (`rSV`)

- [ ] Corbeille reskin V2 : lignes type `.ac-row` + `.mk-btn` (15708-15725).
- [ ] `.btn ghost` de « Historique des versions » → `.mk-btn` (15106, 15112) ; `▸` → Lucide (472).
- [ ] `#4ade80` → `var(--success)` (633) ; `#a7e8c0`/`#f3c4a2` → dérivés tokens (603-605).
- [ ] Ellipsis sur `.ac-row-ref` (`overflow:hidden`, 842).
- [ ] Pills `.dv-stage` selon décision socle.
- [ ] À consigner au README (pas de code) : pas de chip « En cours » (devis clos only, les
  vivants sont dans l'Accueil) · pas d'en-tête de colonnes (cohérent Accueil) · libellés
  « Soldé »/« Refusé / Annulé » corrects (la spec §8 « 30 jours » est fausse : rétention = 30 items).

## 10. ACHATS (`rAchats`)

- [ ] `📅`/`●` → Lucide (16582-16588, cf. socle) ; `.btn` → `.mk-btn` (17489, 17513).
- [ ] Bouton « + Ajouter » dans l'en-tête (`v2PageHead("achats", {actions})`, 17442) — ou acter
  les 2 boutons par-table.
- [ ] Carte « Synthèse coûts horaires » au système V2 : `.v2-panel`, label mono, montant en
  Big Shoulders, labels de contrôles mono (789-808).
- [ ] Champs « Heures annuelles »/« Facteur sécurité » en `.lock-field.with-unit` (17457-17462).
- [ ] Cosmétique : « (années) » 13px dans un th 9px (17521) · `.tr-badge` → pill V2 (1620-1623) ·
  KPI 3 renommé « Dépenses /an … déduites du résultat » (17435-17437).
- [ ] Améliorations : « Coût annuel » (dotation) en jade comme maquette · « prochain
  prélèvement » = feature schéma, plus tard.

## 11. BUGS & SUGGESTIONS (`rBG`) — selon Q7

Reskin minimal (sans schéma) : panneaux `--surface-glass` (1287, 1211, 1269) · pills motif V2
(1351, 1368) · couleurs hors palette remappées (1254-1258) · dates mono non-italique (1373) ·
labels de champs + radius 4px (18477-18486) · en-têtes de section mono. Refonte complète (grille
360/1fr + type + statut ternaire) = décision produit Q7. ⚠ Le quick-add actuel (Entrée, Alt+N,
#numéro auto) est plus riche que la maquette — ne pas le perdre.

## 12. MON COMPTE (`rCompte`)

- [ ] Nom en Big Shoulders 22px uppercase (207).
- [ ] Badge « Propriétaire » jade pill 999px (210-211).
- [ ] Indicateur « Synchronisé » (dot + mono jade) sur la carte profil (18020-18034).
- [ ] Déconnexion : encart ember pleine largeur + `.mk-btn ghost` (18032).
- [ ] Membres : avatar initiales + pill statut « Vous / Membre validé / En attente » (18382-18408).
- [ ] Corbeille : `.bin-item-restore` sans glow, boutons `.mk-btn` (2914-2915).
- [ ] Mises à jour : dot ember par entrée non lue (capturer `lastSeen` avant bump, 10463-10488) ·
  date en mono à droite (265, 10476).
- [ ] Cosmétique : `.maj-entry`/`.ws-row` en `--surface-sunken` (263, 347).
- [ ] À noter (pas corriger) : pas de « + Inviter » (modèle = demande+approbation) · « sélecteur
  de compte Google » forcé en dur, checkbox sans objet · structure chips vs grille = choix
  phase 6 à consigner au README.

## 13. SIDEBAR + EN-TÊTES — audit fait (2026-07-14, 2ᵉ passe)

> **✅ CORRIGÉ (2026-07-14)** : bug scroll (nav seule scrolle, pied épinglé), pied 12px +
> colonne icône 24px + « Mon compte » en ink-100/600, pastille brouillon sortie du label
> (alignée à droite), commentaire faux, eyebrow « Compte & workspace », `.page-title` purgé.
> **RESTE** : cosmétiques « à trancher » ci-dessous + Q13 (libellés NAV).

Conforme sur l'essentiel (largeur, wordmark, groupes, item actif, chevrons, dot brouillon,
eyebrows mot pour mot). Restes :

- [ ] **BUG scroll** : `.sb{overflow-y:auto}` fait scroller TOUTE la sidebar sur viewport bas
  (pied Bugs/Mon compte hors écran). Fix : scroll sur `.sb-nav` seule (`flex:1;min-height:0`),
  retirer l'overflow de `.sb`.
- [ ] Pied de sidebar : hérite du style des enfants de groupe (13px, icône 16) — maquette :
  12px, padding 7px 11px, icône 15 dans colonne 24px centrée (aligne les 2 labels), « Mon
  compte » en `--ink-100` 600.
- [ ] Pastille brouillon d'en-tête : la sortir du span label (droite, entre label et chevron).
- [ ] Commentaire faux ~9241 (« masque au survol » → « quand le groupe est ouvert »).
- [ ] Eyebrow Mon Compte « Réglages & workspace » → « Compte & workspace » (maquette).
- [ ] Cosmétique à trancher : label groupe `--ink-400` vs #8A8698 maquette · `has-active`
  éclaircit le label (maquette : icône seule) · chevron 14 vs 13px · filet en-têtes `--border`
  .14 vs .12 maquette (token global, à acter).
- [ ] CSS mort : `.page-title` + sous-règles (285-287).
- Écart documenté (ne pas « corriger ») : badge « Brouillon » texte → point ember (CLAUDE.md).

## 14. BALAYAGE GLOBAL (2ᵉ passe) — compléments au socle §2

- [ ] **Survivances NAVY pré-V2** (les vraies) : `#cliPickPortal` rgba(15,34,64,.95) + glow (1172),
  `.lock-popup` idem (1428), `.modal-overlay` rgba(8,15,28,.72) (2781).
- [ ] **2ᵉ `:root` pirate** (445-449) : `--violet/--violet-dark/--violet-soft` doublonnent
  `--neon-violet*` du 1ᵉʳ :root → fusionner ; `.pst[data-s="en_cours"]` violet à statuer.
- [ ] Hors palette additionnels : teal #5EEAD4 (1178-1179), #E74C3C (3045, 3051), #062b27 (1508),
  #fca5a5 (2878), #86efac 3ᵉ occ. (3014 `.lg-justif.on`), #9FC6F5 (3107), #C24E12 (16251),
  #c0392b 2ᵉ occ. + fallbacks `var(--success,#2e7d32)` (5712, 5718), `.rich-editor a` #0066cc
  (2951). Ne pas toucher : logo Google (9387), bandeaux d'erreur debug (#fee/#900/#c00).
- [ ] **Halos néon décoratifs** (hors focus inputs = Q5) : `.sb-user-menu-dot`/`.cpt-chip-dot`
  (186, 196), pastilles `.pst` (381-385, 449), `.undo-toast` (2899), `.cgv-edit-remove`
  (2877-2878), `.dp-cgv-add-btn` triple halo (2893-2894), `.dp-rich-zone`/btn (2858-2859),
  `.lg-justif.on` (3014-3015), `.placeholder-chip:hover` (261). Famille focus Q5 étendue :
  `.ech-row`/`.pct-wrap` (2714-2718), `.contact-inline` (2774), `.cli-pick` (1159), `.lg-*`
  (3020-3031, 3080-3081). À CONSERVER : `@keyframes dvpulse` (566, présent maquette).
- [ ] Typo inter-onglets : date de devis fiche client mono 11px vs Inter 12px partagé (1023 vs
  839) · réfs mono 9.5/10/10.5px → 10px partout · `cli-table td` 14px vs `table.hist` 13px ·
  lexique Gmail th Inter 11px → motif mono. (KPI Accueil ≠ KPI Compta : conforme maquette,
  ne pas unifier.)

## QUESTIONS OUVERTES — complément (2ᵉ passe)

13. **Libellés NAV** : le code dit « Missions / Devis en cours / Achats & Abonnements » là où
    maquette + CLAUDE.md disent « Mission / Suivi devis / Achats ». Renommage volontaire
    (→ mettre CLAUDE.md à jour) ou retour aux libellés maquette (pilote aussi les h1) ?
    → **Réponse :**
14. **Purge > 50 lignes** (validation requise par CLAUDE.md) : machinerie morte de l'ancienne
    table Suivi (`arr()`, `suiviExpandedRowHtml`, `suiviDateMenuHtml`/`positionThMenu`/
    `suiviHeaderMenu*` + CSS `.th-menu`, ~150 lignes, zéro point d'entrée UI) — et avec elle
    le filtre année `suiviFilterYears` devenu inatteignable. Supprimer, ou re-brancher un
    filtre année en chips d'abord ? → **Réponse :**
