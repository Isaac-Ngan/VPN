#!/bin/bash

if [[ -z "${Password}" ]]; then
  Password="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
ENCRYPT="chacha20-ietf-poly1305"
QR_Path="/qr"

# V2Ray Configuration
V2_Path="/v2"
mkdir /wwwroot
mv /v2 /usr/bin/v2

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

sed -e "/^#/d" \
    -e "s/\${PORT}/${PORT}/g" \
    -e "s|\${V2_Path}|${V2_Path}|g" \
    -e "s|\${QR_Path}|${QR_Path}|g" \
    -e "$s" \
    /conf/nginx_ss.conf > /etc/nginx/conf.d/ss.conf 

if [ "${Domain}" = "no" ]; then
  echo "Aditya's Personal VPN"
else
  # skip plugin string generation to avoid confusion for now
  ss="ss://$(echo -n ${ENCRYPT}:${Password} | base64 -w 0)@${Domain}:443"
  echo "${ss}" | tr -d '\n' > /wwwroot/index.html
  echo -n "${ss}" | qrencode -s 6 -o /wwwroot/vpn.png
fi

echo "Starting ss-server without plugin:"
echo "ss-server -s 0.0.0.0 -p 2333 -k ${Password} -m ${ENCRYPT} -u &"

ss-server -s 0.0.0.0 -p 2333 -k "${Password}" -m ${ENCRYPT} -u &

rm -rf /etc/nginx/sites-enabled/default
nginx -g 'daemon off;'
