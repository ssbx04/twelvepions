#!/usr/bin/env bash
# Lance toute la stack 12 Pions en local : Postgres + Redis + backend + web.
# Usage : ./run.sh          → démarre tout
#         ./run.sh stop     → arrête les conteneurs Docker
#         Ctrl-C            → arrête backend + web (Docker reste up)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Couleurs pour les logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${BLUE}[run.sh]${NC} $1"; }
ok()   { echo -e "${GREEN}[run.sh]${NC} $1"; }
warn() { echo -e "${YELLOW}[run.sh]${NC} $1"; }
err()  { echo -e "${RED}[run.sh]${NC} $1" >&2; }

# Mode "stop" : arrête juste les conteneurs Docker
if [[ "${1:-}" == "stop" ]]; then
  log "Arrêt des conteneurs Docker…"
  docker compose down
  ok "Stoppé."
  exit 0
fi

# Vérifie les outils requis
for cmd in docker java pnpm; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "Outil manquant : $cmd"
    exit 1
  fi
done

# 1. Postgres + Redis
log "Démarrage de Postgres + Redis (Docker Compose)…"
docker compose up -d
log "Attente que les services soient healthy…"
for i in {1..30}; do
  pg_status=$(docker inspect -f '{{.State.Health.Status}}' 12pions-postgres 2>/dev/null || echo "starting")
  rd_status=$(docker inspect -f '{{.State.Health.Status}}' 12pions-redis 2>/dev/null || echo "starting")
  if [[ "$pg_status" == "healthy" && "$rd_status" == "healthy" ]]; then
    ok "Postgres + Redis prêts."
    break
  fi
  sleep 1
done

# 2. Web : install des deps si node_modules manquant
if [[ ! -d "$ROOT/web/node_modules" ]]; then
  log "Installation des dépendances web (premier lancement)…"
  (cd "$ROOT/web" && pnpm install)
fi

# 3. Backend (en arrière-plan)
log "Démarrage du backend Spring Boot…"
FCM_CREDS_PATH="$ROOT/twelvepions-firebase-adminsdk.json"
if [[ -f "$FCM_CREDS_PATH" ]]; then
  export FIREBASE_CREDENTIALS_JSON="$(cat "$FCM_CREDS_PATH")"
  ok "Firebase credentials chargées depuis $FCM_CREDS_PATH"
fi
(cd "$ROOT/backend" && ./gradlew --console=plain bootRun) &
BACKEND_PID=$!

# 4. Web (en arrière-plan)
log "Démarrage du web SvelteKit…"
(cd "$ROOT/web" && pnpm dev) &
WEB_PID=$!

# Cleanup propre sur Ctrl-C
cleanup() {
  echo
  warn "Arrêt en cours…"
  kill "$BACKEND_PID" "$WEB_PID" 2>/dev/null || true
  wait "$BACKEND_PID" "$WEB_PID" 2>/dev/null || true
  ok "Backend + web arrêtés. (Docker reste up — './run.sh stop' pour tout arrêter)"
  exit 0
}
trap cleanup INT TERM

ok "Tout est lancé."
echo
echo -e "  ${GREEN}Backend${NC}  : http://localhost:8080"
echo -e "  ${GREEN}Web${NC}      : http://localhost:5173"
echo -e "  ${GREEN}Postgres${NC} : localhost:5435 (db: twelvepions)"
echo -e "  ${GREEN}Redis${NC}    : localhost:6379"
echo
echo "Ctrl-C pour arrêter backend + web."

wait
