#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash scripts/05_system_update.sh
bash scripts/06_groups_users.sh
bash scripts/10_create_global_venv.sh
bash scripts/20_install_packages.sh
bash scripts/25_motd_setup.sh
bash scripts/30_shell_activation.sh
bash scripts/35_vnc_config.sh
bash scripts/40_install_oled_netinfo.sh
bash scripts/45_mech_lab_reset_home_dir.sh

echo "[OK] Komplettes Setup abgeschlossen"