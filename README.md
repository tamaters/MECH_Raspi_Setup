# MECH_Raspi_Setup

This Git houses the Setup script for the MECH Raspis

## Step 1: Configure WIFI <br />
``` bash
sudo nano /etc/NetworkManager/system-connections/University-WiFi.nmconnection
```
*Paste the config, edit SSID/username/password* <br />
``` bash
sudo chmod 600 /etc/NetworkManager/system-connections/University-WiFi.nmconnection
sudo nmcli connection reload
sudo nmcli connection up University-WiFi
```

## Step 2: Create user
``` bash
sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/tamaters/MECH_Raspi_Setup.git MECH_Raspi_Setup && cd MECH_Raspi_Setup
sudo bash user_setup.sh
``` 

