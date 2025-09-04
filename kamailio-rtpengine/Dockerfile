FROM ghcr.io/hassio-addons/base:18.1

# pacchetti necessari (Alpine)
RUN apk add --no-cache \
  kamailio kamailio-tls kamailio-websocket kamailio-db \
  rtpengine gettext

# copia rootfs
COPY rootfs/ /

# permessi eseguibili
RUN chmod +x /etc/cont-init.d/00-export-env.sh \
    /etc/cont-init.d/10-init.sh \
    /etc/services.d/kamailio/run \
    /etc/services.d/rtpengine/run
