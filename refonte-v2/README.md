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
