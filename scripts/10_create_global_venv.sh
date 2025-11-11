#!/usr/bin/env bash
set -euo pipefail

VENV_DIR=${VENV_DIR:-/opt/.venvs/MECH_LAB}
PYTHON_BIN=${PYTHON_BIN:-python3}

echo "[1/5] Installiere Systempakete"
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ${PYTHON_BIN} ${PYTHON_BIN}-venv ${PYTHON_BIN}-dev \
  build-essential git acl i2c-tools

# I2C non-interaktiv aktivieren, falls verfügbar (ignoriert Fehler, wenn schon aktiv)
if command -v raspi-config >/dev/null 2>&1; then
  raspi-config nonint do_i2c 0 || true
fi

echo "[2/5] Erstelle globale venv unter ${VENV_DIR} (falls nicht vorhanden)"
if [[ ! -d "${VENV_DIR}" ]]; then
  ${PYTHON_BIN} -m venv "${VENV_DIR}"
fi

# Grundtools
"${VENV_DIR}/bin/pip" install --upgrade pip wheel setuptools

echo "[3/5] Rechte setzen: lesbar/ausführbar für alle, schreibbar nur root"
chown -R root:root "${VENV_DIR}"
find "${VENV_DIR}" -type d -exec chmod 755 {} +
find "${VENV_DIR}" -type f -exec chmod 644 {} +
chmod 755 "${VENV_DIR}/bin"/*

# Für künftige Kompatibilität: ipykernel optional bereitstellen
"${VENV_DIR}/bin/pip" install --upgrade ipykernel || true

echo "[4/5] Python-Version: $("${VENV_DIR}/bin/python" --version)"

echo "[5/5] Fertig."
