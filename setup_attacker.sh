#!/bin/bash
set -e

apt-get update -qq
apt-get install -y nmap netcat-openbsd john ruby ruby-dev build-essential

gem install zsteg chunky_png

# extract rockyou if needed
gunzip /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || true

echo "=============================="
echo "Attacker ready!"
echo "Target: 192.168.56.20"
echo "=============================="