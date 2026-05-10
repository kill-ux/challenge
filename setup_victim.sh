#!/bin/bash
set -e

apt-get update -qq
apt-get install -y vsftpd netcat-openbsd ruby ruby-dev \
  libpng-dev imagemagick build-essential python3

gem install chunky_png zsteg

# ── CREATE THE FLAG AND HASH ──────────────────
PASSWORD="password123"
HASH=$(python3 -c "
import crypt
print(crypt.crypt('$PASSWORD', crypt.mksalt(crypt.METHOD_SHA512)))
")
echo $HASH > /tmp/hash_to_hide.txt

# ── CREATE PNG AND HIDE HASH INSIDE ──────────
convert -size 200x200 xc:white /tmp/cover.png

ruby << 'RUBYEOF'
require 'chunky_png'
data = File.read('/tmp/hash_to_hide.txt').strip
img = ChunkyPNG::Image.from_file('/tmp/cover.png')
bits = data.bytes.flat_map { |b| 8.times.map { |i| (b >> (7-i)) & 1 } }
bits.each_with_index do |bit, idx|
  x = idx % img.width
  y = idx / img.width
  px = img[x, y]
  r = (ChunkyPNG::Color.r(px) & ~1) | bit
  img[x, y] = ChunkyPNG::Color.rgba(
    r,
    ChunkyPNG::Color.g(px),
    ChunkyPNG::Color.b(px),
    ChunkyPNG::Color.a(px)
  )
end
img.save('/srv/ftp/secret.png')
puts 'secret.png created with hidden hash!'
RUBYEOF

# ── SETUP FTP (anonymous, list only, no download) ──
apt-get install -y vsftpd

cat > /etc/vsftpd.conf << 'FTPEOF'
listen=YES
listen_ipv6=NO
anonymous_enable=YES
local_enable=NO
write_enable=NO
anon_upload_enable=NO
anon_mkdir_write_enable=NO
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
anon_root=/srv/ftp
no_anon_password=YES
hide_ids=YES

# KEY: deny download but allow listing
anon_world_readable_only=NO
download_enable=NO
FTPEOF

# create ftp root
mkdir -p /srv/ftp
chmod 755 /srv/ftp

systemctl restart vsftpd
systemctl enable vsftpd

sudo tee /usr/local/bin/ctf-server.py << 'PYEOF'
#!/usr/bin/env python3
import socket
import os

FTP_ROOT = "/srv/ftp"
HOST = "0.0.0.0"
PORT = 4444
ALLOWED_FILE = "secret.png"

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((HOST, PORT))
server.listen(5)
print(f"CTF server listening on port {PORT}")

while True:
    conn, addr = server.accept()
    print(f"Connection from {addr}")
    try:
        filename = conn.recv(1024).decode().strip()
        if filename != ALLOWED_FILE:
            conn.sendall(b"ERROR: permission denied\n")
        else:
            filepath = os.path.join(FTP_ROOT, ALLOWED_FILE)
            with open(filepath, 'rb') as f:
                conn.sendall(f.read())
    finally:
        conn.close()
PYEOF

chmod +x /usr/local/bin/ctf-server.py

# ── SYSTEMD SERVICE ───────────────────────────
cat > /etc/systemd/system/ctf-server.service << SVCEOF
[Unit]
Description=CTF File Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/ctf-server.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable ctf-server
systemctl start ctf-server

echo "=============================="
echo "Victim ready!"
echo "FTP port 21  → list files, no download"
echo "NC  port 4444 → send filename, get content"
echo "Password: $PASSWORD"
echo "Hash: $HASH"
echo "=============================="