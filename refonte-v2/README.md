# Refonte V2 — archive (juillet 2026)

Maquette Claude Design ayant servi de référence à la refonte complète de l'app,
menée en 7 phases entre le 2026-07-13 et le 2026-07-14.

**`maquette-compact.dc.html`** — la maquette. Elle est ARCHIVÉE : la refonte est
livrée, l'app fait autorité. Ne pas la rouvrir pour « vérifier » un détail sans
lire d'abord les écarts assumés ci-dessous.

## Ce qui a été repris

Palette near-black + azure / jade / ember, typos (Big Shoulders Display,
Space Mono, Inter), fond photo sous voile, sidebar à groupes, en-têtes de page,
lignes de devis compactes, timeline verticale du parcours, cartes de mode,
récap sticky de Mission, bandes de KPI.

Les tokens vivent dans le 1ᵉʳ `:root` d'`index.html` — cf. § Charte V2 de
[CLAUDE.md](../CLAUDE.md), qui est la source de vérité, pas cette maquette.

## Écarts ASSUMÉS (ne pas « corriger » en les prenant pour des oublis)

- **Pas de toggle Tableau/Graphe en Compta.** Les deux sont complémentaires : le
  graphe couvre 12 mois glissants, la table tout l'historique. Les masquer l'un
  l'autre coûterait un clic quotidien.
- **Clients reste une table + volet dépliable**, pas un master-detail. La
  sélection multi pour l'envoi groupé (BCC), le tri, le filtre texte et l'export
  CSV dépendent tous de la structure de table. La *valeur* de la maquette
  (avatars, encaissé, devis du client) a été livrée sur la structure existante.
- **Historique garde son volet.** Sans lui, plus d'accès au rewind, aux dates
  d'encaissement ni aux remboursements sur les devis clos.
- **Profil : deux colonnes seulement là où ça aide.** Les blocs à champs
  nombreux (Coordonnées, Statut juridique, Banque, Médiateur) restent pleine
  largeur — à 360 px de colonne, un formulaire de six champs devient illisible.
- **Les barèmes cession / matériel de la maquette ne sont PAS implémentés.**
  C'est une feature à part entière, hors périmètre de la refonte. Le Catalogue
  garde sa piste « Grille » (drag & drop + groupes).

## Écarts assumés — vague 2 (arbitrages du 2026-07-14, cf. REFONTE-SUIVI.md)

- ~~Mission garde son accordéon~~ **RENVERSÉ le 2026-07-15** : le formulaire
  Mission passe aux **sections empilées toujours ouvertes** comme la maquette
  (l'accordéon repliable est abandonné, sa machinerie supprimée).
- **Pas de badge type entreprise/particulier sur la fiche client** : le schéma
  n'a pas de champ `type` et on ne veut ni le dériver du SIRET ni l'ajouter.
- **Bandeau KPI du Bilan : composition conservée** (CA mois · CA cumulé ·
  Salaire net · URSSAF · Marge nette, plus riche que la maquette) — seules les
  couleurs de la spec sont reprises (jade / ambre / azure).
- **Libellés de navigation renommés** : « Missions / Devis en cours /
  Achats / Abonnements » au lieu de « Mission / Suivi devis / Achats » (choix
  utilisateur, propagé aux h1 par construction).
- **Bilan : le filtre par année reste dans la toolbar du tableau**, pas dans
  l'en-tête de page. Les chips « Toutes les années / 20XX » ne filtrent QUE le
  tableau mensuel — les KPI (cumul YTD) et le graphe (12 mois glissants) ne
  bougent pas. Les remonter en actions d'en-tête laisserait croire qu'ils
  pilotent toute la page.
- **Historique : pas de chip « En cours »** dans la barre de filtres. L'onglet
  ne liste que les devis CLOS (Soldé / Refusé / Annulé) ; les devis vivants sont
  dans l'Accueil. Les chips sont donc « Tous · Soldé · Refusé / Annulé ·
  Corbeille ». **Pas d'en-tête de colonnes** (cohérent avec l'Accueil : les
  lignes se lisent seules). La corbeille retient les **30 derniers items**
  (pas « 30 jours » — la spec Refonte.md §8 se trompe sur ce point).
- **Achats : deux boutons « + Ajouter » par-table**, pas un seul dans l'en-tête.
  Abonnement et investissement sont deux entités distinctes (schémas et tables
  séparés) : un unique bouton d'en-tête serait ambigu. Chaque bouton reste
  au-dessus de sa table. Le « Coût annuel » d'amortissement reste neutre (pas
  jade) : dans la palette, jade = net positif — le teinter jurerait avec la
  convention du Bilan où l'amortissement est une dépense.
