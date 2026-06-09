#!/bin/bash

source "$(dirname "$0")/.env"

curl -H "Authorization: Bearer $API_CLOUDFLARE_TOKEN" \
  "https://api.cloudflare.com/client/v4/user/tokens/verify"