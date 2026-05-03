# 12 Pions — Spec canonique des règles

> Cette spec est la **référence unique** des règles du jeu.
> Les implémentations Kotlin (backend), Dart (mobile) et TypeScript (web)
> doivent toutes passer le corpus de tests dans `test-corpus.json`.

## Plateau

- Grille **5×5** (25 cases).
- 2 couleurs : **X (Vert)** et **O (Rouge)**.
- Pièces : pion ou dame.

## Placement initial

| Couleur | Position |
|---|---|
| **X (Vert)** | Rangées 0 et 1 (10 pions) + (2,0) et (2,1) → 12 pions, en haut |
| **O (Rouge)** | Rangées 3 et 4 (10 pions) + (2,3) et (2,4) → 12 pions, en bas |
| Vide | (2,2) |

**Vert (X) commence la partie.**

## Coordonnées

- `r` = ligne (0 en haut, 4 en bas)
- `c` = colonne (0 à gauche, 4 à droite)
- `forward` direction d'avancée :
  - X (Vert, en haut) → `+1` (vers le bas)
  - O (Rouge, en bas) → `-1` (vers le haut)

## Déplacement (sans capture)

### Pion (non-dame)

3 directions seulement :
- avant : `(r + forward, c)`
- côté gauche : `(r, c - 1)`
- côté droit : `(r, c + 1)`

**Jamais en arrière.**

### Dame

Glisse n'importe quelle distance dans les **4 directions orthogonales** :
- haut : `(r-1, c), (r-2, c), …`
- bas : `(r+1, c), (r+2, c), …`
- gauche : `(r, c-1), …`
- droite : `(r, c+1), …`

**Pas de diagonale.** S'arrête avant la première case occupée.

## Capture

**La capture est obligatoire** : si au moins une capture est disponible
pour la couleur dont c'est le tour, le joueur **doit** capturer.

### Pion

Saute par-dessus un ennemi adjacent et atterrit sur la case vide juste
derrière, **uniquement dans les 3 directions autorisées** (avant, gauche, droite).

### Dame

1. Glisse en orthogonal jusqu'à un ennemi (en passant par-dessus des cases vides).
2. Saute par-dessus l'ennemi.
3. **Atterrit sur n'importe quelle case vide au-delà** (plusieurs landings possibles).

### Captures en chaîne (Coudou)

Après une capture, si la pièce qui vient d'atterrir peut **encore capturer**,
elle **doit** continuer. La chaîne s'arrête seulement quand plus aucune capture
n'est possible depuis la position d'arrivée.

## Promotion en dame

Un pion qui atteint **la rangée adverse opposée** devient une dame :
- X atteint la rangée 4 → dame
- O atteint la rangée 0 → dame

**Promotion automatique aussi en cours d'une chaîne de captures.**

### Promotion solo (« lonely pion »)

Si un joueur n'a plus qu'**un seul pion non-dame** sur le plateau, ce pion
est automatiquement promu en dame.

## Surplace (sanction OOPS)

Si un joueur effectue un mouvement alors qu'**une capture était disponible**,
l'adversaire peut activer le mode **Surplace** puis cliquer sur le pion fautif
pour le retirer du plateau.

- L'adversaire dispose d'un **temps limité** pour activer le surplace
  (sinon le tour passe normalement).
- C'est un **droit** de l'adversaire, jamais une obligation.
- L'opération du surplace ne consomme **pas** le tour de l'adversaire :
  une fois le pion retiré, il joue normalement son coup.

## Fin de partie

| Condition | Résultat |
|---|---|
| Un joueur capture le dernier pion adverse | Victoire par capture totale |
| L'adversaire n'a plus aucun coup légal | Victoire par blocage |
| **Chaque joueur n'a plus qu'une seule pièce** | **Match nul automatique** |
| Accord mutuel | Match nul |
| 3 demandes de match nul refusées | Forfait pour le demandeur |
| Joueur abandonne | Forfait |

> **Match nul automatique 1 vs 1** : dès que les deux joueurs sont réduits à
> exactement une pièce chacun, la partie est un match nul. Avec la règle du
> *lonely pion* (promotion automatique du dernier pion non-dame), il s'agit
> en pratique d'un duel dame contre dame, considéré comme nul.

## Timing (en ligne)

- **30 secondes** pour jouer son tour (sinon auto-pass / forfait du tour).
- **3 secondes** entre captures dans une chaîne (sinon auto-end).

## Format de coup (sérialisation)

```json
{
  "from": { "r": 0, "c": 0 },
  "to":   { "r": 1, "c": 0 },
  "captured": null
}
```

Ou pour une capture :
```json
{
  "from": { "r": 1, "c": 1 },
  "to":   { "r": 3, "c": 1 },
  "captured": { "r": 2, "c": 1 }
}
```

Un **tour** est une séquence de coups :
```json
{
  "sequence": [
    { "from": {...}, "to": {...}, "captured": {...} },
    { "from": {...}, "to": {...}, "captured": {...} }
  ]
}
```
