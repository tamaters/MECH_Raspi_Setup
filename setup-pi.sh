#!/bin/bash

# Exit on error
set -e

echo "=== Raspberry Pi 5 WiFi Setup and Temporary User Creation ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo)"
    exit 1
fi

# WiFi Configuration
read -p "Enter WiFi SSID: " SSID
read -p "Enter EAP Identity/Username: " EAP_IDENTITY
read -sp "Enter EAP Password: " EAP_PASSWORD
echo

# Create NetworkManager connection for WPA/WPA2 Enterprise
echo "Configuring WiFi connection..."
nmcli connection add \
    type wifi \
    con-name "Enterprise-WiFi" \
    ifname wlan0 \
    ssid "$SSID" \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap peap \
    802-1x.phase2-auth mschapv2 \
    802-1x.identity "$EAP_IDENTITY" \
    802-1x.password "$EAP_PASSWORD"

# Bring up the connection
echo "Connecting to WiFi..."
nmcli connection up "Enterprise-WiFi"

echo "✓ WiFi connected successfully"

# Create temporary user
echo "Creating temporary user 'stud'..."

# Create user with home directory
useradd -m -s /bin/bash stud

# Set password
echo "stud:MECH2025" | chpasswd

echo "✓ User 'stud' created with password 'MECH2025'"

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

# Alternative: Use PAM to trigger cleanup on logout
echo "session optional pam_exec.so /usr/local/bin/cleanup-stud.sh" >> /etc/pam.d/common-session

echo "✓ Cleanup mechanism configured"
echo ""
echo "=== Setup Complete ==="
echo "WiFi: Connected to $SSID"
echo "User: stud (password: MECH2025)"
echo "Note: All changes made by 'stud' will be deleted after logout"