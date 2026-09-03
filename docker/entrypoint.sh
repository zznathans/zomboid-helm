#!/usr/bin/env bash
set -euo pipefail

STEAMCMD_DIR="${STEAMCMD_DIR:-/opt/steamcmd}"
PZSERVER_DIR="${PZSERVER_DIR:-/opt/pzserver}"

SERVER_NAME="${SERVER_NAME:-servertest}"
# The server writes save/config data to ~/Zomboid, resolved from the
# container user's passwd home dir (/data, set at image build time) --
# not from $HOME. This is just used below for the RCON ini patch.
CACHE_DIR="${CACHE_DIR:-/data}"
UPDATE_ON_START="${UPDATE_ON_START:-true}"

mkdir -p "$CACHE_DIR"

if [ "$UPDATE_ON_START" = "true" ]; then
  echo "[entrypoint] Checking for Project Zomboid dedicated server updates..."
  "$STEAMCMD_DIR/steamcmd.sh" \
    +force_install_dir "$PZSERVER_DIR" \
    +login anonymous \
    +app_update 380870 validate \
    +quit
fi

if [ -z "${ADMIN_PASSWORD:-}" ]; then
  echo "[entrypoint] WARNING: ADMIN_PASSWORD is not set. No default admin account will be preconfigured." >&2
fi

INI_PATH="$CACHE_DIR/Zomboid/Server/${SERVER_NAME}.ini"
if [ -n "${RCON_PASSWORD:-}" ] && [ -f "$INI_PATH" ]; then
  echo "[entrypoint] Applying RCON_PASSWORD to $INI_PATH"
  sed -i "s/^RCONPassword=.*/RCONPassword=${RCON_PASSWORD}/" "$INI_PATH"
fi

cd "$PZSERVER_DIR"

ARGS=(-servername "$SERVER_NAME")
if [ -n "${ADMIN_PASSWORD:-}" ]; then
  ARGS+=(-adminpassword "$ADMIN_PASSWORD")
fi
if [ -n "${EXTRA_ARGS:-}" ]; then
  # shellcheck disable=SC2206
  ARGS+=($EXTRA_ARGS)
fi

echo "[entrypoint] Starting: ./start-server.sh ${ARGS[*]}"
exec ./start-server.sh "${ARGS[@]}"
