# Shortim

Minuteur à intervalles personnalisés pour iOS (Flutter) : visuel épuré, fond
bleu marine, boutons blancs.

- Jusqu'à **30 intervalles** (minutes 0-59 + secondes 0-59), éditables,
  supprimables et réordonnables (glisser-déposer) avant le départ.
- Série jouée **1 fois** ou **répétée N fois** (1-99).
- Pendant l'exécution : gros décompte `MM:SS`, durée de l'intervalle suivant,
  position (`Intervalle 3/8`, `Tour 2/3`), pause / reprise, arrêt avec
  confirmation, écran « Terminé » avec relance.
- **Bip court à T-3, T-2, T-1** de chaque intervalle, **son distinct** à
  chaque changement d'intervalle (y compris au changement de tour) et au
  démarrage, mélodie de fin de série. Aucun son pendant la pause.
- Continue de décompter et de sonner **en arrière-plan / écran verrouillé**.
- La dernière série est mémorisée ; une série interrompue (app tuée) peut
  être reprise au relancement.

## Lancer

```bash
flutter pub get
flutter run            # simulateur ou appareil iOS
flutter test           # tests du moteur de timer + smoke tests UI
flutter analyze
```

> Avec Xcode 27, `flutter build ios --simulator` (build multi-architecture)
> échoue sur une vérification `lipo` de Flutter 3.44 ; `flutter run -d <simulateur>`
> fonctionne (build mono-architecture).

## Architecture

```
lib/
  models/            TimerInterval, Series (+ JSON)
  services/
    timer_engine.dart    moteur pur Dart, basé sur l'horloge murale, testable
    run_controller.dart  relie moteur, sons, wakelock et persistance (ChangeNotifier)
    sound_service.dart   lecture des sons (audioplayers) + boucle silencieuse
    storage_service.dart shared_preferences : brouillon + run en cours
  screens/           setup_screen (saisie), run_screen (exécution)
  widgets/           DurationPicker (roues min/s), RoundIconButton
assets/sounds/       bips WAV générés par tool/generate_sounds.py
```

### Choix techniques

- **Horloge murale, pas de compteur de ticks.** Le moteur stocke l'instant de
  fin de l'intervalle courant et calcule le temps restant via `DateTime.now()`.
  Le `Timer.periodic` (100 ms) ne sert qu'à rafraîchir l'UI et déclencher les
  sons. Si l'app est ralentie, le moteur rattrape le retard ; les fins
  d'intervalle s'enchaînent à partir de la fin précédente, donc sans dérive.
  Après un saut de plusieurs intervalles, un seul son de changement est joué
  et les bips périmés sont ignorés.
- **Bips** : déclenchés au franchissement exact de 3 s, 2 s et 1 s restantes,
  une seule fois chacun (mémorisé, donc pas de doublon après une pause). Un
  intervalle de 2 s ne bipe qu'à T-1, etc.
- **Moteur injectable** (`clock`) : tous les tests utilisent une horloge
  factice (`test/timer_engine_test.dart`).
- `TimerInterval` plutôt que `Interval` pour éviter le conflit avec la courbe
  d'animation `Interval` de Flutter.
- **Sons** : WAV synthétiques courts générés par script
  (`python3 tool/generate_sounds.py`), pas de dépendance à des fichiers tiers.
- **Session audio iOS** : catégorie `playback` + `mixWithOthers` (la musique
  de l'utilisateur continue), mode d'arrière-plan `audio` dans `Info.plist`.
- `wakelock_plus` garde l'écran allumé pendant le run.

## Arrière-plan iOS : fonctionnement et limites

iOS suspend une app en arrière-plan sauf si elle joue de l'audio. Pendant un
run, Shortim joue donc en boucle une piste **silencieuse** (catégorie
`playback`), ce qui maintient le process actif ; les bips sont joués par
d'autres lecteurs de la même session.

Limites connues :

- L'app doit rester **lancée** : si l'utilisateur la tue (balayage dans le
  sélecteur d'apps) ou si iOS la termine (pression mémoire), le décompte et
  les sons s'arrêtent. Au relancement, Shortim propose de reprendre la série
  là où elle en serait (le temps a continué de s'écouler).
- Une **interruption audio** (appel téléphonique, Siri, autre app audio non
  mixable) peut couper la session ; le décompte reste exact (horloge murale)
  mais des sons peuvent être manqués jusqu'au retour au premier plan.
- Le **mode silencieux** (interrupteur latéral) ne coupe pas les sons, car la
  catégorie `playback` l'ignore — c'est voulu pour un minuteur. Le volume
  média s'applique.
- Pas de notification locale : en arrière-plan, seuls les sons signalent les
  changements d'intervalle.
- Android n'est pas la cible : l'app y fonctionne au premier plan, mais sans
  service de premier plan le système peut la suspendre en arrière-plan.
