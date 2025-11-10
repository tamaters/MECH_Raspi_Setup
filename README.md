# MECH_Raspi_Setup

This Git houses the Setup script for the MECH Raspis

# Step 1: Configure WIFI
sudo nano /etc/NetworkManager/system-connections/University-WiFi.nmconnection
Paste the config, edit SSID/username/password
sudo chmod 600 /etc/NetworkManager/system-connections/University-WiFi.nmconnection
sudo nmcli connection reload
sudo nmcli connection up University-WiFi

# Step 2: Create user
sudo bash setup-stud-user.sh
