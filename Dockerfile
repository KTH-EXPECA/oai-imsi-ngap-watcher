# Use a small base with awk/grep and docker CLI available
FROM alpine:3.20

RUN apk add --no-cache bash coreutils grep gawk docker-cli

ENV AMF_CONTAINER=oai-amf
ENV INTERVAL_SEC=1
ENV OUTPUT_FILE=/tmp/ngap_imsi_map.log

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
