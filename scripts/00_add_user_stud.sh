#!/usr/bin/env bash
set -euo pipefail

USER_NAME=${USER_NAME:-stud}
USER_PASS=${USER_PASS:-muffin2019}

if id -u "$USER_NAME" >/dev/null 2>&1; then
  echo "[INFO] Benutzer $USER_NAME existiert bereits – überspringe Anlage."
else
  echo "[1/3] Lege Benutzer $USER_NAME an"
  # /bin/bash als Shell, Home-Verzeichnis anlegen
  useradd -m -s /bin/bash "$USER_NAME"
  echo "$USER_NAME:$USER_PASS" | chpasswd
  # Optional: zu nützlichen Gruppen hinzufügen (sudo nur, wenn gewünscht)
  # usermod -aG sudo "$USER_NAME"
fi

# Gemeinsame Arbeitsgruppe für Projekte (optional, nützlich für gemeinsame Ordner)
if ! getent group labusers >/dev/null; then
  groupadd labusers
fi
usermod -aG labusers "$USER_NAME"

echo "[OK] Benutzer $USER_NAME fertig."
