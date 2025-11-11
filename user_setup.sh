#!/bin/bash
set -e
echo "=== Creating Temporary User 'stud' with Python Virtual Environment ==="

# Must be root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

# --- 1. System prerequisites for Python and lgpio ---
echo "Installing prerequisites..."
apt-get update
apt-get install -y python3-venv python3-pip python3-dev build-essential swig liblgpio-dev

# --- 2. Create necessary groups if they don't exist ---
echo "Ensuring required groups exist..."
getent group spi >/dev/null || groupadd -r spi
getent group gpio >/dev/null || groupadd -r gpio
getent group dialout >/dev/null || groupadd -r dialout
getent group i2c >/dev/null || groupadd -r i2c

# --- 3. Create user 'stud' if not exists ---
if id "stud" &>/dev/null; then
    echo "User 'stud' already exists."
else
    echo "Creating user 'stud'..."
    useradd -m -s /bin/bash stud
    echo "stud:MY3.141" | chpasswd
    echo "✓ User 'stud' created with password 'MY3.141'"
fi

# --- 4. Add user to hardware access groups ---
echo "Adding user 'stud' to hardware groups..."
usermod -a -G spi,gpio,dialout,i2c stud
echo "✓ User 'stud' added to groups: spi, gpio, dialout, i2c"

# --- 5. Create and populate Python virtual environment as stud ---
echo "Setting up MECH virtual environment..."
su - stud -c "python3 -m venv ~/MECH"
su - stud -c "source ~/MECH/bin/activate && pip install --upgrade pip"
su - stud -c "source ~/MECH/bin/activate && pip install numpy matplotlib gpiozero rpi-lgpio lgpio spidev"
echo "✓ Virtual environment 'MECH' ready with all libraries."

# --- 6. Auto-activate MECH on login ---
cat >> /home/stud/.bashrc << 'EOF'

# Auto-activate MECH virtual environment
if [ -d "$HOME/MECH" ] && [ -f "$HOME/MECH/bin/activate" ]; then
    source "$HOME/MECH/bin/activate"
fi
EOF

cat > /home/stud/.bash_profile << 'EOF'
# Load .bashrc if it exists
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

chown stud:stud /home/stud/.bashrc /home/stud/.bash_profile
echo "✓ Auto-activation configured."

# --- 7. Cleanup script for resetting home directory (preserves MECH venv and VSCode extensions) ---
cat > /usr/local/bin/cleanup-stud.sh << 'EOF'
#!/bin/bash
sleep 2

if ! who | grep -q "^stud "; then
    # Create original backup if it doesn't exist (after venv and extensions are set up)
    if [ ! -d /home/stud.original ]; then
        cp -a /home/stud /home/stud.original
    fi
    
    # Preserve MECH venv and VSCode extensions before cleanup
    if [ -d /home/stud/MECH ]; then
        mkdir -p /tmp/stud-preserve
        cp -a /home/stud/MECH /tmp/stud-preserve/
    fi
    
    if [ -d /home/stud/.vscode-server ]; then
        mkdir -p /tmp/stud-preserve
        cp -a /home/stud/.vscode-server /tmp/stud-preserve/
    fi
    
    # Reset home directory
    rm -rf /home/stud
    cp -a /home/stud.original /home/stud
    
    # Restore MECH venv
    if [ -d /tmp/stud-preserve/MECH ]; then
        cp -a /tmp/stud-preserve/MECH /home/stud/
    fi
    
    # Restore VSCode extensions
    if [ -d /tmp/stud-preserve/.vscode-server ]; then
        cp -a /tmp/stud-preserve/.vscode-server /home/stud/
    fi
    
    # Cleanup temp directory
    rm -rf /tmp/stud-preserve
    
    chown -R stud:stud /home/stud
    logger "User 'stud' home directory reset (MECH venv and VSCode extensions preserved)"
fi
EOF

chmod +x /usr/local/bin/cleanup-stud.sh

# --- 8. Systemd service for cleanup ---
cat > /etc/systemd/system/stud-cleanup@.service << 'EOF'
[Unit]
Description=Cleanup stud user changes after logout
After=user@%i.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cleanup-stud.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

STUD_UID=$(id -u stud)
systemctl enable stud-cleanup@${STUD_UID}.service

# --- 9. PAM hook for cleanup ---
if ! grep -q "cleanup-stud.sh" /etc/pam.d/common-session; then
    echo "session optional pam_exec.so /usr/local/bin/cleanup-stud.sh" >> /etc/pam.d/common-session
fi

echo ""
echo "=== Setup Complete ==="
echo "User: stud (password: MY3.141)"
echo "Groups: spi, gpio, dialout, i2c"
echo "Virtual Environment: MECH (auto-activates on login)"
echo "Installed packages: numpy, matplotlib, gpiozero, rpi-lgpio, lgpio, spidev"
echo ""
echo "PRESERVED ACROSS LOGOUTS:"
echo "  - MECH virtual environment with all installed libraries"
echo "  - VSCode extensions (.vscode-server)"
echo ""
echo "DELETED AFTER LOGOUT:"
echo "  - User files created in home directory"
echo "  - Modified configuration files"
echo ""
echo "Test it with:"
echo "  su - stud"
echo "  groups"
echo "  which python"
echo "  python -m pip list"
