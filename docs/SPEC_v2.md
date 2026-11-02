# Shortim — spécification v2 (refonte DA + animations + fonctionnalités)

Ce fichier remplace `docs/CLAUDE_v1_legacy.md` (conservé pour mémoire : c'est le
cahier des charges de la v1, déjà implémentée et qui tourne). **Lis d'abord
`docs/DESIGN.md`** (DA complète : couleurs, typo, motion, logo) avant de
toucher au code — c'est la référence visuelle contraignante pour tout ce qui
suit, elle prime sur toute couleur/police codée en dur dans la v1.

## Contexte
La v1 (marche fonctionnelle, testée) avait un visuel bleu marine/blanc minimal.
On la fait évoluer vers la vraie identité de marque Shortim/Essef (dark premium,
crème, Playfair Display + monospace), on ajoute de vraies animations partout,
la sauvegarde de séries nommées, un écran Réglages complet, et le multilingue
FR/EN. La logique métier du moteur de timer (horloge murale, bips T-3/T-2/T-1,
répétition de série) ne change pas — on construit par-dessus, pas par-dessous.

## 1. Application de la DA (voir docs/DESIGN.md)
- Remplacer tous les usages de bleu marine / blanc par les tokens `ink`
  (`#050506`), `cream` (`#f4f1ea`), échelle `brand-300..700`, texte body
  `#F7F7F8`.
- Typo : `google_fonts` → Playfair Display (wordmark/splash/à-propos),
  monospace tabulaire (JetBrains Mono ou Space Mono) pour le décompte principal
  et les labels, sans-serif système pour le reste de l'UI.
- Boutons pill crème/texte noir (primaire) ou outline crème (secondaire).
- Logo : intégrer `assets/logos/shortim-*.svg` (déjà présents dans le repo,
  dérivés de `app-chrono`). Utiliser `flutter_svg` pour l'affichage statique.
  Icône d'app iOS = `shortim-app-icon-1024.svg` (générer les tailles requises
  dans `ios/Runner/Assets.xcassets/AppIcon.appiconset`).

## 2. Animations (exigence forte de l'utilisateur : "plein d'animations dans tous les sens", mais toujours sobres/fluides, pas de confettis)
Durées/easings = ceux de `docs/DESIGN.md` (`fast`/`base`/`slow`,
`brand`/`emphasis`). Chaque point ci-dessous doit être une vraie animation
pilotée par `AnimationController`, pas un simple `AnimatedContainer` par défaut
qu'on n'a pas réglé :

- **Splash au lancement** : reproduire la timeline du mark animé (ring se
  dessine 0–1.1s, couronne apparaît 1.1–1.5s, "clic" avec léger rebond vers
  1.9s via easing `emphasis`, tient, puis transition fluide vers l'écran de
  saisie). Implémenté en `CustomPainter` sur les paths `ring`/`crown`/`hand`
  (coordonnées dans `docs/DESIGN.md`), pas en rejouant le CSS du SVG.
- **Sélection/ajout d'un intervalle** (écran de saisie) : quand on ajoute un
  intervalle (bouton "+"), la nouvelle carte doit apparaître avec un effet
  d'entrée marqué (scale + fade + léger slide, easing `emphasis`), pas juste
  un `insert` muet dans une liste. Suppression = sortie animée symétrique.
  Réordonnancement (drag) : animation fluide de réinsertion.
- **Changement d'intervalle pendant l'exécution** : transition visible et
  distincte du simple changement de texte (ex. crossfade + léger scale sur le
  chiffre, pulse sur l'anneau) synchronisée avec le son de changement
  d'intervalle.
- **Décompte principal** : anneau circulaire qui se vide en continu (pas de
  à-coups, interpolé frame par frame depuis le moteur horloge-murale) autour
  du temps MM:SS, **+ pulsation visuelle synchronisée aux 3 derniers bips**
  (T-3/T-2/T-1) : léger scale-up/down ou glow sur l'anneau à chaque bip, en
  plus du son (décision prise au clarify précédent).
- **Pause/reprendre** : transition claire (ex. l'anneau se grise/désature en
  pause puis retrouve sa couleur crème à la reprise), pas juste un texte de
  bouton qui change.
- **Fin de série** : animation de clôture sobre (ex. anneau qui se referme en
  un trait continu + léger zoom du texte "Terminé"), sans confettis ni couleurs
  flashy — cohérent avec le "sobre" validé au clarify.
- **Navigation entre écrans** (Saisie ↔ Exécution ↔ Mes séries ↔ Réglages) :
  transitions de page personnalisées (pas le push/pop par défaut Material) —
  fade+slide ou shared-element sur le logo/l'anneau quand c'est pertinent.

## 3. Séries sauvegardées ("Mes séries")
- Sur l'écran de saisie, bouton **"Enregistrer"** distinct du bouton
  "Démarrer" : ouvre une boîte de dialogue pour nommer la série (placeholder
  type "Muscu1", "Pompes1" — pas de suggestion auto-générée imposée, l'usager
  tape ce qu'il veut). Démarrer sans enregistrer reste possible (série
  éphémère).
- Nouvel écran **"Mes séries"** (accessible depuis l'écran de saisie, ex. bouton
  ou onglet) : liste des séries sauvegardées (nom + résumé type "8 intervalles
  · 12:30 · ×3"), avec pour chaque entrée : lancer directement, renommer,
  supprimer. Appui sur une série charge ses intervalles dans l'écran de saisie
  (modifiable avant de lancer).
- Persistance locale (ex. `shared_preferences` en JSON, ou un fichier) : liste
  de `{name, intervals, loopMode, loopCount}`.

## 4. Écran Réglages (icône roue crantée, accessible depuis l'écran de saisie)
Contenu (validé au clarify) :
- **Langue** : FR / EN, par défaut auto-détectée depuis la langue système au
  premier lancement, modifiable manuellement ici (persisté, prioritaire sur la
  détection auto une fois choisie). Utiliser `flutter_localizations` + fichiers
  `.arb` (ou `easy_localization`) — tous les textes UI doivent passer par les
  clés de traduction, aucun texte FR/EN en dur dans les widgets.
- **Son** : on/off global, + **choix du thème sonore** parmi plusieurs styles
  (voir section 5) pour le bip de compte à rebours ET pour le son de
  changement d'intervalle (peuvent être liés au même thème ou choisis
  séparément si c'est simple à faire, sinon un seul sélecteur de thème qui
  fixe les deux sons cohérents entre eux).
- **Vibrations/haptique** : on/off (haptique sur les bips, le changement
  d'intervalle, la fin de série).
- **Couleur d'accent** : sélecteur parmi les teintes listées dans
  `docs/DESIGN.md` (crème par défaut + 3 alternatives), appliquée à l'anneau de
  progression et aux boutons primaires.
- **Gestion des séries sauvegardées** : accès à la liste pour renommer/
  supprimer en masse (peut réutiliser l'écran "Mes séries" avec un mode
  édition, pas besoin de dupliquer l'UI).
- Texte explicite ici (contrairement au reste de l'app qui reste très sobre en
  texte) : labels clairs, pas juste des icônes.

## 5. Bibliothèque de sons + ducking audio
- Étendre `tool/generate_sounds.py` (déjà présent, génère des WAV synthétisés)
  pour produire **plusieurs thèmes** sélectionnables dans les Réglages, par
  exemple : "Bip classique" (sin court), "Cloche douce", "Marimba", "Pulse
  électro". Chaque thème fournit un son de compte à rebours (T-3/T-2/T-1) et un
  son de changement d'intervalle distinct, cohérents entre eux.
- **Ducking de la musique en cours** (musique de l'utilisateur jouée par une
  autre app, y compris si la sortie audio est une enceinte Bluetooth/AirPlay —
  le ducking se fait au niveau de la session audio système, donc ça s'applique
  quel que soit le device de sortie) : configurer la session audio (package
  `audio_session`) en catégorie *playback* avec l'option **`duckOthers`**
  (+`mixWithOthers` si on veut aussi permettre la lecture simultanée sans
  couper), pour que les bips baissent temporairement le volume de la musique
  en cours puis le restaurent en douceur à la fin du son (pas de coupure
  brutale). Documenter dans le README la limite connue si `duckOthers` ne
  fonctionne pas sur toutes les apps tierces (certaines ne respectent pas le
  ducking système).

## 6. Multilingue FR/EN
- `flutter gen-l10n` (fichiers `.arb` `lib/l10n/app_fr.arb` / `app_en.arb`) ou
  `easy_localization` — choisis l'approche la plus simple à maintenir pour ce
  projet, mais aucun texte visible ne doit être codé en dur dans les widgets.
  Détection auto de la langue système au premier lancement (`FR` si le système
  est en français, `EN` sinon), override persistant dans Réglages.

## Définition de "terminé"
1. `flutter analyze` sans erreur.
2. `flutter test` passe (adapter/étendre les tests existants du moteur de
   timer si leur interface change ; ajouter des tests sur la persistance des
   séries sauvegardées et sur le changement de langue si raisonnable).
3. Build + run sur le simulateur iOS : écran de saisie et écran d'exécution
   reflètent la nouvelle DA (dark/crème, Playfair + mono), les animations
   listées en section 2 sont visibles et fluides, "Mes séries" et "Réglages"
   sont fonctionnels, le changement de langue FR/EN se reflète immédiatement
   sur l'UI.
4. Commits clairs, poussés sur `origin/main`.

## Décisions laissées à ta discrétion (documente-les dans le README)
- Détail exact des courbes d'easing Flutter (`Curves.easeOutCubic` etc.) tant
  que l'esprit "doux" vs "léger rebond" de `docs/DESIGN.md` est respecté.
- Mécanique exacte du drag & drop de réordonnancement (ReorderableListView ou
  custom), tant que l'animation reste fluide.
- Inclure ou non la variante "lockup-essef" (avec signature Essef) dans le
  splash, vs la variante lockup simple — les deux fichiers sont disponibles
  dans `assets/logos/`.
