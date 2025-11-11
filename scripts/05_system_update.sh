#!/usr/bin/env bash
set -euo pipefail

echo "[Update] apt-get update && upgrade -y (kann einige Minuten dauern)"
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y