# Shortim — spécification produit et technique (v2, document central)

Shortim est une app iOS (Flutter) : minuteur à intervalles personnalisés.
Ce fichier est la référence unique et à jour du projet (v1 déjà livrée et
qui tourne, ce document décrit maintenant l'état cible v2 : refonte DA,
animations, séries sauvegardées, réglages, multilingue, sons).

## 0. État actuel (v1 livrée)
- Moteur de timer horloge-murale (`lib/services/timer_engine.dart`), testé
  (22 tests unitaires + 1 test d'intégration réel sur simulateur).
  **Ne pas casser cette logique** : bips T-3/T-2/T-1, son distinct au
  changement d'intervalle, pause/stop, répétition de série (once/repeatN).
- Écran de saisie (intervalles min/sec, +, édition/suppression/réorg,
  jusqu'à 30, choix répétition) et écran d'exécution (décompte, prochain
  intervalle, pause, arrêt) fonctionnels.

## 1. Direction artistique : design system Essef
**Source de vérité : `~/Developer/essef-design-system/DESIGN.md`** (tokens Flutter : `essef_tokens.dart`). Lire avant tout travail UI et le mettre à jour dans le même travail que toute évolution visuelle (exigence d'Allan). Zéro legacy hors demande explicite d'Allan (voir « Don't » du DESIGN.md : accent réglable, bleu marine v1, Oswald/Bebas, nom « Chrono », etc.).

Spécifique à Shortim :
- **Palettes** (`lib/theme.dart`, `AppPalette`) : couple fond / typographie nommé (Sprint, Gym Floor, Endurance, Flow), choisi dans Réglages via une bulle coupée en diagonale. Remplace l'ancienne « couleur d'accent ». Les écrans de marque (splash, lockup) restent monochromes.
- **Typo** : Playfair Display 400 (wordmark, titre d'écran uniquement), sans système pour l'UI, JetBrains Mono tabulaire pour le décompte et les labels. Polices embarquées dans `assets/google_fonts/`.
- **Logo** : `assets/logos/shortim-*.svg` (mark horloge anneau + aiguille + couronne, lockups, `-essef`, app icon fond `#0A0A0A`, mark `#F2F2F0`). Splash = timeline du mark animé reproduite en `CustomPainter`.
- **Mascotte** sous le décompte (`lib/widgets/mascot*.dart`), couleurs dérivées de la palette courante.

## 2. Animations à implémenter (vraies, pilotées par `AnimationController`)
Exigence utilisateur : "plein d'animations dans tous les sens", mais fluides
et sobres (pas de `AnimatedContainer` par défaut non réglé, pas de confettis) :

1. **Splash au lancement** : reproduit la timeline du mark animé ci-dessus en
   `CustomPainter` sur les paths `ring`/`crown`/`hand`, easing `emphasis` sur
   le "clic", puis transition fluide vers l'écran de saisie.
2. **Ajout d'intervalle** (bouton "+") : la carte apparaît avec scale + fade +
   léger slide (`emphasis`). Suppression = sortie symétrique. Réordonnancement
   (drag) : réinsertion animée fluide.
3. **Changement d'intervalle en exécution** : crossfade + léger scale sur le
   chiffre, pulse sur l'anneau, synchronisé avec le son de changement.
4. **Décompte principal** : anneau circulaire qui se vide en continu (interpolé
   frame par frame depuis l'horloge murale, pas d'à-coups) + pulsation
   visuelle (scale/glow) synchronisée aux bips T-3/T-2/T-1.
5. **Pause/reprendre** : l'anneau se désature en pause, retrouve sa couleur à
   la reprise (pas juste un changement de texte de bouton).
6. **Fin de série** : anneau qui se referme en un trait continu + léger zoom
   du texte "Terminé", sobre (pas de confettis).
7. **Navigation entre écrans** (Saisie ↔ Exécution ↔ Mes séries ↔ Réglages) :
   transitions de page personnalisées (fade+slide), pas le push/pop Material
   par défaut.

## 3. Séries sauvegardées ("Mes séries")
- Bouton **"Enregistrer"** sur l'écran de saisie (distinct de "Démarrer") :
  dialogue pour nommer la série (placeholder = nom drôle aléatoire FR/EN,
  l'utilisateur tape ce qu'il veut). Démarrer sans enregistrer reste possible.
- Écran **"Mes séries"** : liste des séries sauvegardées (nom + résumé "8
  intervalles · 12:30 · ×3"), actions lancer / renommer / supprimer. Charger
  une série remplit l'écran de saisie (modifiable avant de lancer).
- Persistance locale (`shared_preferences` JSON ou fichier) :
  `{name, intervals, loopMode, loopCount}[]`.

## 4. Écran Réglages (menu flottant en bas)
- **Langue** FR/EN : auto-détectée depuis le système au premier lancement,
  override manuel persistant. Tous les textes UI via clés de traduction
  (`flutter gen-l10n` ou `easy_localization`), aucun texte en dur.
- **Son** : on/off global + choix de thème sonore (section 5).
- **Vibrations/haptique** : on/off (bips, changement d'intervalle, fin).
- **Palette** : sélecteur parmi les 4 palettes de la section 1 (bulle diagonale fond / typographie).
- **Gestion des séries sauvegardées** : renommer/supprimer (peut réutiliser
  l'écran "Mes séries" en mode édition).
- Contrairement au reste de l'app (très sobre en texte), cet écran peut être
  explicite : labels clairs, pas juste des icônes.

## 5. Sons + ducking audio
- Étendre `tool/generate_sounds.py` pour produire plusieurs thèmes
  sélectionnables : "Bip classique", "Cloche douce", "Marimba", "Pulse
  électro" — chacun avec un son de compte à rebours et un son de changement
  d'intervalle cohérents entre eux.
- **Ducking** de la musique en cours (y compris sortie Bluetooth/AirPlay, le
  ducking opère au niveau de la session audio système donc indépendant du
  device de sortie) : package `audio_session`, catégorie *playback*, option
  `duckOthers` (+ `mixWithOthers` si pertinent), restauration douce du volume
  après le son. Documenter la limite si certaines apps tierces ignorent le
  ducking système.

## 6. Multilingue FR/EN
- Détection auto de la langue système au premier lancement (FR si système en
  français, EN sinon), override persistant dans Réglages. Aucun texte visible
  codé en dur dans les widgets.

## Définition de "terminé"
1. `flutter analyze` sans erreur.
2. `flutter test` passe (étendre les tests existants si l'interface du moteur
   change ; ajouter des tests sur la persistance des séries et le changement
   de langue si raisonnable).
3. Build + run sur simulateur iOS : nouvelle DA visible (dark/crème, Playfair
   + mono), animations de la section 2 visibles et fluides, "Mes séries" et
   "Réglages" fonctionnels, changement de langue FR/EN immédiat.
4. Commits clairs, poussés sur `origin/main`.

## Méthode de travail imposée par l'utilisateur
**Important : avancer par étapes visibles, pas en un seul run opaque.**
Travailler par petites étapes (une section à la fois : DA/typo d'abord, puis
animations écran de saisie, puis écran d'exécution, puis Mes séries, puis
Réglages/i18n/sons), avec un commit par étape et un résumé court de ce qui a
été fait avant de passer à la suite, pour que l'utilisateur puisse suivre et
interrompre si besoin.

## Décisions laissées à ta discrétion (à documenter dans le README)
- Détail exact des courbes Flutter (`Curves...`) tant que l'esprit "doux" vs
  "léger rebond" est respecté.
- Mécanique du drag & drop (ReorderableListView ou custom).
- Inclure ou non la variante "lockup-essef" (signature Essef) dans le splash.
