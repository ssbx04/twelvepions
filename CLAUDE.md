# 12 Pions — Contexte projet (chargé auto à chaque session)

> Ce fichier est lu automatiquement au démarrage de Claude Code dans ce
> répertoire. Il regroupe la vision, l'architecture, l'état d'avancement,
> les décisions techniques, les pages de wireframes et les prochaines étapes
> de manière à ce qu'une nouvelle session reprenne exactement où on s'était arrêtés.

## Vision

**12 Pions** = la version sénégalaise du jeu de dames (plateau 5×5, 12 pions
par camp). Objectif ambitieux : **« chess.com pour 12 Pions »** — pas un truc
entre potes, mais une plateforme jouée par tous les Sénégalais.

- Jouable solo contre **Mariama** (IA), à deux sur le même appareil, ou en
  ligne avec n'importe qui (matchmaking par ELO).
- Cross-plateforme : **mobile** (Flutter, focus actuel), **web** (SvelteKit, à venir).
- Backend solide : **Spring Boot 4 + Kotlin**, autoritaire pour les parties online.
- Auth par **OTP SMS** sur numéro `+221`.

Branding : nom du produit = **12 Pions**, IA = **Mariama**, palette = drapeau
Sénégal (`#00853F` vert, `#FDEF42` jaune, `#E31B23` rouge).

Site live legacy : <https://one2pions-sn.onrender.com/>
Repo legacy : <https://github.com/sadibou-r/12pions-sn>

## Les deux dossiers à connaître

```
~/12pions_sn/    # LEGACY (single-file index.html, JS+HTML+CSS, ~2000 lignes)
                 # → toujours en prod sur Render, sert de référence fonctionnelle
                 # → contient les 6 sons MP3 (sounds/), le logo et les règles
                 # → sera abandonné quand le monorepo sera lancé

~/12pions/       # NOUVEAU MONOREPO (cible, en cours)
```

**Toujours travailler dans `~/12pions/`.** Le legacy n'est touché que pour
récupérer des assets (sons, etc.).

## Stack & architecture

| Couche | Choix | Raison |
|---|---|---|
| Backend | **Spring Boot 4.0.6** + **Kotlin 2.2.21** + Java 21 + Gradle Kotlin DSL | L'utilisateur connaît Spring, vibe coding implique qu'il puisse relire / debug |
| DB | PostgreSQL 16 + **Flyway** | Migrations versionnées |
| Cache / Pub-Sub | Redis 7 | OTP storage, matchmaking, futur pub-sub multi-instance |
| Auth | JWT HS256 (jjwt 0.12.6), 7 jours, OTP SMS | Console en dev, Africa's Talking ou Orange API en prod |
| WS | Spring `ws` natif (pas STOMP) | Plus simple, contrôle total sur le protocole |
| Mobile | **Flutter 3.41 / Dart 3.11** | L'utilisateur connaît Flutter |
| Web | SvelteKit + TypeScript | Léger, à brancher plus tard |
| State mgmt mobile | **flutter_bloc 9.x** | L'utilisateur connaît BLoC |
| DI mobile | **get_it 8.x** (sans injectable) | Pas de codegen, simple |
| HTTP mobile | **dio 5.x** | Interceptors propres pour JWT |
| Functional | **dartz 0.10** | `Either<Failure, T>` standard pour les repositories |
| Hosting cible | Free tier (Render existant), puis Oracle Cloud Free Tier (4 cores ARM) | Budget 0€ pour l'instant |

## Structure du monorepo

```
12pions/
├── backend/                 # Spring Boot 3 + Kotlin
│   ├── build.gradle.kts     # Spring Boot 4.0.6, Kotlin 2.2.21, JVM target 21
│   └── src/main/kotlin/sn/twelvepions/
│       ├── BackendApplication.kt
│       ├── HealthController.kt        # GET /health
│       ├── auth/                      # User, UserLevel, OtpService, AuthService,
│       │                              # AuthController, MeController, exceptions
│       ├── security/                  # JwtService, JwtAuthFilter, SecurityConfig
│       ├── game/                      # Types, Board, Rules (règles pures), entités JPA,
│       │   ├── ai/                    # Mariama, Evaluator, TranspositionTable, Difficulty
│       │   ├── EloService             # formule ELO standard K=32
│       │   ├── GameService            # createGame, applyMove (+faulty), resign,
│       │   │                          # acceptDraw, timeoutCurrentTurn, applyOopsRemoval,
│       │   │                          # findActiveGameOf
│       │   └── MatchmakingService     # queue Redis FIFO + lock JVM
│       ├── ws/                        # WsConfig, JwtHandshakeInterceptor, SessionRegistry,
│       │                              # GameWebSocketHandler, TurnTimer, ReconnectGuard,
│       │                              # DrawOfferRegistry, OopsRegistry
│       └── config/OpenApiConfig.kt    # Swagger /swagger-ui
│
├── mobile/                  # Flutter (Android/iOS)
│   ├── pubspec.yaml         # bloc, get_it, dio, dartz, go_router, flutter_svg, etc.
│   ├── run.sh               # détecte IP locale, lance flutter avec --dart-define=API_URL
│   ├── assets/
│   │   ├── icons/           # @.png, fullname.png, success.png, final_check.png
│   │   ├── images/          # pion_green.png, pion_rouge.png
│   │   └── logos/           # logo.svg ("12 PIONS" multicolore)
│   └── lib/
│       ├── main.dart
│       ├── app.dart
│       ├── core/
│       │   ├── constants/   # AppColors, AppDimensions, AppTextStyles, ApiEndpoints
│       │   ├── di/          # service_locator.dart (GetIt)
│       │   ├── errors/      # failures.dart, exceptions.dart
│       │   ├── network/     # (vide pour l'instant)
│       │   ├── router/      # app_router.dart (go_router)
│       │   ├── storage/     # auth_local_storage.dart (FlutterSecureStorage)
│       │   ├── theme/       # app_theme.dart
│       │   └── widgets/     # AppBackground, BlurEllipse, PrimaryButton
│       └── features/
│           ├── splash/      # SplashPage avec bootstrap session
│           └── auth/
│               ├── data/    # UserModel, AuthSessionModel, RemoteDataSource, RepositoryImpl
│               ├── domain/  # entités, repository abstract, 4 use cases
│               └── presentation/
│                   ├── blocs/{phone,otp,complete_profile}/
│                   ├── pages/{splash,phone,otp,complete_profile}_page.dart
│                   └── widgets/{phone_input,otp_input,labeled_text_field,
│                                level_selector,avatar_initials}.dart
│
├── web/                     # SvelteKit (skeleton, à implémenter plus tard)
├── shared/                  # Spec canonique des règles + corpus de tests partagé
│   ├── rules-spec.md
│   └── test-corpus.json
├── screens/                 # Designs Figma exportés (PNG/JPG)
│   ├── SplashScreen.jpg
│   ├── GetOtpByPhoneScreen.jpg
│   ├── VerifyNumberScreen.jpg
│   └── CompleteProfile.jpg
├── docs/screens.md          # Liste des 22 écrans MVP + décisions UX
├── docker-compose.yml       # Postgres :5435 + Redis :6379
├── run.sh                   # lance docker compose + backend + web SvelteKit
└── README.md
```

## Phases — État d'avancement

| Phase | Contenu | Statut |
|---|---|---|
| **0** | Setup : monorepo, Hetzner (skipped, dev local), CI, Docker Compose, run.sh | ✅ Commit `f0be27c` |
| **1** | Règles du jeu en Kotlin + tests Vitest-style (JUnit5) | ✅ Commit `7004afa` (35 tests) |
| **2** | Auth OTP : migration Flyway, JPA, OtpService, JwtService, controllers | ✅ Commit `497629b` |
| **3** | Mariama (IA Kotlin) + Swagger | ✅ Commit `cc7cd2a` (8 tests AI, 43 total) |
| **4** | Multijoueur online : games + game_moves, EloService, MatchmakingService, WebSocket | ✅ Commit `dd28f50` |
| **4.5** | Timer 30s/tour, reconnexion WS (avec suspend du timer), draw offer (3 refus = forfait), surplace OOPS | ✅ (51 tests, à commit) |
| **Mobile auth** | Flutter Clean Architecture, splash + phone + OTP + complete profile branchés au backend | ✅ Validé end-to-end sur device |
| **Mobile /home** | Page d'accueil/lobby avec données réelles, bouton de déconnexion et OTP Push Local | ✅ Terminé |
| **Web SvelteKit** | Reprendre le frontend web | ⏭ Plus tard |
| **F** | Tournois, leaderboard, friends, etc. | ⏭ V2 |

## État courant détaillé (mobile auth)

### Flow d'authentification (4 écrans + bootstrap)

1. **Splash** (`splash_page.dart`) :
   - Affiche le design (gradient sombre + 2 pions blurrés diagonaux + logo SVG centré)
   - Min 2s d'affichage
   - **Bootstrap session** : `AuthRepository.hasSession()` → si JWT existe :
     - `getMe()` → si OK + `profileComplete` → `/home`, sinon → `/complete-profile`
     - Si `UnauthorizedFailure` → `logout()` + `/phone`
     - Si network error → trust local `profileComplete` flag (offline-first)
   - Si pas de JWT → `/phone`

2. **Phone** (`phone_page.dart`) :
   - Champ téléphone avec préfixe `🇸🇳 +221`, auto-format `XX XXX XX XX`
   - Bouton "CONTINUER" disabled tant que != 9 chiffres
   - `PhoneBloc.add(PhoneSubmitted)` → `POST /auth/phone` → si succès, navigate `/otp` avec `+221XXXXXXXXX` en `extra`
   - Erreurs (cooldown, rate limit) → SnackBar rouge

3. **OTP** (`otp_page.dart`) :
   - 6 cases auto-advance, paste support, backspace recule
   - Sous-titre affiche le téléphone reformaté `+221 XX XXX XX XX` en jaune gras
   - Resend timer 30s puis bouton actif
   - Bouton "VÉRIFIER" → `OtpBloc.add(OtpVerifySubmitted)` → `POST /auth/verify-otp`
   - Sur `OtpVerified(session)` : `profileComplete` → `/home`, sinon → `/complete-profile`
   - Resend → `POST /auth/phone` à nouveau, SnackBar verte "Nouveau code envoyé"
   - Le repository `verifyOtp` **persiste auto le JWT** en secure storage

4. **CompleteProfile** (`complete_profile_page.dart`) :
   - Avatar généré : initiales calculées du nom complet (cercle jaune, texte noir)
   - Champ nom complet (icône `fullname.png`, capitalisation auto)
   - Champ username (icône `@.png`, regex `^[a-z0-9_]{3,20}$`, **check disponibilité live debouncé 500ms**)
   - 4 pills niveau (Débutant 1000 / Intermédiaire 1200 / Avancé 1400 / Expert 1600)
   - Bouton "COMMENCER À JOUER" + icône `final_check.png`
   - `CompleteProfileBloc.add(ProfileSubmitted)` → `POST /auth/complete-profile` → `/home`

### BLoCs créés

- `PhoneBloc` (events: `PhoneSubmitted`, `PhoneReset`)
- `OtpBloc` (events: `OtpVerifySubmitted`, `OtpResendSubmitted`)
- `CompleteProfileBloc` (events: `UsernameCheckRequested`, `UsernameCleared`, `ProfileSubmitted` — state avec `UsernameStatus` + `SubmitStatus` enums + `copyWith`)

### Use cases (domain)

- `SendOtp` → `Either<Failure, Unit>`
- `VerifyOtp({phone, code})` → `Either<Failure, AuthSession>`
- `CompleteProfile({fullName, username, level})` → `Either<Failure, AuthSession>`
- `CheckUsername(username)` → `Either<Failure, bool>`

### Routes (`app_router.dart`)

```
/                  → SplashPage
/phone             → PhonePage
/otp               → OtpPage(phone via extra)
/complete-profile  → CompleteProfilePage
/home              → _HomePlaceholder (à implémenter)
```

## Endpoints backend disponibles

### Public

| Méthode | Path | Body / Params | Résultat |
|---|---|---|---|
| GET  | `/health` | — | `{status, service, timestamp}` |
| POST | `/auth/phone` | `{phone: "+221XXXXXXXXX"}` | `200` (OTP loggé console) |
| POST | `/auth/verify-otp` | `{phone, code}` | `{token, profileComplete, user}` |
| GET  | `/auth/check-username?u=...` | — | `{available: bool}` |
| POST | `/ai/move` | `{board, color, difficulty}` | `{sequence, score, depth}` |
| —    | `/swagger-ui/index.html` | — | UI Swagger |

### Authentifié (Bearer JWT)

| Méthode | Path | Body | Résultat |
|---|---|---|---|
| GET  | `/me` | — | `UserDto` |
| POST | `/auth/complete-profile` | `{fullName, username, level}` | `{token, profileComplete, user}` |
| WS   | `/ws?token=<jwt>` | (handshake JWT par query) | bidirectionnel |

### Protocole WebSocket

```
client → server :  queue.join | queue.leave | game.move | game.resign | ping
server → client :  connected | queue.queued | queue.left | game.matched
                   | game.resume | game.update | game.ended
                   | game.draw.offered | game.draw.declined
                   | opponent.disconnected | opponent.reconnected
                   | error | pong
client → server :  + game.draw.offer | game.draw.respond | game.oops.claim
```

### Règles temps & gestion partie (Phase 4.5)

- **Timer 30s/tour serveur** (`TurnTimer`) : à expiration → forfait du joueur dont c'est le tour
  (`endReason = TIMEOUT`). Chaque message `game.matched` / `game.update` / `game.resume`
  porte `turnDeadlineEpochMs`.
- **Reconnexion WS** (`ReconnectGuard`) : si un joueur dropper, on garde son slot 30 s
  (`opponent.disconnected` envoyé à l'adversaire avec `forfeitDeadlineEpochMs`).
  Pendant ce temps le `TurnTimer` est **suspendu** (resume avec le temps restant à
  la reconnexion). À expiration → `gameService.resign(userId)`. À la reconnexion :
  message `game.resume { state, yourColor, turnDeadlineEpochMs }` au revenant +
  `opponent.reconnected` à l'autre.
- **Draw offer** (`DrawOfferRegistry`) : `game.draw.offer` → `game.draw.offered` à
  l'adversaire. Réponse `game.draw.respond { accept }` :
  - accept → `acceptDraw` (`endReason = DRAW_AGREED`, ELO appliqué).
  - decline → `game.draw.declined { offererId, refusalsByOfferer, max }`.
  - **3 refus du même demandeur** dans la partie → forfait du demandeur.
  - Jouer un coup annule implicitement le pending **sans** compter comme refus.
- **Surplace OOPS online** (`OopsRegistry`) : `applyMove` valide désormais contre
  `Rules.enumerateAllLegalTurns` (autorise coup simple ou chaîne incomplète même
  si capture dispo). Si fautif, le bloc `oops: { claimableBy, faultyPositions }`
  est joint à `game.update`. L'adversaire peut envoyer `game.oops.claim
  { gameId, position }` (validation : position ∈ faultyPositions). Le pion est
  retiré, le tour ne change pas, le `TurnTimer` est rearmé. Jouer son coup sans
  réclamer = OOPS auto-clear.
- Tous ces composants sont **in-memory** (perdus au redémarrage backend) ;
  acceptable pour MVP, à reprendre quand on passera multi-instance.

## Règles du 12 Pions (résumé — détail dans `shared/rules-spec.md`)

- 5×5, 12 pions/camp ; X (Vert) en haut commence, O (Rouge) en bas.
- **Pion** : 3 directions (avant + côtés), jamais en arrière.
- **Dame** : 4 directions orthogonales (pas de diagonale), n'importe quelle distance.
- **Capture obligatoire** ; chaîne forcée (Coudou) ; promotion en dame en arrivant
  rangée adverse (auto pendant chaîne).
- **Surplace (OOPS)** : si un joueur joue un coup simple alors qu'une capture
  était dispo, l'**adversaire** peut retirer un pion fautif (jamais forcé).
- **Promotion solo** : si un joueur n'a plus qu'un pion non-dame → auto-promu en dame.
- **Match nul automatique 1 vs 1** : dès que les deux camps n'ont qu'1 pièce.
- Match nul mutuel : 3 demandes refusées = forfait du demandeur.
- Timing : 30 s/tour, 3 s entre captures dans une chaîne.

## Décisions techniques importantes

### Backend

- **Spring Boot 4 + Jackson 3** : import `tools.jackson.databind.ObjectMapper`
  (pas `com.fasterxml.jackson...`) — c'est le namespace Jackson 3 utilisé par SB4.
- **JsonNode.asText()** est déprécié → utiliser `asString()`.
- **`JsonNode.map { … }`** ne compile pas en Kotlin avec Jackson 3 → itérer
  manuellement avec `for (m in node) { … }`.
- **JVM target Kotlin = 21** : configuré dans `build.gradle.kts` avec
  `jvmTarget.set(JvmTarget.JVM_21)` + `jvmToolchain(21)`.
- **CHAR vs VARCHAR Postgres** : Hibernate refuse `CHAR(N)` (= `bpchar`)
  pour un `String` Kotlin. Toujours utiliser `VARCHAR(N)` dans les migrations.
- **Pour reset la DB** en dev quand un checksum Flyway change : `docker compose down -v`
  (avec le `-v` pour effacer les volumes), pas juste `down`.
- **Mariama** (IA) : alpha-beta + iterative deepening + transposition table,
  4 niveaux dont **EXPERT** avec budget 3,5 s. Hash plateau = string 26 chars
  (25 cases + couleur).

### Mobile

- **Clean Architecture stricte** : `data` (models, datasources, repos) →
  `domain` (entities, repos abstract, use cases) → `presentation` (blocs, pages, widgets).
- Les datasources lèvent `NetworkException` / `ServerException(code, message)`.
  Le repository convertit en `Failure` métier (`OtpCooldownFailure`,
  `UsernameTakenFailure`, etc.) et retourne `Either<Failure, T>`.
- **Pas de freezed**, juste `Equatable` pour value equality (le user n'a pas
  demandé freezed et codegen ralentit le vibe coding).
- **`String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080')`**
  pour rendre l'URL configurable au build via `--dart-define`.
- **`mobile/run.sh`** détecte automatiquement l'IP locale via
  `ip route get 1.1.1.1` et lance `flutter run --dart-define=API_URL=...`.
  Utilisé pour le **debug wireless** (le user code en wireless ADB, pas USB).
- **`flutter_secure_storage`** pour le JWT : Keystore Android, Keychain iOS.
- **`google_fonts` (DM Sans)** au runtime, cache local après 1er load.

### UI / Design

- **Couleurs** : `#00853F` vert, `#FDEF42` jaune, `#E31B23` rouge (drapeau Sénégal).
- **Background gradient** : `#1A0F08` → `#2D1810`.
- **Police** : DM Sans via google_fonts.
- **Template `AppBackground`** : linear gradient + 2 ellipses radiales (vert + rouge,
  18% alpha) positionnables par page via `greenOffset` / `redOffset`.
- **Pions blurrés** : sur le splash, on utilise `ImageFiltered` avec
  `ImageFilter.blur(sigma: 12)` directement sur les images PNG (pas un halo séparé).
- **Avatar initiales** : "Cheikh Sadibou SONKO" → "CS" (première du premier mot
  + première du dernier mot).

### Auth flow détails

- **Format téléphone** : `+221XXXXXXXXX` strict (regex `^\+221\d{9}$`),
  affichage `+221 XX XXX XX XX`.
- **Format username** : `[a-z0-9_]{3,20}`, lowercase forcé, debouncé 500ms côté UI.
- **OTP** : 6 chiffres, TTL 5 min, cooldown 30 s, max 5/h, max 3 essais par code.
  Stocké en Redis (hash `otp:code:{phone}` + `otp:cooldown:{phone}` + compteur horaire).
  En dev, **imprimé dans le terminal backend** dans une boîte ASCII.
- **JWT** : 7 jours, claims `sub` (UUID user) + `profileComplete`.
- **Niveaux et seed ELO** : Débutant=1000, Intermédiaire=1200, Avancé=1400, Expert=1600.

## Pour lancer le dev en local

### Backend + Postgres + Redis + web SvelteKit

```bash
cd ~/12pions
./run.sh                     # docker compose + backend Gradle + web Vite
./run.sh stop                # arrête les containers Docker
```

URLs :
- Backend : http://localhost:8080
- Swagger : http://localhost:8080/swagger-ui/index.html
- Web : http://localhost:5173 (ou 5174 si port pris)
- Postgres : localhost:**5435** (db `twelvepions`, user `twelvepions`, pwd `dev_only_change_in_prod`)
- Redis : localhost:6379

### Mobile (wireless debug)

```bash
# 1. Backend doit tourner (./run.sh dans ~/12pions)
# 2. Téléphone connecté en wireless ADB et sur le même WiFi
adb connect <IP_DU_PHONE>:5555
adb devices

cd ~/12pions/mobile
./run.sh                     # détecte IP locale, lance flutter run avec --dart-define
```

Le script échoue gentiment si le backend n'est pas joignable (vérifie via
`/health`). Si curl `http://192.168.X.Y:8080/health` ne répond pas depuis la
machine de dev, c'est ufw qui bloque : `sudo ufw allow 8080/tcp`.

### Tests backend

```bash
cd ~/12pions/backend
./gradlew test               # 51 tests (43 Rules + 8 Mariama)
./gradlew bootRun            # juste démarrer le backend sans Docker pour les containers
```

## Frustrations passées / règles de collaboration

L'utilisateur **vibe code** avec moi. Il est exigeant sur le respect de ses
décisions et perçoit comme négatif le fait que je modifie des choses sans demander :

- **Ne jamais modifier la mécanique du jeu sans accord explicite.** Au début
  de la session, j'avais ajouté un système surplace forcé qui ne lui plaisait
  pas et il l'a vécu comme une atteinte à ses règles. Toujours **demander
  avant** de toucher à quoi que ce soit qui touche au gameplay ou à des
  comportements UX déjà validés.
- **Ne pas spammer du code sans valider.** Préférer poser une question
  rapide quand une décision a un impact (ex: "Tu veux paramétrique ou
  variants présets ?") plutôt que d'écrire 500 lignes qu'il faut ensuite
  débricoler.
- **Tokens limités** : éviter de tout réécrire pour un petit changement,
  faire des `Edit` ciblés.
- **Pas de freezed**, **pas d'injectable codegen** (juste get_it pur).
  L'utilisateur n'aime pas la couche codegen quand on peut faire sans.
- **Pas de tests à tout prix** côté mobile pour l'instant, on valide
  visuellement sur le device.
- L'utilisateur passe en revue chaque écran avec un screenshot de son
  device, on itère jusqu'à ce que ça matche le Figma.

### Patterns d'interaction qui marchent

- Demander 1-3 détails de design (couleurs, positions, comportements)
  AVANT de coder.
- Quand l'utilisateur dit "perfect next step", il veut **enchaîner**
  (sans débriefing).
- Ne pas mentionner les system-reminders ou la date dans les réponses.
- Réponses courtes, structurées, en français, avec rappels concrets
  des commandes à lancer.

## Designs Figma & assets

Les 4 designs auth sont dans `~/12pions/screens/` :
- `SplashScreen.jpg` (pions blurrés diagonaux + logo)
- `GetOtpByPhoneScreen.jpg` (input téléphone avec préfixe drapeau)
- `VerifyNumberScreen.jpg` (6 cases OTP + timer renvoi)
- `CompleteProfile.jpg` (avatar initiales + 2 inputs + level selector)

Assets dans `~/12pions/mobile/assets/` :
- `images/pion_green.png`, `images/pion_rouge.png` (pions 3D générés ChatGPT)
- `logos/logo.svg` (texte multicolore "12 PIONS" avec étoile sénégalaise)
- `icons/fullname.png`, `icons/@.png`, `icons/success.png`, `icons/final_check.png`

Les 22 écrans complets (MVP + V2) sont catalogués dans `~/12pions/docs/screens.md`.

## Gotchas & pièges connus

- **`docker compose down`** sans `-v` ne supprime pas la DB → si tu
  modifies une migration Flyway déjà appliquée, tu dois faire `down -v`
  sinon tu auras un checksum mismatch au démarrage.
- **Mariama avec X en bas** : le moteur attend X en haut (forward `+r`).
  Si on lui passe un plateau inversé, il jouera mais avec un score
  négatif (X bloqué). C'est le client qui flippe seulement l'**affichage**.
- **`adb reverse`** ne marche **pas** en wireless ADB → utiliser
  `mobile/run.sh` qui injecte l'IP locale via `--dart-define`.
- **Spring Security default password** : un UUID est généré au démarrage
  et imprimé en console. C'est juste du bruit, ignorer (notre auth via
  JWT remplace ça).
- **HikariPool startup error sur démarrage backend** : si Postgres pas prêt
  encore, le backend retry. Le script `run.sh` attend que les containers
  soient `healthy` avant de lancer le backend.
- **Spring Boot 4** est sorti récemment (en 2026). Beaucoup de tutos
  internet sont encore pour 3.x → bien vérifier les imports Jackson
  (`tools.jackson...`) et les API qui ont bougé.
- **Connexion ADB wireless** : si elle se perd, refaire `adb connect IP:5555`,
  puis relancer le `flutter run` (pas besoin de relancer `run.sh` du backend).

## Prochaines étapes précises

### Immédiat — page `/home` (lobby)

Actuellement `/home` est en cours d'implémentation.
Il faut :

1. Créer le `Scaffold` avec la `BottomNavigationBar` (5 onglets : Accueil, Jouer, Amis, Profil, Réglages).
2. Implémenter le contenu de l'onglet Accueil : 
   - Bouton géant "JOUER MAINTENANT"
   - Carte "Affronter Mariama"
   - Historique "Dernière partie"
   - Liste des amis en ligne
3. Brancher un `HomeBloc` (ou utiliser `AuthBloc`) pour récupérer l'ELO du joueur via `GET /me`.

### Phase 4.5 — fait

Tous les chantiers livrés (51 tests verts) :
- **Timer 30s/tour** serveur (`TurnTimer`, `EndReason.TIMEOUT`)
- **Reconnexion WS** (`ReconnectGuard`, suspend/resume du `TurnTimer`)
- **Draw offer** (`DrawOfferRegistry`, 3 refus = forfait, `EndReason.DRAW_AGREED`)
- **Surplace OOPS online** (`OopsRegistry`, `Rules.faultyPositions`,
  `Rules.enumerateAllLegalTurns`, `GameService.applyOopsRemoval`)

À reprendre plus tard pour scale : remplacer les composants in-memory
par du Redis pub/sub multi-instance (timer, reconnect, draw, oops).

### Encore plus tard — Web SvelteKit

Le scaffold est dans `web/`. Il faut implémenter le frontend web avec les
mêmes flows que le mobile (mais plus tard, mobile en priorité).

## Commandes utiles (cheatsheet)

```bash
# Monorepo
cd ~/12pions
./run.sh                            # tout démarrer (Docker + backend + web)
./run.sh stop                       # arrêter les containers Docker

# Backend
cd ~/12pions/backend
./gradlew bootRun                   # backend seul (Postgres et Redis doivent tourner)
./gradlew test                      # 51 tests (Rules + Mariama)
./gradlew compileKotlin             # juste compiler

# Mobile
cd ~/12pions/mobile
flutter pub get                     # install deps
./run.sh                            # debug wireless avec --dart-define auto
flutter analyze                     # linter Dart
adb connect 192.168.X.Y:5555        # se reconnecter en wireless
adb devices                         # vérifier les devices connectés

# Reset DB en dev (perd les données)
cd ~/12pions
docker compose down -v
./run.sh

# Tester un endpoint backend en CLI
curl http://localhost:8080/health
curl -X POST -H "Content-Type: application/json" \
  -d '{"phone":"+221785384455"}' \
  http://localhost:8080/auth/phone
# → regarder le terminal backend pour voir le code OTP imprimé

# Si firewall bloque le mobile
sudo ufw allow 8080/tcp
```

## Conventions de code

- **Pas de commentaires inutiles** : ne commenter que le *pourquoi* non-évident,
  jamais le *quoi*.
- **Kotlin** : suivre les conventions du linter (constructeurs primaires,
  `data class` pour les value types, `object` pour les singletons).
- **Dart** : `final` pour tout ce qui n'est pas muté, `const` pour les
  widgets sans state, prefer relative imports en Dart (pas de `package:` interne).
- **Flutter** : Material 3 (`useMaterial3: true`), DM Sans via google_fonts.
- **Tests Kotlin** : `@Test fun \`nom de test en backticks\`()`, JUnit 5 +
  `kotlin.test.*` (pas Kotest pour pas ajouter de dep).
- **JSON API** : camelCase partout (Jackson Kotlin module + Dart standard).
- **TS strict** côté shared/web (avec `noUncheckedIndexedAccess`).
