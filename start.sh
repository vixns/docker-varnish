#!/bin/sh

set -e

cat > /etc/default/varnish << EOF
DAEMON_OPTS="-a :$LISTEN_PORT -T :$TELNET_PORT -f /etc/varnish/default.vcl -S /etc/varnish/secret -s $STORAGE_BACKEND,$CACHE_SIZE"
EOF

exec varnishd -F \
  -f $VCL_CONFIG \
   -S /etc/varnish/secret \
  -T :$TELNET_PORT \
  -a :$LISTEN_PORT \
  -s $STORAGE_BACKEND,$CACHE_SIZE \
  $VARNISHD_PARAMS

