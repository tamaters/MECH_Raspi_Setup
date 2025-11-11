#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# setup_stud_mech_global_venv.sh
# Creates user 'stud', adds hardware groups, sets up global venv /opt/.venvs/MECH
# Installs Raspberry Pi 5 libraries and cleanup logic (same as HSLU provisioning)
# -----------------------------------------------------------------------------
set -euo pipefail

USER_NAME="stud"
USER_PASS="MY3.141"
VENV_DIR="/opt/.venvs/MECH"

echo "[setup] === Creating global MECH environment and user '${USER_NAME}' ==="

# --- 1) System prerequisites -------------------------------------------------
echo "[setup] Installing prerequisites..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  python3 python3-venv python3-pip python3-dev build-essential \
  git swig liblgpio-dev

# --- 2) Ensure groups --------------------------------------------------------
for grp in gpio spi i2c dialout; do
  getent group "$grp" >/dev/null || groupadd -r "$grp"
done

# --- 3) Create user ----------------------------------------------------------
if id "$USER_NAME" &>/dev/null; then
  echo "[setup] User '$USER_NAME' already exists."
else
  useradd -m -s /bin/bash "$USER_NAME"
  echo "${USER_NAME}:${USER_PASS}" | chpasswd
  echo "[setup] ✓ User '${USER_NAME}' created (password: ${USER_PASS})"
fi

usermod -aG gpio,spi,i2c,dialout "$USER_NAME"
echo "[setup] ✓ Added '${USER_NAME}' to groups gpio spi i2c dialout"

# --- 4) Create global venv ---------------------------------------------------
if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
  echo "[setup] Creating global venv at ${VENV_DIR}..."
  mkdir -p "$(dirname "$VENV_DIR")"
  python3 -m venv "$VENV_DIR"
else
  echo "[setup] Reusing existing venv at ${VENV_DIR}"
fi

# --- 5) Install packages -----------------------------------------------------
echo "[setup] Installing packages in MECH venv..."
source "${VENV_DIR}/bin/activate"
pip install --upgrade pip setuptools wheel --break-system-packages
pip install numpy matplotlib gpiozero rpi-lgpio lgpio spidev pyserial smbus2 pandas scipy --break-system-packages
deactivate
echo "[setup] ✓ Packages installed"

# --- 6) Permissions ----------------------------------------------------------
chmod -R a+rX "$VENV_DIR"
chown -R root:root "$VENV_DIR"
echo "[setup] ✓ Global venv permissions set"

# --- 7) Auto-activation for stud user ---------------------------------------
cat >> "/home/${USER_NAME}/.bashrc" <<EOF

# Auto-activate global MECH venv
if [ -f "${VENV_DIR}/bin/activate" ]; then
    source "${VENV_DIR}/bin/activate"
fi
EOF

cat > "/home/${USER_NAME}/.bash_profile" <<'EOF'
# Load .bashrc for login shells
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
EOF
chown "${USER_NAME}:${USER_NAME}" "/home/${USER_NAME}/.bashrc" "/home/${USER_NAME}/.bash_profile"
echo "[setup] ✓ Auto-activation configured"

# --- 8) Cleanup mechanism (same as mech_lab_reset_home_dir) ------------------
cat > /usr/local/bin/cleanup-stud.sh <<'EOF'
#!/usr/bin/env bash
sleep 2
if ! who | grep -q "^stud "; then
    mkdir -p /tmp/stud-preserve
    [[ -d /home/stud/.vscode-server ]] && cp -a /home/stud/.vscode-server /tmp/stud-preserve/
    if [[ ! -d /home/stud.original ]]; then
        cp -a /home/stud /home/stud.original
    fi
    rm -rf /home/stud
    cp -a /home/stud.original /home/stud
    [[ -d /tmp/stud-preserve/.vscode-server ]] && cp -a /tmp/stud-preserve/.vscode-server /home/stud/
    rm -rf /tmp/stud-preserve
    chown -R stud:stud /home/stud
    logger "User 'stud' home reset (global MECH venv + VSCode preserved)"
fi
EOF
chmod +x /usr/local/bin/cleanup-stud.sh

# PAM hook
if ! grep -q cleanup-stud /etc/pam.d/common-session; then
  echo "session optional pam_exec.so /usr/local/bin/cleanup-stud.sh" >> /etc/pam.d/common-session
fi
echo "[setup] ✓ Cleanup mechanism ready"

# --- 9) Summary --------------------------------------------------------------
echo ""
echo "=== Setup Complete ==="
echo "User: ${USER_NAME} (password: ${USER_PASS})"
echo "Groups: gpio spi i2c dialout"
echo "Global venv: ${VENV_DIR}"
echo ""
echo "Installed packages:"
echo "  numpy, matplotlib, gpiozero, rpi-lgpio, lgpio, spidev, pyserial, smbus2, pandas, scipy"
echo ""
echo "Preserved after logout:"
echo "  - Global MECH venv (/opt/.venvs/MECH)"
echo "  - .vscode-server extensions"
echo ""
echo "Test with:"
echo "  su - ${USER_NAME}"
echo "  which python"
echo "  pip list"
