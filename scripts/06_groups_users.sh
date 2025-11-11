#!/usr/bin/env bash
set -euo pipefail

# Gruppen 6)
for g in stud vnc; do
  if ! getent group "$g" >/dev/null; then
    groupadd "$g"
    echo "[groups] Gruppe angelegt: $g"
  else
    echo "[groups] Gruppe existiert: $g"
  fi
done

# 7) pi in vnc
if id -nG pi 2>/dev/null | grep -qw vnc; then
  echo "[groups] pi ist bereits in vnc"
else
  usermod -a -G vnc pi && echo "[groups] pi zur Gruppe vnc hinzugefügt"
fi

# 8) stud anlegen: Primärgruppe stud, Sekundärgruppen gpio,i2c,vnc
if id -u stud >/dev/null 2>&1; then
  echo "[users] stud existiert bereits"
else
  useradd -m -g stud -G gpio,i2c,spi,vnc -s /bin/bash stud
  echo "[users] Benutzer stud angelegt"
fi

# 9) labor1 anlegen: Primärgruppe stud, Sekundärgruppen gpio,i2c,vnc
if id -u labor1 >/dev/null 2>&1; then
  echo "[users] labor1 existiert bereits"
else
  useradd -m -g stud -G gpio,i2c,vnc -s /bin/bash labor1
  echo "[users] Benutzer labor1 angelegt"
fi

# 10) Passwörter setzen (non-interaktiv)
# ACHTUNG: steht hier explizit, weil gefordert – ggf. später ändern!
echo 'stud:MY3.141' | chpasswd
echo 'labor1:cupcake2019' | chpasswd

echo "[sudoers] Erlaube Gruppe stud: poweroff & shutdown ohne Passwort"
# 11) /etc/sudoers.d statt direkte Bearbeitung von /etc/sudoers
cat > /etc/sudoers.d/stud_shutdown <<'EOF'
%stud ALL=(root) NOPASSWD:/usr/sbin/poweroff, /usr/sbin/shutdown
EOF
chmod 440 /etc/sudoers.d/stud_shutdown

echo "[OK] Gruppen, Benutzer, Passwörter, sudoers eingerichtet"
