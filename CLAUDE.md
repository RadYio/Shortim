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
- Visuel actuel : bleu marine / blanc (**à remplacer entièrement par la DA
  ci-dessous**).

## 1. Direction artistique (héritée du repo `app-chrono`, adaptée à Shortim)

### Ambiance
Dark mode premium, quasi-noir, feel "tech éditorial" : grosse typo serif pour
les titres/wordmark (effet magazine/luxe), texte body sans-serif neutre,
labels en monospace majuscules. Beaucoup d'air, cartes sobres à bordure fine,
coins arrondis.

### Couleurs (tokens UI)
- `ink` = `#050506` — fond principal (quasi noir)
- `cream` = `#f4f1ea` — accent clair chaud (CTA primaire, anneau de
  progression), défaut de l'accent réglable
- Gris "brand" (texte secondaire / bordures) : `brand-300 #d4d4d8`,
  `brand-400 #a1a1aa`, `brand-500 #71717a`, `brand-600 #52525b`,
  `brand-700 #3f3f46`
- Texte body clair : `#F7F7F8` (blanc cassé, proche `oklch(0.967 0.001 286.375)`)
- Pas de couleur vive dominante. **Accent réglable dans les Réglages** :
  crème (défaut), or mat `#c9a35a`, corail doux `#e8846b`, teal profond
  `#4fb6a3` — jamais de couleur saturée flashy.
- Assets de marque (logo/icône, déjà dans `assets/logos/`) : couleurs figées
  `#0A0A0A` / `#F2F2F0`, volontairement différentes des tokens UI ci-dessus.

### Typographie
- Wordmark / splash / à-propos : **Playfair Display** 400, letter-spacing
  légèrement négatif (package `google_fonts`, pas de fallback système).
- Décompte principal (gros chiffres MM:SS) : **monospace tabulaire**
  (JetBrains Mono ou Space Mono, 600/700) — cohérent avec la famille
  "labels monospace" de la DA, évite que les chiffres sautent en largeur.
  *(Décision actée : l'option "Oswald/Bebas Neue" envisagée avant la
  découverte de cette DA est abandonnée pour rester cohérent avec le système
  existant.)*
- Corps de texte / UI : sans-serif système, neutre.
- Labels/badges ("INTERVALLE 3/8", "TOUR 2/3") : monospace, MAJUSCULES,
  letter-spacing large, `brand-400`.

### Composants
- Boutons pill (radius complet). Primaire = fond crème + texte `ink`.
  Secondaire = outline crème/gris, fond transparent.
- Cartes (ligne d'intervalle, carte série sauvegardée) : fond légèrement plus
  clair que `ink`, bordure 1px subtile, coins très arrondis, padding généreux.

### Motion (tokens)
- Durées : `fast=150ms`, `base=250ms`, `slow=520ms`.
- Easings : `brand = Cubic(.22,1,.36,1)` (doux, transitions courantes),
  `emphasis = Cubic(.34,1.56,.64,1)` (léger rebond, micro-interactions qui
  doivent se sentir vivantes).
- Animations fluides et marquées mais **sobres** : pas de confettis ni de
  couleurs flashy, l'effort visuel va dans le mouvement (transitions, anneau,
  logo), jamais dans des effets gratuits qui nuisent à la lisibilité du temps.

### Logo Shortim
`assets/logos/shortim-*.svg` (déjà présents dans le repo, dérivés de
`app-chrono`, wordmark "Chrono"→"Shortim") :
- `shortim-mark-*.svg` — mark seul (anneau + aiguille + couronne, horloge
  monoligne, `viewBox 0 0 100 100`, `stroke-width 9`, paths `#ring`/`#crown`/
  `#hand`, `pathLength="100"`)
- `shortim-mark-animated-*.svg` — version "draw-on" CSS (référence de
  timeline uniquement, à reproduire nativement) : 0–1.1s anneau se dessine,
  1.1–1.5s couronne apparaît, ~1.9s "clic" (couronne qui plonge, ticks qui
  flashent, aiguille qui se dessine), tient, fade, boucle (boucle non
  nécessaire en app, une seule lecture au splash suffit).
- `shortim-lockup-*.svg` / `shortim-lockup-essef-*.svg` — mark + wordmark
  (+ signature "Essef" optionnelle)
- `shortim-app-icon-1024.svg` / `-animated-1024.svg` — icône app (fond
  `#0A0A0A`, mark `#F2F2F0`)

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
  dialogue pour nommer la série (placeholder type "Muscu1" à titre d'exemple,
  l'utilisateur tape ce qu'il veut). Démarrer sans enregistrer reste possible.
- Écran **"Mes séries"** : liste des séries sauvegardées (nom + résumé "8
  intervalles · 12:30 · ×3"), actions lancer / renommer / supprimer. Charger
  une série remplit l'écran de saisie (modifiable avant de lancer).
- Persistance locale (`shared_preferences` JSON ou fichier) :
  `{name, intervals, loopMode, loopCount}[]`.

## 4. Écran Réglages (icône roue crantée)
- **Langue** FR/EN : auto-détectée depuis le système au premier lancement,
  override manuel persistant. Tous les textes UI via clés de traduction
  (`flutter gen-l10n` ou `easy_localization`), aucun texte en dur.
- **Son** : on/off global + choix de thème sonore (section 5).
- **Vibrations/haptique** : on/off (bips, changement d'intervalle, fin).
- **Couleur d'accent** : sélecteur parmi les 4 teintes de la section 1.
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
