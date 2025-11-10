# MECH_Raspi_Setup

This Git houses the Setup script for the MECH Raspis

## Step 1: Configure WIFI <br />
```sudo nano /etc/NetworkManager/system-connections/University-WiFi.nmconnection``` <br />
*Paste the config, edit SSID/username/password* <br />
```sudo chmod 600 /etc/NetworkManager/system-connections/University-WiFi.nmconnection``` <br />
```sudo nmcli connection reload``` <br />
```sudo nmcli connection up University-WiFi``` <br />

## Step 2: Create user
```sudo bash setup-stud-user.sh``` <br />
