#!/usr/bin/env bash
# scripts/45_mech_lab_reset_home_dir.sh
# Installiert/aktualisiert das Repo ChrHohmann/mech_lab_reset_home_dir
# - Klont/updated nach TARGET_DIR
# - Kopiert systemd-Units (*.service/*.timer) und aktiviert sie
# - Installiert ausführbare Skripte aus ./scripts nach /usr/local/bin

set -euo pipefail

# --- Konfiguration (kann beim Aufruf überschrieben werden) ---
REPO_URL=${REPO_URL:-"https://github.com/ChrHohmann/mech_lab_reset_home_dir.git"}
TARGET_DIR=${TARGET_DIR:-"/opt/mech_lab_reset_home_dir"}
RUN_USER=${RUN_USER:-"pi"}              # Ausführender User
SYSTEMD_DIR="/etc/systemd/system"
USR_LOCAL_BIN="/usr/local/bin"

echo "[reset-home] Repo:  $REPO_URL"
echo "[reset-home] Ziel: $TARGET_DIR (User: $RUN_USER)"

# 1) Repository holen oder aktualisieren
if [[ -d "$TARGET_DIR/.git" ]]; then
  echo "[reset-home] Aktualisiere bestehendes Repo..."
  git -C "$TARGET_DIR" fetch --all --quiet || true
  git -C "$TARGET_DIR" pull --ff-only || true
else
  echo "[reset-home] Klone Repository..."
  git clone "$REPO_URL" "$TARGET_DIR"
fi
chown -R "$RUN_USER:$RUN_USER" "$TARGET_DIR" || true

# 2) Executables aus ./scripts nach /usr/local/bin installieren (falls vorhanden)
if compgen -G "$TARGET_DIR/scripts/*" >/dev/null; then
  echo "[reset-home] Installiere Executables nach $USR_LOCAL_BIN"
  install -m 755 "$TARGET_DIR"/scripts/* "$USR_LOCAL_BIN"/
else
  echo "[reset-home] Kein ./scripts-Verzeichnis oder keine Dateien – überspringe /usr/local/bin-Install."
fi

# 3) Systemd-Units (*.service/*.timer) aus dem Repo installieren/aktivieren
mapfile -t UNIT_FILES < <(find "$TARGET_DIR" -type f \( -name "*.service" -o -name "*.timer" \))
if (( ${#UNIT_FILES[@]} > 0 )); then
  echo "[reset-home] Installiere Systemd-Units..."
  for uf in "${UNIT_FILES[@]}"; do
    base=$(basename "$uf")
    install -m 644 "$uf" "$SYSTEMD_DIR/$base"

    # Platzhalter ersetzen
    if grep -q "@USER@" "$SYSTEMD_DIR/$base"; then
      sed -i "s/@USER@/$RUN_USER/g" "$SYSTEMD_DIR/$base"
    fi
    if grep -q "@APP_DIR@" "$SYSTEMD_DIR/$base"; then
      sed -i "s|@APP_DIR@|$TARGET_DIR|g" "$SYSTEMD_DIR/$base"
    fi
  done

  systemctl daemon-reload
  for uf in "${UNIT_FILES[@]}"; do
    base=$(basename "$uf")
    echo "[reset-home] enable --now $base"
    systemctl enable --now "$base"
  done
else
  echo "[reset-home] Keine *.service/*.timer im Repo gefunden – Systemd-Setup übersprungen."
fi

echo "[OK] mech_lab_reset_home_dir installiert/aktualisiert."