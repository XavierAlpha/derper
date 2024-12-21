FROM golang:alpine AS builder
LABEL org.opencontainers.image.authors="Camellia Corp."
WORKDIR /root
ADD third_party/tailscale /root/tailscale
RUN cd /root/tailscale/cmd/derper && \
    CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags "-s -w -buildid=" -o /root/derper && \
    cd /root && rm -rf /root/tailscale

FROM alpine:latest
WORKDIR /root
ENV DEV=false
ENV VERSION_FLAG=false
ENV ADDR=":443"
ENV HTTP_PORT=80
ENV STUN_PORT=3478
ENV CONFIG_PATH=""
ENV CERT_MODE="manual"
ENV CERT_DIR="derper-certs"
ENV HOSTNAME="127.0.0.1"
ENV RUN_STUN=true
ENV RUN_DERP=true
ENV MESH_PSKFILE=""
ENV MESH_WITH=""
ENV BOOTSTRAP_DNS=""
ENV UNPUBLISHED_DNS=""
ENV VERIFY_CLIENTS=true
ENV VERIFY_CLIENT_URL=""
ENV VERIFY_FAIL_OPEN=true
ENV ACCEPT_CONNECTION_LIMIT="+Inf"
ENV ACCEPT_CONNECTION_BURST=9223372036854775807
ENV TCP_KEEPALIVE_TIME="10m0s"
ENV TCP_USER_TIMEOUT="15s"
COPY --from=builder /root/derper /usr/local/bin/derper
COPY entrypoint.sh /entrypoint.sh
RUN apk update && apk add --no-cache openssl && chmod +x /entrypoint.sh 
EXPOSE 80
EXPOSE 3478/UDP
EXPOSE 443
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "sh", "-c", "derper --a=$ADDR --accept-connection-limit=$ACCEPT_CONNECTION_LIMIT --accept-connection-burst=$ACCEPT_CONNECTION_BURST --bootstrap-dns-names=$BOOTSTRAP_DNS --c=$CONFIG_PATH --certdir=$CERT_DIR --certmode=$CERT_MODE --derp=$RUN_DERP --dev=$DEV --hostname=$HOSTNAME --http-port=$HTTP_PORT --mesh-psk-file=$MESH_PSKFILE --mesh-with=$MESH_WITH --stun=$RUN_STUN --stun-port=$STUN_PORT --tcp-keepalive-time=$TCP_KEEPALIVE_TIME --tcp-user-timeout=$TCP_USER_TIMEOUT --unpublished-bootstrap-dns-names=$UNPUBLISHED_DNS  --verify-client-url=$VERIFY_CLIENT_URL --verify-client-url-fail-open=$VERIFY_FAIL_OPEN --verify-clients=$VERIFY_CLIENTS --version=$VERSION_FLAG" ]
