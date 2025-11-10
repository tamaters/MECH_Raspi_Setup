# MECH_Raspi_Setup

This Git houses the Setup script for the MECH Raspis
This asumes that the MAC Adresse of the Raspi is saved in the EEE Networkmanager

## Step 1: Configure WIFI <br />
Change identity and password for that in the EEE Networkmanager <br />
``` bash
sudo nmcli connection add \
    type wifi \
    con-name "EEE" \
    ifname wlan0 \
    ssid "EEE" \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap peap \
    802-1x.phase2-auth mschapv2 \
    802-1x.identity "Username" \
    802-1x.password "password" \
    802-1x.system-ca-certs no \
    connection.autoconnect yes \
    connection.autoconnect-priority 100
```
Disconnect from Raspi and then try and connect with HSLU. At first the IP might be needed.

## Step 2: Create user
``` bash
sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/tamaters/MECH_Raspi_Setup.git MECH_Raspi_Setup && cd MECH_Raspi_Setup
sudo apt install -y dos2unix
sudo dos2unix user_setup.sh
sudo bash user_setup.sh
```
