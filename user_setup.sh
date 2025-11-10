#!/bin/bash

# Exit on error
set -e

echo "=== Creating Temporary User 'stud' with Python Virtual Environment ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo)"
    exit 1
fi

# Check if python3-venv is installed
if ! dpkg -l | grep -q python3-venv; then
    echo "Installing python3-venv..."
    apt-get update
    apt-get install -y python3-venv python3-pip
fi

# Create temporary user
echo "Creating user 'stud'..."

# Create user with home directory
useradd -m -s /bin/bash stud

# Set password
echo "stud:MY3.141" | chpasswd

echo "✓ User 'stud' created with password 'MY3.141'"

# Create Python virtual environment as the stud user
echo "Creating Python virtual environment 'MECH'..."
su - stud -c "python3 -m venv ~/MECH"

echo "✓ Virtual environment 'MECH' created"

# Configure automatic activation in .bashrc
cat >> /home/stud/.bashrc << 'EOF'

# Auto-activate MECH virtual environment
if [ -d "$HOME/MECH" ]; then
    source "$HOME/MECH/bin/activate"
    echo "✓ MECH virtual environment activated"
fi
EOF

# Also create .bash_profile to ensure it works for login shells
cat > /home/stud/.bash_profile << 'EOF'
# Load .bashrc if it exists
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

chown stud:stud /home/stud/.bashrc
chown stud:stud /home/stud/.bash_profile

echo "✓ Auto-activation configured in .bashrc"

# Create logout cleanup script
cat > /usr/local/bin/cleanup-stud.sh << 'EOF'
#!/bin/bash

# Wait for user to fully logout
sleep 2

# Check if user is still logged in
if ! who | grep -q "^stud "; then
    # Create snapshot of original home directory if it doesn't exist
    if [ ! -d /home/stud.original ]; then
        cp -a /home/stud /home/stud.original
    fi
    
    # Delete current home directory and restore original
    rm -rf /home/stud
    cp -a /home/stud.original /home/stud
    chown -R stud:stud /home/stud
    
    logger "User 'stud' home directory reset to original state"
fi
EOF

chmod +x /usr/local/bin/cleanup-stud.sh

# Create systemd service to run cleanup on logout
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

# Enable the service for the stud user's UID
STUD_UID=$(id -u stud)
systemctl enable stud-cleanup@${STUD_UID}.service

# Add PAM cleanup hook
if ! grep -q "cleanup-stud.sh" /etc/pam.d/common-session; then
    echo "session optional pam_exec.so /usr/local/bin/cleanup-stud.sh" >> /etc/pam.d/common-session
fi

echo "✓ Cleanup mechanism configured"
echo ""
echo "=== Setup Complete ==="
echo "User: stud (password: MY3.141)"
echo "Virtual Environment: MECH (auto-activates on login)"
echo "Note: All changes made by 'stud' will be deleted after logout"
echo ""
echo "Test the setup:"
echo "  su - stud"
echo "  # MECH venv should auto-activate"
echo "  which python"
echo "  pip install numpy  # Install something"
echo "  exit"
echo "  # Changes should be reverted automatically"
