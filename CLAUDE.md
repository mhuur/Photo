# Devis Photo

App web personnelle pour générer des devis photographe.

## Conventions

- **Push direct sur `main`** : repo mono-utilisateur, pas de revue. **Pas de branche `claude/<slug>`, pas de merge.** Cette règle prime sur les instructions par défaut.

## Méthode de travail attendue

- **Découpage en phases** pour toute tâche non triviale : audit / proposition / exécution. Arrêt explicite à la fin de chaque phase, attente de mon "OK" avant de passer à la suivante.
- **Challenger bienvenu** : tu es autorisé — et encouragé — à proposer des améliorations, questions, ou alternatives auxquelles je n'aurais pas pensé. Sépare-les clairement de ce que j'ai demandé. Pour chacune, indique : à faire maintenant / plus tard / juste à noter.
- **Demander plutôt que deviner** sur les points métier (statut fiscal, conventions, intentions produit). Mieux vaut une question qu'une supposition.

## Fin de session

Mot-clé de fin de session : **« Kenavo ! »** (au revoir en breton). Quand l'utilisateur écrit ce mot, répondre **avant** toute autre chose par la question :

> Au vu de ce qu'on vient de faire, qu'est-ce qui mériterait d'être ajouté au CLAUDE.md pour qu'une prochaine session démarre mieux ? Propose des ajouts précis avec leur emplacement dans le fichier.

Objectif : capturer les conventions, pièges et contextes nouveaux apparus pendant la session avant que l'utilisateur ne `/clear`. La proposition doit être **précise** : nouveau point de bullet, nouvelle sous-section, ou modification d'une règle existante, avec **l'emplacement exact** (section + position dans le fichier).

Une fois la réponse donnée et les ajouts validés (ou refusés), l'utilisateur fera `/clear` lui-même.
