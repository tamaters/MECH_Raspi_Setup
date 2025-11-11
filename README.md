# MECH_Raspi_Setup

This Git houses the Setup script for the MECH Raspis.
This asumes that the MAC Adresse of the Raspi is saved in the EEE Networkmanager.

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
sudo bash scripts/05_system_update.sh
sudo bash scripts/06_groups_users.sh
sudo bash scripts/10_create_global_venv.sh
sudo bash scripts/20_install_packages.sh
sudo bash scripts/30_shell_activation.sh
sudo bash scripts/45_mech_lab_reset_home_dir.sh
```

## Step 3: Interface enable
```
sudo raspi-config
```
Enable SPI and Enable I2C
```
sudo reboot
```
