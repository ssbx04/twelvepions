# 📱 12 Pions — Liste des écrans (MVP)

> Document de référence pour le UI/UX et le développement.
> Total : **22 écrans MVP** + 4 onboarding skippables.

## Décisions transversales

- 🇫🇷 **Français uniquement** (peut-être anglais en V2)
- 💬 **Chat = messages prédéfinis** (emojis + phrases courtes, pas de texte libre)
- 🎨 **Avatars = initiales générées** sur fond coloré (pas d'upload de photo)
- 📲 **Mobile** = Flutter ; **Web** = SvelteKit ; **Backend** = Spring Boot 3 + Kotlin
- 💾 **Postgres + Redis** ; auth OTP SMS (envoyé dans le terminal backend en dev)
- 💸 Dev 100% local avec Docker Compose ; hosting plus tard

---

## 🔐 Auth — 4 écrans

| # | Écran | Contenu |
|---|---|---|
| 1 | **Splash** | Logo + étoile sénégalaise, bouton "Continuer" |
| 2 | **Numéro de téléphone** | Préfixe `+221` par défaut, validation format |
| 3 | **OTP** | 6 chiffres, renvoi possible après 30s |
| 4 | **Complete profile** | Nom complet, username (unique, vérifié en live), niveau auto-déclaré |

**Niveau auto-déclaré → seed ELO :**
- Débutant → 1000
- Intermédiaire → 1200
- Avancé → 1400
- Expert → 1600

**Flow auth :**
```
Splash → Téléphone → OTP → [vérif user existe ?]
                              ├── oui → Accueil
                              └── non → Complete profile → Onboarding → Accueil
```

---

## 👋 Onboarding — 4 écrans (skippables)

| # | Écran | Contenu |
|---|---|---|
| 5 | **Bienvenue** | "Le jeu de dames sénégalais" — courte intro |
| 6 | **Coudou** | GIF animé d'une capture en chaîne |
| 7 | **Surplace** | GIF de la sanction OOPS |
| 8 | **Dame** | GIF de la promotion |

> Réutilisables depuis l'écran "Règles" plus tard.

---

## 🏠 MVP — 8 écrans

| # | Écran | Contenu |
|---|---|---|
| 9 | **Accueil** | Bouton "Jouer" géant, ELO actuel, dernière partie, amis en ligne, état de Mariama |
| 10 | **Lobby Jouer** | 4 modes : Match rapide / Défier un ami / vs Mariama (4 niveaux) / 2 joueurs même appareil |
| 11 | **Recherche d'adversaire** | Animation matchmaking, bouton "Annuler" |
| 12 | **Partie** (board) | Joueurs haut/bas, ELO, horloge, captures (trophées), chat prédéfini |
| 13 | **Fin de partie** | Résultat, ±ELO gagné, Revanche / Nouveau / Partager |
| 14 | **Profil** (sien + autres) | Avatar généré, stats (V/N/D, ELO max), historique récent, bouton Défier |
| 15 | **Historique** | Liste des parties (vs qui, résultat, date), tap → replay |
| 16 | **Replay** | Boutons ⏮ ⏪ ⏯ ⏩ ⏭ pour rejouer coup par coup |

---

## 👥 Social — 3 écrans

| # | Écran | Contenu |
|---|---|---|
| 17 | **Amis** | Liste avec statut online/offline, demandes en attente |
| 18 | **Recherche utilisateur** | Par username, voir profil, ajouter en ami / défier |
| 19 | **Notifications** | Défi reçu, votre tour (correspondance), ami en ligne |

---

## ⚙️ Pratique — 3 écrans

| # | Écran | Contenu |
|---|---|---|
| 20 | **Réglages** | Sons (toggle), notifications push, déconnexion |
| 21 | **Règles** | Explications + GIFs (réutilisés de l'onboarding) |
| 22 | **À propos** | Version, contact, mentions légales |

---

## 🏆 V2 — pas avant le lancement MVP

- **Leaderboard** (global, hebdo, Sénégal)
- **Puzzles** (« trouve la chaîne », « gagne en 2 coups »)
- **Daily challenge**
- **Parties par correspondance** (multi-jours, push notifs)
- **Customisation plateau** (bois, drapeau Sénégal, etc.)
- **Tournois**
- **Anglais** (i18n)
- **Upload photo de profil**

---

## Navigation principale (post-auth)

Bottom tab bar (mobile) / sidebar (web) :

```
🏠 Accueil  |  ▶️ Jouer  |  👥 Amis  |  👤 Profil  |  ⚙️ Réglages
```

Notifications accessibles depuis l'icône cloche dans le header de chaque écran.
