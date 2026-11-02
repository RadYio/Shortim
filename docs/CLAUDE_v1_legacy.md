# Shortim — spécification produit et technique

Shortim est une app iOS (Flutter) : minuteur à intervalles personnalisés,
visuel épuré, fond bleu marine, boutons blancs.

## Stack
- Flutter (déjà scaffoldé dans ce repo, target iOS en priorité, Android en bonus si ça ne coûte rien).
- Pas de backend, pas de compte : tout est local, state en mémoire + persistance locale simple (shared_preferences ou fichier JSON) pour permettre de relancer une série si l'app est tuée par erreur (nice-to-have, pas critique).
- Packages suggérés : `audioplayers` ou `just_audio` (sons + lecture background), `wakelock_plus` (écran allumé pendant le run, optionnel), `flutter_local_notifications` si besoin de notifier le changement d'intervalle écran verrouillé (optionnel, le son suffit comme exigence minimale).

## Palette / UI
- Fond : bleu marine (`#0A1A33` ou proche, à ajuster pour un bon contraste).
- Texte et boutons : blanc, contours blancs, pas d'icônes chargées, interface minimaliste (gros chiffres, peu de texte).
- Pas de dégradés voyants, pas d'ombres excessives. Typo grande et lisible pour le temps principal.

## Modèle de données
```
Interval { id, minutes: int (0-59), seconds: int (0-59) }  // durée totale = minutes*60+seconds, doit être > 0
Series {
  intervals: List<Interval>  // 1 à 30 intervalles max
  loopMode: enum { once, repeatN }
  loopCount: int  // utilisé seulement si repeatN, >=1 (pas de "infini" dans cette v1)
}
```

## Écran 1 — Saisie de la série
- Un sélecteur minutes + secondes (type "picker" roue ou stepper, au choix, mais rapide à manipuler) pour saisir le **premier** intervalle.
- Un bouton **"+"** à droite de l'intervalle courant qui ajoute un nouvel intervalle (nouveau sélecteur minutes/secondes) à la suite, jusqu'à 30 intervalles max (désactiver/masquer le "+" au-delà, message discret si on tente d'en ajouter un 31e).
- Chaque intervalle déjà ajouté doit rester éditable : on peut changer son temps, le supprimer (bouton suppression par intervalle), et réordonner la liste (drag & drop ou boutons monter/descendre) — tout ça **avant validation**.
- Affichage de la liste des intervalles ajoutés sous forme compacte (ex: "1. 00:45", "2. 00:15", ...), avec le total cumulé visible (ex: "Durée totale : 12:30").
- Option "Répéter la série" : toggle/segmented control
  - "1 fois" (défaut) : un seul passage à travers tous les intervalles puis fin.
  - "Répéter x fois" : champ numérique (stepper) pour définir le nombre de répétitions de la série entière (ex: 3 → toute la série de N intervalles tourne 3 fois à la suite).
- Bouton "Démarrer" (validation) qui lance l'écran 2 avec la série construite. Désactivé si aucun intervalle valide (durée 0).

## Écran 2 — Exécution du minuteur
- Affichage principal : **décompte du temps restant** de l'intervalle en cours, en gros chiffres (MM:SS).
- Juste en dessous (plus petit) : **temps de la prochaine intervalle** (sa durée, ex: "Suivant : 00:30"), ou "Dernier intervalle" / "Terminé" si c'est le dernier.
- Indicateur discret de progression : numéro d'intervalle courant / total (ex: "Intervalle 3/8"), et si loopMode=repeatN, le tour courant / total (ex: "Tour 2/3").
- Bouton **Pause** : met en pause le décompte (le son ne doit pas se déclencher pendant la pause) ; devient "Reprendre" une fois pressé.
- Bouton **Arrêt total** : stoppe complètement et ramène à l'écran de saisie (avec confirmation simple, ex: dialogue "Arrêter la série ?").
- Fin de série : écran ou état "Terminé" clair (retour possible à l'écran de saisie ou relance de la même série).

## Logique sonore
- **Bip des 3 dernières secondes** de chaque intervalle (y compris le tout dernier intervalle de la série/de chaque tour) : un bip court à T-3, T-2, T-1 (secondes restantes), son identique à chaque fois.
- **Son distinct au changement d'intervalle** (déclenché exactement quand un intervalle se termine et que le suivant démarre, y compris au changement de tour en mode répétition) : son différent du bip de compte à rebours, pour bien marquer "nouvel intervalle qui démarre".
- Aucun son pendant la pause. Au "Reprendre", le décompte sonore repart normalement sur le temps restant.
- Utiliser des sons simples (bips synthé courts), inclus en asset ou générés, pas besoin de voix.

## Fonctionnement arrière-plan / écran verrouillé
- Exigence : le minuteur doit continuer à décompter et à jouer les sons même si l'app passe en arrière-plan ou que l'écran est verrouillé.
- Approche recommandée : activer le mode background "Audio, AirPlay, and Picture in Picture" dans Info.plist/Xcode, et garder une session audio active (ex: piste silencieuse en boucle très faible volume, ou simplement le fait de jouer les bips via un lecteur audio en catégorie "playback") pour empêcher iOS de suspendre le process. Le calcul du temps restant doit être basé sur une horloge murale (`DateTime.now()` comparé à un timestamp de fin d'intervalle stocké), jamais sur un simple compteur de ticks, pour rester exact même si l'app est throttée en arrière-plan.
- Documenter dans le code/README les limites connues si l'approche a des contraintes iOS (ex: nécessité que l'utilisateur garde l'app lancée, pas totalement "killée").

## Contraintes générales
- Max 30 intervalles.
- Minutes/secondes : 0-59 chacun, picker rapide (pas de clavier numérique obligatoire mais acceptable en alternative).
- Code Flutter propre : séparer modèle (Series/Interval), moteur de timer (service dédié, testable, basé sur horloge murale), écrans (saisie / exécution), widgets de picker réutilisables.
- Ajouter quelques tests unitaires sur le moteur de timer (calcul du temps restant, transition d'intervalle, déclenchement des bips à T-3/T-2/T-1, gestion de la répétition de série) — pas besoin de couverture UI exhaustive.
- README.md avec : description de l'app, comment lancer (`flutter run`), choix techniques, limitations connues (background iOS).

## Définition de "terminé" pour cette tâche
1. `flutter analyze` sans erreur bloquante.
2. `flutter test` passe sur les tests du moteur de timer.
3. L'app se lance sur le simulateur iOS et permet de : saisir plusieurs intervalles (ajout/édition/suppression/réordonnancement), choisir répétition simple ou multiple, démarrer, voir le décompte + prochain intervalle, mettre en pause/reprendre, arrêter totalement.
4. Commits git clairs et poussés sur `origin/main` (le remote est déjà configuré).
