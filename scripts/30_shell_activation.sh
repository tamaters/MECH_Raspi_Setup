#!/usr/bin/env bash
# scripts/30_shell_activation.sh
# Richtet systemweite Auto-Aktivierung der globalen venv ein (auch für VS Code, non-interactive shells).
set -euo pipefail

VENV_DIR=${VENV_DIR:-/opt/.venvs/MECH}
PROFILED_SCRIPT="/etc/profile.d/activate_venv_mech.sh"

# Hilfsfunktion: Marker-prüfender Append (ohne Expansion)
append_if_missing() { # <file> <marker>  (Inhalt wird aus STDIN gelesen)
  local file="$1"; local marker="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fq "$marker" "$file" || cat >> "$file"
}

echo "[1/4] Systemweite Aktivierung über /etc/profile.d (non-interactive-safe)"
# WICHTIG: Kein case $- in *i*-Check mehr → wird in allen Shell-Typen aktiviert.
cat > "$PROFILED_SCRIPT" <<'EOS'
# /etc/profile.d/activate_venv_mech.sh
VENV_DIR=/opt/.venvs/MECH
if [ -z "$VIRTUAL_ENV" ] && [ -f "$VENV_DIR/bin/activate" ]; then
  . "$VENV_DIR/bin/activate"
fi
EOS
chmod +x "$PROFILED_SCRIPT"

echo "[2/4] Für alle bestehenden Nutzer ~/.bashrc ergänzen und ~/.bashrc_with_venv erzeugen"
for home in /root /home/*; do
  [ -d "$home" ] || continue
  owner="$(stat -c "%U" "$home" || echo root)"
  group="$(stat -c "%G" "$home" || echo root)"

  BRC="$home/.bashrc"
  append_if_missing "$BRC" "# >>> venv_mech auto-activate >>>" <<'EOBRC'
# >>> venv_mech auto-activate >>>
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/.venvs/MECH/bin/activate ]; then
  . /opt/.venvs/MECH/bin/activate
fi
# <<< venv_mech auto-activate <<<
EOBRC

  BRCV="$home/.bashrc_with_venv"
  cat > "$BRCV" <<'EOV'
# Spezielle Bashrc: erst normale ~/.bashrc laden
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
# Danach globale venv aktivieren (falls noch keine aktiv ist)
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/.venvs/MECH/bin/activate ]; then
  . /opt/.venvs/MECH/bin/activate
fi
EOV

  chown "$owner:$group" "$BRC" "$BRCV" || true
  chmod 644 "$BRC" "$BRCV" || true
done

echo "[3/4] Vorlagen für künftige Nutzer in /etc/skel"
append_if_missing /etc/skel/.bashrc "# >>> venv_mech auto-activate >>>" <<'EOSKEL'
# >>> venv_mech auto-activate >>>
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/.venvs/MECH/bin/activate ]; then
  . /opt/.venvs/MECH/bin/activate
fi
# <<< venv_mech auto-activate <<<
EOSKEL

cat > /etc/skel/.bashrc_with_venv <<'EOV'
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/.venvs/MECH/bin/activate ]; then
  . /opt/.venvs/MECH/bin/activate
fi
EOV
chmod 644 /etc/skel/.bashrc_with_venv

echo "[4/4] Test"
if [ -x "$VENV_DIR/bin/python" ]; then
  echo "Python: $("$VENV_DIR"/bin/python -V 2>/dev/null || true)"
fi
echo "[OK] Shell-Aktivierung (global + non-interactive) eingerichtet."
