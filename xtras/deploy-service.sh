#!/bin/bash
set -euo pipefail

SERVICE="${1:?Uso: $0 <nome-do-servico>}"
XTRA_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$XTRA_DIR/$SERVICE"

if [ ! -d "$SRC" ]; then
  echo "Erro: pasta '$SERVICE' não encontrada em xtras/"
  echo "Pastas disponíveis:"
  ls -1 "$XTRA_DIR"
  exit 1
fi

if [ ! -f "$SRC/docker-compose.yml" ]; then
  echo "Erro: $SRC/docker-compose.yml não encontrado"
  exit 1
fi

BASE="/opt/server"
COMPOSE_DIR="$BASE/compose/$SERVICE"
DATA_DIR="$BASE/data/$SERVICE"
LOGS_DIR="$BASE/logs/$SERVICE"
APPS_DIR="$BASE/apps/$SERVICE"

echo "=== Deployando serviço: $SERVICE ==="

# Cria estrutura de diretórios
sudo mkdir -p "$COMPOSE_DIR" "$DATA_DIR" "$LOGS_DIR"

# Copia compose
sudo cp "$SRC/docker-compose.yml" "$COMPOSE_DIR/"

# Copia arquivos de config extras se existirem
if [ -d "$SRC/apps" ]; then
  sudo mkdir -p "$APPS_DIR"
  sudo cp -r "$SRC/apps/"* "$APPS_DIR/"
fi

# Ajusta permissões
sudo chown -R ubuntu:ubuntu "$BASE/compose" "$BASE/data" "$BASE/logs"
sudo chmod -R 755 "$BASE/compose" "$BASE/data" "$BASE/logs"

echo ""
echo "Estrutura criada:"
echo "  Compose:  $COMPOSE_DIR/docker-compose.yml"
echo "  Data:     $DATA_DIR/"
echo "  Logs:     $LOGS_DIR/"
echo ""
echo "Para subir o serviço:"
echo "  cd $COMPOSE_DIR && docker compose up -d"
