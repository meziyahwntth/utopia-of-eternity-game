#!/usr/bin/env bash
# Create gitignored BridgeSecrets.luau + PlaceSecrets.luau + CatalogSecrets.luau from examples
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$ROOT/src/ServerScriptService/Secrets"
for f in BridgeSecrets PlaceSecrets CatalogSecrets; do
  if [[ ! -f "$SECRETS/${f}.luau" ]]; then
    cp "$SECRETS/${f}.example.luau" "$SECRETS/${f}.luau"
    echo "Created $SECRETS/${f}.luau"
  else
    echo "Exists: $SECRETS/${f}.luau"
  fi
done
