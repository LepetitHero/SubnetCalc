# SubnetCalc

Calculateur de sous-reseaux IPv4, VLSM et regroupement (supernetting),
100% hors-ligne. Ecrit en Flutter.

## Fonctionnalites

- Calcul de sous-reseau : adresse reseau, broadcast, plage utilisable,
  nombre d'hotes, masque, wildcard
- Vue binaire (bits reseau / bits hote)
- Classification d'adresse (classe A-E, privee/publique/loopback/APIPA/
  multicast/CGNAT)
- VLSM : division en N sous-reseaux egaux, ou allocation par besoins en
  hotes personnalises
- Regroupement (supernetting) : plus petit bloc CIDR englobant plusieurs
  reseaux
- Saisie au format `ip/prefixe`, copie des resultats (texte/CSV),
  theme clair/sombre, persistance de la derniere saisie

## Architecture

- `lib/models/` : types de donnees purs (IP, masque, classification...)
- `lib/logic/` : logique metier, sans dependance Flutter, testee
  unitairement (`test/logic/`)
- `lib/ui/` : ecrans et widgets

## Developpement

```bash
flutter pub get
flutter test
flutter run
```

## Licence

GPL-3.0, voir [LICENSE](LICENSE).
