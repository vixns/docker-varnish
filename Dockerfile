FROM debian:stretch

# INSTALL
RUN apt-get update && \
    apt-get install -y curl gnupg apt-transport-https && \
    curl -L https://packagecloud.io/varnishcache/varnish60lts/gpgkey | apt-key add - && \
    echo "deb https://packagecloud.io/varnishcache/varnish60lts/debian/ stretch main" > /etc/apt/sources.list.d/varnishcache_varnish60lts.list && \
    apt-get update && \
    apt-get install -y \
    varnish \
    git \
    gettext-base \
    libcap2-bin \
    vim \
    procps \
    htop

# Compile and install varnish vmod 'urlcode'.
RUN apt-get install -y \
    wget \
    dpkg-dev \
    varnish-dev \
    libtool \
    m4 \
    automake \
    pkg-config \
    docutils-common 
RUN cd /tmp \
    && mkdir urlcode \
    && cd urlcode \
    && wget https://github.com/fastly/libvmod-urlcode/archive/master.tar.gz \
    && tar -xf master.tar.gz \
    && cd libvmod-urlcode-master \
    && sh autogen.sh \
    && ./configure \
    && sed -i -e "/#include \"vrt.h\"/d" src/vmod_urlcode.c \
    && make \
    && make install \
    && make check
RUN cd /tmp \
    && git clone https://github.com/nigoroll/libvmod-dynamic.git -b 6.0 \
    && cd libvmod-dynamic \
    && ./autogen.sh \
    && ./configure \
    && make install \
    && cd /tmp \
    && rm -rf /tmp/libvmod-dynamic libvmod-urlcode-master
RUN cd /tmp \
    && git clone https://github.com/varnish/varnish-modules.git \
    && cd varnish-modules \
    && ./bootstrap && ./configure && make && make install \
    && cd /tmp && rm -rf varnish-modules
RUN apt-get remove


# BUILD-TIME ENVIRONMENT VARIABLES
ENV FILE_DEFAULT_VCL "/etc/varnish/default.vcl"
ENV FILE_SITE_VCL "/etc/varnish/site.vcl"
ENV PATH_VAR_VARNISH "/var/lib/varnish"
ENV FILE_GENERATE_SITE_VCL_SH "/etc/varnish/generate-site-vcl.sh"
ENV RUN_VARNISH "/run-varnish.sh"
ENV EXEC_VARNISH "exec $RUN_VARNISH"

# RUN-TIME ENVIRONMENT VARIABLES
ENV VARNISH_CACHE_COOKIE= VARNISH_IGNORE_COOKIE= VARNISH_CACHE_AUTH= VARNISH_IGNORE_AUTH= VARNISH_DEFAULT_TTL=

# Copy files
COPY default.vcl "$FILE_DEFAULT_VCL"
COPY generate-site-vcl.sh "$FILE_GENERATE_SITE_VCL_SH"

# PERMISSIONS: PORTS
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/varnishd

# PERMISSIONS: FILES and FOLDERS
RUN D="$PATH_VAR_VARNISH"  && mkdir -p "$D" && chgrp -R root "$D" && chmod g=u -R "$D"
RUN F="$FILE_SITE_VCL"     && D="$(dirname "$F")" && mkdir -p "$D" && chmod g=u "$D" && touch "$F"  && chmod g=u "$F" && \
    F="$FILE_DEFAULT_VCL"  && D="$(dirname "$F")" && mkdir -p "$D" && chmod g=u "$D" && touch "$F"  && chmod g=u "$F"

COPY run "$RUN_VARNISH"
RUN chmod ug+x "$RUN_VARNISH"

ENTRYPOINT [ "/run-varnish.sh" ]
