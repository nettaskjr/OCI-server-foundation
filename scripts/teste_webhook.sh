#!/bin/bash

# Carrega o .env localizado na mesma pasta do script
source "$(dirname "$0")/.env"

echo "Enviando mensagem de teste para o Discord..."

curl -H "Content-Type: application/json" \
     -X POST \
     -d '{"content": "🔔 **Alerta de Teste:** O webhook do Discord está funcionando perfeitamente!"}' \
     $DISCORD_WEBHOOK_URL

echo -e "\nFeito!"