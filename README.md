# MECH_Raspi_Setup

This Git houses the Setup script for the MECH Raspis

## Step 1: Configure WIFI <br />
*Change identity and password for that in the EEE* <br />
``` bash
sudo nmcli connection add \
    type wifi \
    con-name "EEE" \
    ifname wlan0 \
    ssid "EEE" \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap peap \
    802-1x.phase2-auth mschapv2 \
    802-1x.identity "eee-w009-038" \
    802-1x.password "nEKM7qjgDWEbB7pb2NJ2" \
    802-1x.system-ca-certs no \
    connection.autoconnect yes \
    connection.autoconnect-priority 100
```

## Step 2: Create user
``` bash
sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/tamaters/MECH_Raspi_Setup.git MECH_Raspi_Setup && cd MECH_Raspi_Setup
sudo bash user_setup.sh
``` 

