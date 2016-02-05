#!/bin/sh

set -e

exec varnishd -F \
  -f $VCL_CONFIG \
  -T 0.0.0.0:$TELNET_PORT \
  -a 0.0.0.0:$LISTEN_PORT \
  -s $STORAGE_BACKEND,$CACHE_SIZE \
  $VARNISHD_PARAMS

