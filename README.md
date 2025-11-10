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

## Step 3: Install libraries
```
# 1. Create and activate a virtual environment
python3 -m venv ~/MECH
source ~/MECH/bin/activate

# 2. Upgrade pip
pip install --upgrade pip

# 3. Install all necessary libraries (including lgpio)
pip install \
    numpy \
    matplotlib \
    gpiozero \
    rpi-lgpio \
    lgpio \
    spidev
```


