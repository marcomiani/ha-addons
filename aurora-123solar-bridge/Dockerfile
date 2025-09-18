ARG BUILD_FROM
FROM $BUILD_FROM

# curl + jq + mosquitto_pub
RUN apk add --no-cache bash curl jq mosquitto-clients tzdata

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
