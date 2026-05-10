#!/bin/bash
#!/bin/bash
set -e

apt-get update -qq
apt-get install -y \
  nmap \
  netcat-openbsd \
  john \
  ruby \
  ruby-dev \
  build-essential \
  ftp \
  arp-scan

gem install zsteg chunky_png

# extract rockyou if needed
mkdir -p /usr/share/wordlists
curl -L https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt \
  -o /usr/share/wordlists/rockyou.txt

echo "=============================="
echo "Attacker ready!"
echo "Target: 192.168.56.20"
echo "=============================="