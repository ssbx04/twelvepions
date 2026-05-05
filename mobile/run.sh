#!/usr/bin/env bash
# Lance Flutter en injectant l'IP locale dans l'URL du backend.
# Utilise pour le debug wireless : phone et machine dev sur le même WiFi.
#
# Usage : ./run.sh [args flutter]
#   ./run.sh                       # build debug, hot reload actif
#   ./run.sh --release             # build release
#   ./run.sh -d <device-id>        # cible un device précis

set -euo pipefail

# Détecte l'IP locale (interface utilisée pour sortir vers internet)
HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)

if [[ -z "${HOST_IP:-}" ]]; then
  # Fallback : première IP non-loopback
  HOST_IP=$(hostname -I | awk '{print $1}')
fi

if [[ -z "${HOST_IP:-}" ]]; then
  echo "❌ Impossible de détecter l'IP locale. Connecté au WiFi ?"
  exit 1
fi

API_URL="http://${HOST_IP}:8080"
WS_URL="ws://${HOST_IP}:8080/ws"

echo "📡 IP locale : ${HOST_IP}"
echo "   API : ${API_URL}"
echo "   WS  : ${WS_URL}"
echo

# Vérifie que le backend répond
if ! curl -fsS -o /dev/null -m 2 "${API_URL}/health" 2>/dev/null; then
  echo "⚠️  Backend non joignable sur ${API_URL}"
  echo "   Lance d'abord : cd ~/12pions && ./run.sh"
  echo "   (Continuer quand même ? Ctrl-C pour annuler, Entrée pour continuer)"
  read -r
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

exec flutter run \
  --dart-define=API_URL="${API_URL}" \
  --dart-define=WS_URL="${WS_URL}" \
  "$@"
