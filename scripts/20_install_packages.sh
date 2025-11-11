#!/usr/bin/env bash
# scripts/20_install_packages.sh
# Installiert benötigte Python-Pakete in der globalen venv und prüft sie robust.
set -euo pipefail

VENV_DIR=${VENV_DIR:-/opt/.venvs/MECH_LAB}
GROVE_REPO_BRANCH=${GROVE_REPO_BRANCH:-master}   # Branch deines Forks jonasjosi-hslu/grove.py

echo "[PKGS] Verwende venv: $VENV_DIR"
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  echo "[FEHLER] venv unter $VENV_DIR nicht gefunden. Bitte zuerst 10_create_global_venv.sh ausführen." >&2
  exit 1
fi

echo "[PKGS] Aktualisiere Pip-Tools"
"$VENV_DIR/bin/pip" install --upgrade pip wheel setuptools

echo "[PKGS] Installiere lgpio"
"$VENV_DIR/bin/pip" install lgpio

echo "[PKGS] Installiere matplotlib"
"$VENV_DIR/bin/pip" install matplotlib

echo "[PKGS] Installiere rpi-lgpio"
"$VENV_DIR/bin/pip" install rpi-lgpio

echo "[PKGS] Installiere spidev"
"$VENV_DIR/bin/pip" install spidev

echo "[PKGS] Installiere numpy"
"$VENV_DIR/bin/pip" install numpy

echo "[PKGS] Installiere gpiozero"
"$VENV_DIR/bin/pip" install gpiozero

# Schutz: Falls versehentlich ein fremdes 'importlib' Paket installiert wurde, entfernt es die Stdlib-Funktionalität.
# Das führt später u.a. zu 'AttributeError: module importlib has no attribute util'.
if "$VENV_DIR/bin/pip" show importlib >/dev/null 2>&1; then
  echo "[PKGS][WARN] Fremd-Paket 'importlib' in der venv gefunden. Entferne es, um Konflikte mit der Standardbibliothek zu vermeiden."
  "$VENV_DIR/bin/pip" uninstall -y importlib || true
fi

echo "[PKGS] Prüfe Installation durch Import-Tests"
"$VENV_DIR/bin/python" - <<'PY'
missing = []
for name in ("lgpio"):
    try:
        __import__(name)
    except Exception as e:
        missing.append(f"{name}: {e}")
if missing:
    print("FEHLEND/Problem:", ", ".join(missing))
    raise SystemExit(1)
else:
    print("Pakete OK")
PY

echo "[OK] Pakete erfolgreich installiert und geprüft."
