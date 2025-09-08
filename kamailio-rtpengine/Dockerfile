ARG BUILD_FROM=ghcr.io/hassio-addons/base:14.8.1
FROM ${BUILD_FROM}

RUN apk add --no-cache \
  kamailio kamailio-tls kamailio-websocket kamailio-db kamailio-outbound \
  rtpengine gettext

COPY rootfs/ /

RUN chmod +x /etc/cont-init.d/00-export-env.sh \
    /etc/cont-init.d/10-init.sh \
    /etc/services.d/kamailio/run \
    /etc/services.d/rtpengine/run
