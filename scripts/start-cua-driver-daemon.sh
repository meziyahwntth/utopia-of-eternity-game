#!/usr/bin/env bash
# Start cua-driver daemon (required before Cursor MCP can drive macOS GUI).
# Uses CuaDriver.app for correct TCC context on macOS.
set -euo pipefail

if cua-driver status 2>/dev/null | grep -q "running"; then
  cua-driver status
  exit 0
fi

cua-driver serve
sleep 1
cua-driver status
