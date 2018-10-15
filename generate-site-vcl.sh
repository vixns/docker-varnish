#!/bin/bash

VARNISH_BACKEND_HOST=${VARNISH_BACKEND_HOST:-"backend"}
VARNISH_BACKEND_PORT=${VARNISH_BACKEND_PORT:-"80"}
VARNISH_PROBE_URL=${VARNISH_PROBE_URL:-"/ping"}

#############
# DEFAULTS #
#############

# The default backend and copy of beginning of the built-in vcl_recv
cat -  <<EOF

probe app_probe {
    .url = "$VARNISH_PROBE_URL";
}

backend default {
    .host = "localhost";
}

sub vcl_init {
  new app_dir = dynamic.director(
    port = "$VARNISH_BACKEND_PORT",
    host_header = "$VARNISH_BACKEND_HOST",
    probe = app_probe,
    ttl = 20s);
}

sub vcl_recv {
    if (req.method == "PRI") {
    /* We do not support SPDY or HTTP/2.0 */
    return (synth(405));
    }
    if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }

    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pass);
    }
}

sub vcl_backend_fetch {
  set bereq.backend = app_dir.backend("$VARNISH_BACKEND_HOST");
}

EOF



###############################
# CACHE/IGNORE AUTHORIZATION? #
###############################

if [ "$VARNISH_CACHE_AUTH" != "" ]; then
cat -  <<EOF
sub vcl_hash {
    if (req.http.Authorization) {
        hash_data(req.http.Authorization);
    }
}
EOF
elif [ "$VARNISH_IGNORE_AUTH" == "" ]; then
cat -  <<EOF
sub vcl_recv {
    if (req.http.Authorization) {
        return(pass);
    }
}
EOF
fi



########################
# CACHE/IGNORE COOKIE? #
########################

if [ "$VARNISH_CACHE_COOKIE" != "" ]; then
cat -  <<EOF
sub vcl_hash {
    if (req.http.Cookie) {
        hash_data(req.http.Cookie);
    }
}
EOF
elif [ "$VARNISH_IGNORE_COOKIE" != "" ]; then
cat -  <<EOF
sub vcl_recv {
    if (req.http.Cookie) {
        return(pass);
    }
}
EOF
fi


#############
# DEEFAULTS #
#############

# Skip the built-in configuration
cat -  <<EOF
sub vcl_recv {
    return(hash);
}
EOF

if [ "$VARNISH_DEFAULT_TTL" != "" ]; then
cat -  <<EOF
sub vcl_backend_response {
	set beresp.ttl = $VARNISH_DEFAULT_TTL;
}
EOF
fi
