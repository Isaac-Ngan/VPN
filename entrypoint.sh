#!/bin/bash

# Set default password if not provided
if [[ -z "${Password}" ]]; then
  Password="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
ENCRYPT="chacha20-ietf-poly1305"
QR_Path="/qr"

# V2Ray Configuration
V2_Path="/v2"

# Create /wwwroot if missing
mkdir -p /wwwroot

# Move /v2 to /usr/bin/v2 if it exists
if [ -d "${V2_Path}" ]; then
  mv "${V2_Path}" /usr/bin/v2
else
  echo "Warning: ${V2_Path} does not exist, skipping move"
fi

# Create config directory if missing
if [ ! -d /etc/shadowsocks-libev ]; then  
  mkdir /etc/shadowsocks-libev
fi

# Generate config file without plugin lines (for debugging)
sed -e "/^#/d" \
    -e "s/\${PASSWORD}/${Password}/g" \
    -e "s/\${ENCRYPT}/${ENCRYPT}/g" \
    -e "s|\${V2_Path}|${V2_Path}|g" \
    -e "/\"plugin\":/d" \
    -e "/\"plugin_opts\":/d" \
    /conf/shadowsocks-libev_config.json > /etc/shadowsocks-libev/config.json

echo "/etc/shadowsocks-libev/config.json contents:"
cat /etc/shadowsocks-libev/config.json

# Generate nginx config
sed -e "/^#/d" \
    -e "s/\${PORT}/443/g" \
    -e "s|\${V2_Path}|${V2_Path}|g" \
    -e "s|\${QR_Path}|${QR_Path}|g" \
    /conf/nginx_ss.conf > /etc/nginx/conf.d/ss.conf 

# Generate Shadowsocks connection string if domain is set
if [ "${Domain}" = "no" ] || [ -z "${Domain}" ]; then
  echo "Aditya's Personal VPN"
else
  ss="ss://$(echo -n ${ENCRYPT}:${Password} | base64 -w 0)@${Domain}:443"
  echo "${ss}" | tr -d '\n' > /wwwroot/index.html
  echo -n "${ss}" | qrencode -s 6 -o /wwwroot/vpn.png
fi

echo "Starting ss-server on port 2333 without plugin:"
echo "ss-server -s 0.0.0.0 -p 2333 -k ${Password} -m ${ENCRYPT} -u &"

# Start Shadowsocks on port 2333 to avoid nginx port conflict
ss-server -s 0.0.0.0 -p 2333 -k "${Password}" -m ${ENCRYPT} -u &

# Remove default nginx site if exists
rm -rf /etc/nginx/sites-enabled/default

# Start nginx normally on port 443
nginx -g 'daemon off;'
