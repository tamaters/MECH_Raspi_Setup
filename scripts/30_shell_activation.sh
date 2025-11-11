#!/usr/bin/env bash
# scripts/30_shell_activation.sh
# Richtet systemweite Auto-Aktivierung der globalen venv ein und ergänzt Benutzer-Shells.
set -euo pipefail

VENV_DIR=${VENV_DIR:-/opt/.venvs/MECH_LAB}
PROFILED_SCRIPT="/etc/profile.d/activate_venv_mech_lab.sh"

# Hilfsfunktion: Marker-prüfender Append (ohne Expansion)
append_if_missing() { # <file> <marker>  (Inhalt wird aus STDIN gelesen)
  local file="$1"; local marker="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fq "$marker" "$file" || cat >> "$file"
}

echo "[1/4] Systemweite Aktivierung über /etc/profile.d"
# Ganz wichtig: gequoteter Heredoc, damit $... NICHT jetzt expandiert, sondern erst zur Laufzeit der Login-Shell.
cat > "$PROFILED_SCRIPT" <<'EOS'
# /etc/profile.d/activate_venv_mech_lab.sh
VENV_DIR=/opt/.venvs/MECH_LAB
case $- in
  *i*)
    if [ -z "$VIRTUAL_ENV" ] && [ -f "$VENV_DIR/bin/activate" ]; then
      . "$VENV_DIR/bin/activate"
    fi
    ;;
esac
EOS
chmod +x "$PROFILED_SCRIPT"

echo "[2/4] Für alle bestehenden Nutzer ~/.bashrc ergänzen und ~/.bashrc_with_venv erzeugen"
for home in /root /home/*; do
  [ -d "$home" ] || continue
  owner="$(stat -c "%U" "$home" || echo root)"
  group="$(stat -c "%G" "$home" || echo root)"

  # ~/.bashrc ergänzen (idempotent) – wieder: gequoteter Heredoc, damit $... nicht jetzt expandiert
  BRC="$home/.bashrc"
  append_if_missing "$BRC" "# >>> venv_mech_lab auto-activate >>>" <<'EOBRC'
# >>> venv_mech_lab auto-activate >>>
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/.venvs/MECH_LAB/bin/activate ]; then
  case $- in *i*) . /opt/.venvs/MECH_LAB/bin/activate ;; esac
fi
# <<< venv_mech_lab auto-activate <<<
EOBRC

  # ~/.bashrc_with_venv neu schreiben (hier komplett ersetzen/erstellen)
  BRCV="$home/.bashrc_with_venv"
  cat > "$BRCV" <<'EOV'
# Spezielle Bashrc: erst normale ~/.bashrc laden
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
# Danach globale venv aktivieren (falls noch keine aktiv ist)
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/.venvs/MECH_LAB/bin/activate ]; then
  . /opt/.venvs/MECH_LAB/bin/activate
fi
EOV

  chown "$owner:$group" "$BRC" "$BRCV" || true
  chmod 644 "$BRC" "$BRCV" || true
done

echo "[3/4] Vorlagen für künftige Nutzer in /etc/skel"
# ~/.bashrc Ergänzung in /etc/skel
append_if_missing /etc/skel/.bashrc "# >>> venv_mech_lab auto-activate >>>" <<'EOSKEL'
# >>> venv_mech_lab auto-activate >>>
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/.venvs/MECH_LAB/bin/activate ]; then
  case $- in *i*) . /opt/.venvs/MECH_LAB/bin/activate ;; esac
fi
# <<< venv_mech_lab auto-activate <<<
EOSKEL

# ~/.bashrc_with_venv Vorlage in /etc/skel
cat > /etc/skel/.bashrc_with_venv <<'EOV'
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/.venvs/MECH_LAB/bin/activate ]; then
  . /opt/.venvs/MECH_LAB/bin/activate
fi
EOV
chmod 644 /etc/skel/.bashrc_with_venv

echo "[4/4] Test"
if [ -x "$VENV_DIR/bin/python" ]; then
  echo "Python: $("$VENV_DIR"/bin/python -V 2>/dev/null || true)"
fi
echo "[OK] Shell-Aktivierung eingerichtet."