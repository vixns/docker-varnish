FROM vixns/base
MAINTAINER Stéphane Cottin <stephane.cottin@vixns.com>

RUN \
  export DEBIAN_FRONTEND=noninteractive && \
  curl -k -s https://repo.varnish-cache.org/GPG-key.txt | apt-key add - && \
  apt-get update && apt-get install -y apt-transport-https && \
  echo "deb https://repo.varnish-cache.org/debian jessie varnish-4.1" >> /etc/apt/sources.list && \
  apt-get update && apt-get -y dist-upgrade && \
  apt-get -y install varnish && \
  rm -rf /var/lib/apt/lists/*

ENV VCL_CONFIG      /etc/varnish/default.vcl
ENV STORAGE_BACKEND malloc
ENV CACHE_SIZE      64m
ENV TELNET_PORT	    6082
ENV LISTEN_PORT	    6086
ENV VARNISHD_PARAMS -p default_ttl=3600 -p default_grace=3600

COPY start.sh /start.sh
CMD ["/start.sh"]
