#!/bin/bash
# user_setup.sh — Creates user 'stud', Python venv, and safe cleanup service

set -euo pipefail

RUN_USER="stud"
STUD_HOME="/home/$RUN_USER"
SYSTEMD_DIR="/etc/systemd/system"
CLEANUP_SCRIPT="/usr/local/bin/cleanup-stud.sh"

echo "=== Creating user '$RUN_USER' with MECH Python environment ==="

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script with sudo."
  exit 1
fi

# --- Ensure python3-venv and pip are installed ---
if ! dpkg -l | grep -q python3-venv; then
  echo "Installing python3-venv and pip..."
  apt-get update
  apt-get install -y python3-venv python3-pip
fi

# --- Create user if missing ---
if id "$RUN_USER" &>/dev/null; then
  echo "User '$RUN_USER' already exists."
else
  echo "Creating user '$RUN_USER'..."
  useradd -m -s /bin/bash "$RUN_USER"
  echo "$RUN_USER:MY3.141" | chpasswd
  echo "✓ User '$RUN_USER' created with password 'MY3.141'"
fi

# --- Create Python virtual environment if missing ---
if [[ ! -d "$STUD_HOME/MECH" ]]; then
  echo "Creating Python virtual environment 'MECH'..."
  su - "$RUN_USER" -c "python3 -m venv ~/MECH"
  echo "Installing required libraries into MECH venv..."
  su - "$RUN_USER" -c "source ~/MECH/bin/activate && pip install --upgrade pip && pip install numpy matplotlib gpiozero rpi-lgpio lgpio spidev"
  echo "✓ Virtual environment 'MECH' ready"
else
  echo "Virtual environment already exists — skipping creation."
fi

# --- Add auto-activation to .bashrc ---
if ! grep -q "MECH/bin/activate" "$STUD_HOME/.bashrc" 2>/dev/null; then
  cat >> "$STUD_HOME/.bashrc" <<'EOF'

# Auto-activate MECH virtual environment
if [ -d "$HOME/MECH" ]; then
    source "$HOME/MECH/bin/activate"
    echo "✓ MECH virtual environment activated"
fi
EOF
fi

# --- Ensure .bash_profile loads .bashrc ---
cat > "$STUD_HOME/.bash_profile" <<'EOF'
# Load .bashrc if it exists
[ -f ~/.bashrc ] && . ~/.bashrc
EOF

chown "$RUN_USER:$RUN_USER" "$STUD_HOME/.bashrc" "$STUD_HOME/.bash_profile"

echo "✓ Auto-activation configured"

# --- Create cleanup script ---
cat > "$CLEANUP_SCRIPT" <<'EOF'
#!/bin/bash
# cleanup-stud.sh — Cleans user-created Python files after logout

STUD_HOME="/home/stud"
LOGFILE="/var/log/cleanup-stud.log"

sleep 2

# Proceed only if user is fully logged out
if ! who | grep -q "^stud "; then
    echo "$(date): Cleaning user-created Python files in $STUD_HOME" >> "$LOGFILE"

    # Delete only user-created files (preserve virtualenv & libraries)
    find "$STUD_HOME" -type f \( -name "*.py" -o -name "*.ipynb" -o -name "*.txt" -o -name "*.csv" -o -name "*.log" \) -delete

    # Remove Python cache directories
    find "$STUD_HOME" -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".cache" \) -exec rm -rf {} +

    chown -R stud:stud "$STUD_HOME"
    logger "User 'stud' cleanup: removed custom Python files, kept MECH libraries intact"
fi
EOF

chmod +x "$CLEANUP_SCRIPT"
echo "✓ Created cleanup script at $CLEANUP_SCRIPT"

# --- Create systemd cleanup service ---
cat > "$SYSTEMD_DIR/stud-cleanup@.service" <<'EOF'
[Unit]
Description=Cleanup stud user-created files after logout
After=user@%i.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cleanup-stud.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

# --- Enable service for stud’s UID ---
STUD_UID=$(id -u "$RUN_USER")
systemctl enable stud-cleanup@"${STUD_UID}".service

# --- Add PAM hook if not already present ---
if ! grep -q "cleanup-stud.sh" /etc/pam.d/common-session; then
  echo "session optional pam_exec.so /usr/local/bin/cleanup-stud.sh" >> /etc/pam.d/common-session
fi

echo ""
echo "=== Setup Complete ==="
echo "User: $RUN_USER (password: MY3.141)"
echo "Virtual Environment: MECH (auto-activates on login)"
echo "Cleanup: deletes only user-created Python files after logout"
echo ""
echo "Test it:"
echo "  su - stud"
echo "  echo 'print(123)' > test.py"
echo "  exit"
echo "  # test.py will be automatically deleted"
