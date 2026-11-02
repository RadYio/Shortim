# Direction artistique — Shortim

DA héritée du repo de préparation `app-chrono` (produit **Essef**, au même titre que
NestIPTV), adaptée au nom final **Shortim**. Les tokens ci-dessous remplacent le
fond bleu marine / boutons blancs de la v1 — c'est la DA définitive de l'app.

## Ambiance générale
Dark mode premium, quasi-noir, feel "tech éditorial" : grosse typo serif pour les
titres/wordmark (effet magazine/luxe) contrastée avec du texte body sans-serif
neutre et des labels en monospace majuscules. Beaucoup d'air, cartes très sobres
à bordure fine, coins arrondis.

## Couleurs (tokens UI)
- `--color-ink: #050506` — fond principal (quasi noir, pas du pur `#000`)
- `--color-cream: #f4f1ea` — accent clair chaud (CTA primaire, titres clés, anneau de progression), pas de blanc pur
- Échelle de gris "brand" (texte secondaire / bordures) :
  - `--color-brand-300: #d4d4d8`
  - `--color-brand-400: #a1a1aa`
  - `--color-brand-500: #71717a`
  - `--color-brand-600: #52525b`
  - `--color-brand-700: #3f3f46`
- Texte body clair : blanc cassé `oklch(0.967 0.001 286.375)` (~#F7F7F8)
- Pas de couleur vive dominante : palette monochrome noir/crème/gris. Les couleurs
  saturées restent des accents fonctionnels ponctuels.
- **Accent color réglable** (nouveauté Shortim, demandée par l'utilisateur) : la
  crème `#f4f1ea` est l'accent par défaut, mais l'écran Réglages propose quelques
  teintes alternatives qui restent dans l'esprit "premium sombre" (ex. crème,
  or mat `#c9a35a`, corail doux `#e8846b`, teal profond `#4fb6a3`) — jamais de
  couleur saturée flashy qui casserait l'ambiance.

Assets de marque (logo, app icon) — couleurs officielles, légèrement différentes
des tokens UI ci-dessus (volontaire, cf repo d'origine) :
- `#0A0A0A` (quasi-noir) — version "black" sur fond clair/transparent
- `#F2F2F0` (blanc cassé) — version "white" sur fond sombre/transparent
- App icon : fond plein `#0A0A0A` (1024×1024), mark en `#F2F2F0` centré

## Typographie
- **Wordmark / écrans de marque** (splash, à propos) : *Playfair Display*, poids 400,
  letter-spacing légèrement négatif. Police Google Fonts à embarquer (package
  `google_fonts` en Flutter), pas de fallback système.
- **Décompte principal (gros chiffres MM:SS)** : monospace à chiffres tabulaires
  (`JetBrains Mono` ou `Space Mono`, poids 600/700) — cohérent avec la famille
  "labels en monospace" déjà présente dans la DA, et ça évite que les chiffres
  "sautent" en largeur pendant l'anim. *(Décision prise sans confirmation : la
  piste "Oswald/Bebas Neue" envisagée avant la découverte de cette DA est
  abandonnée au profit de la cohérence avec le système existant.)*
- **Corps de texte / UI (boutons, écran réglages, listes)** : sans-serif système
  (`ui-sans-serif, system-ui`), neutre, lisible.
- **Labels / badges / eyebrows** (ex. "INTERVALLE 3/8", "TOUR 2/3") : monospace,
  MAJUSCULES, letter-spacing large, petite taille, gris atténué (`brand-400`).

## Composants / patterns UI
- **Boutons** : forme pill (radius complet). Primaire = fond crème + texte noir
  (`ink`). Secondaire = outline fin crème/gris sur fond transparent.
- **Cartes** (ex. ligne d'intervalle dans la liste, carte "série sauvegardée") :
  fond légèrement plus clair que `ink`, bordure 1px subtile, coins très arrondis
  (~1–1.5rem), padding généreux.
- **Badges/eyebrow** : pill, bordure fine, texte mono majuscule.

## Motion
- Durées : `fast = 150ms`, `base = 250ms`, `slow = 520ms`.
- Easings : `brand = Cubic(.22, 1, .36, 1)` (doux, pour la plupart des
  transitions), `emphasis = Cubic(.34, 1.56, .64, 1)` (léger overshoot, pour les
  micro-interactions qui doivent se sentir "vivantes" : ajout/suppression
  d'intervalle, validation, fin de série).
- Les animations doivent rester **fluides et marquées mais sobres** : pas de
  confettis ni de couleurs flashy, l'effort visuel se concentre sur le mouvement
  (transitions, anneau de progression, logo au lancement), jamais sur des effets
  gratuits qui nuiraient à la lisibilité du temps.

## Logo Shortim
Fichiers dans `assets/logos/` (dérivés de `app-chrono`, wordmark remplacé
"Chrono" → "Shortim", mêmes proportions de mark) :
- `shortim-mark-black.svg` / `shortim-mark-white.svg` — mark seul (anneau + aiguille + couronne, horloge monoligne)
- `shortim-mark-animated-black.svg` / `shortim-mark-animated-white.svg` — mark avec animation "draw-on" CSS intégrée (boucle ~4s) : 0–1.1s l'anneau se dessine, 1.1–1.5s la couronne apparaît, ~1.9s "clic" (couronne qui plonge, ticks qui flashent, aiguille qui se dessine), tient, puis fade et boucle.
- `shortim-lockup-black.svg` / `shortim-lockup-white.svg` — mark + wordmark "Shortim" (Playfair Display 400)
- `shortim-lockup-essef-black.svg` / `shortim-lockup-essef-white.svg` — idem + signature "Essef" en dessous
- `shortim-lockup-animated-*.svg`, `shortim-lockup-essef-animated-*.svg` — variantes animées des lockups
- `shortim-app-icon-1024.svg` / `shortim-app-icon-animated-1024.svg` — icône app 1024×1024 (fond `#0A0A0A`, mark `#F2F2F0`)

Construction du mark : `viewBox="0 0 100 100"`, `stroke-width="9"`,
`stroke-linecap="butt"`, `stroke-linejoin="miter"`, `fill="none"`, traits ouverts
monolignes (`#ring`, `#crown`, `#hand`, `pathLength="100"` pour l'animation
`stroke-dashoffset`). Utiliser cette même animation "draw-on" du mark comme
**animation de lancement de l'app** (splash screen Shortim), rejouée une fois à
l'ouverture (pas en boucle sur l'écran principal).

## Stack technique
Flutter. Police via `google_fonts` (Playfair Display, JetBrains Mono ou Space
Mono). SVG via `flutter_svg` pour les assets statiques ; l'animation "draw-on"
du logo est reproduite nativement en Flutter (AnimationController + CustomPainter
sur les mêmes paths `ring`/`crown`/`hand`, pas en rejouant le CSS du SVG) pour
rester fluide et pilotable (easing `emphasis`, durée ~1.9s cf timeline ci-dessus).

---
*DA héritée de `app-chrono` (repo de préparation privé), adaptée pour Shortim.*
