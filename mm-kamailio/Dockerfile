ARG BUILD_FROM
FROM $BUILD_FROM

# Install Kamailio core + required modules
# kamailio          : core (sl, tm, rr, textops, siputils, maxfwd, sanity, pv, corex, ctl)
# kamailio-tls      : TLS transport
# kamailio-websocket: WebSocket / WSS support + xhttp
# kamailio-extras   : nathelper, htable, tmx, rtpengine.so and other extras
# kamailio-db       : usrloc, registrar, and other database-capable modules (db_mode=0 = memory-only)
# kamailio-utils    : additional utilities
# rtpengine         : RTP/media relay daemon (NAT traversal + WebRTC↔RTP bridging)
# iproute2          : ip(8) command used in run.sh to detect local IP
RUN apk add --no-cache \
    kamailio \
    kamailio-tls \
    kamailio-websocket \
    kamailio-extras \
    kamailio-db \
    kamailio-utils \
    rtpengine \
    iproute2

RUN mkdir -p /etc/kamailio

COPY run.sh /run.sh
COPY kamailio.cfg.template /etc/kamailio/kamailio.cfg.template
COPY tls.cfg.template      /etc/kamailio/tls.cfg.template

RUN chmod +x /run.sh

CMD ["/run.sh"]
