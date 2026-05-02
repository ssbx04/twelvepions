# 12 Pions

> Le jeu de dames sénégalais — version moderne, multi-plateforme et en ligne.

## Vision

Une plateforme inspirée de chess.com, dédiée au **12 Pions sénégalais** :
- Jouable en solo contre **Mariama** (IA), à deux sur le même appareil, ou en ligne avec n'importe qui.
- Cross-plateforme : **web** (SvelteKit), **mobile** Android/iOS (Flutter).
- Backend solide en **Spring Boot 3 + Kotlin**, autoritaire pour les parties en ligne.
- Authentification par **OTP SMS** (numéro sénégalais `+221`).

## Architecture

```
12pions/
├── backend/         # Spring Boot 3 + Kotlin + Gradle (REST + WebSocket)
├── web/             # SvelteKit + TypeScript
├── mobile/          # Flutter (Android + iOS)
├── shared/          # Spec des règles + corpus de tests partagé
├── docs/            # Spec des écrans, design, décisions
└── docker-compose.yml  # Postgres + Redis pour le dev local
```

## Stack

| Couche | Choix |
|---|---|
| Backend | Spring Boot 3.x, Kotlin 2.x, Java 21, Gradle Kotlin DSL |
| DB | PostgreSQL 16 + Flyway (migrations) |
| Cache / Pub-Sub | Redis 7 |
| Auth | JWT, OTP SMS (terminal en dev → Africa's Talking en prod) |
| Web | SvelteKit, TypeScript, Vite |
| Mobile | Flutter 3.x, Dart 3.x |
| Hosting cible | Render (free) → Oracle Cloud Free Tier ou Hetzner |

## Démarrer en local

### Pré-requis

- Java 21 (`java --version`)
- Node 22 + pnpm (`pnpm --version`)
- Flutter 3.x (`flutter --version`)
- Docker + Docker Compose

### 1. Lancer Postgres + Redis

```bash
docker compose up -d
```

### 2. Backend

```bash
cd backend
./gradlew bootRun
```
Backend disponible sur `http://localhost:8080`.

### 3. Web

```bash
cd web
pnpm install
pnpm dev
```
Web disponible sur `http://localhost:5173`.

### 4. Mobile

```bash
cd mobile
flutter pub get
flutter run
```

## Documentation

- [`docs/screens.md`](docs/screens.md) — Liste et description des écrans
- *(à venir : `docs/rules.md`, `docs/api.md`, `docs/protocol.md`)*

## Phase actuelle

**Phase 0 — Setup ✅** : structure du monorepo, scaffolds, Docker Compose.

**Phase 1 (en cours)** : règles du jeu en Kotlin + corpus de tests partagé.

Voir le plan complet dans [`docs/screens.md`](docs/screens.md).
