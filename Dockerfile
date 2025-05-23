FROM golang:alpine AS builder
LABEL org.opencontainers.image.authors="Camellia Corp."
WORKDIR /root
COPY . /root/
SHELL ["/bin/sh","-euxc"]
RUN \
  apk update && apk add --no-cache git && \
  cd /root/third_party/tailscale && \
  eval "$(CGO_ENABLED=0 \
           GOOS=$(go env GOHOSTOS) \
           GOARCH=$(go env GOHOSTARCH) \
           go run ./cmd/mkversion --export)" && \
  default_tags="ts_cmd_derper,v${VERSION_SHORT},v${VERSION_MINOR}" && \
  tags="${tags:-${default_tags}}" && \
  ldflags="\
    -X tailscale.com/version.shortStamp=${VERSION_SHORT} \
    -X tailscale.com/version.longStamp=${VERSION_LONG} \
    -X tailscale.com/version.gitCommitStamp=${VERSION_GIT_HASH}" && \
  cd cmd/derper && \
  CGO_ENABLED=0 GOOS=$(go env GOHOSTOS) GOARCH=$(go env GOHOSTARCH) \
  go build -trimpath -buildvcs=true \
    -tags="$tags" \
    -ldflags="$ldflags -s -w" \
    -o /root/derper .

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
ENV FLAGHOME=""
ENV MESH_PSKFILE=""
ENV MESH_WITH=""
ENV SECRETS_URL=""
ENV SECRETS_PREFIX="prod/derp"
ENV SECRETS_CACHEDIR="derper-secrets"
ENV BOOTSTRAP_DNS=""
ENV UNPUBLISHED_DNS=""
ENV VERIFY_CLIENTS=true
ENV VERIFY_CLIENT_URL=""
ENV VERIFY_FAIL_OPEN=true
ENV SOCKET=""
ENV ACCEPT_CONNECTION_LIMIT="+Inf"
ENV ACCEPT_CONNECTION_BURST=9223372036854775807
ENV TCP_KEEPALIVE_TIME="10m0s"
ENV TCP_USER_TIMEOUT="15s"
ENV TCP_WRITE_TIMEOUT="2s"
COPY --from=builder /root/derper /usr/local/bin/derper
COPY entrypoint.sh /entrypoint.sh
RUN apk update && apk add --no-cache openssl && chmod +x /entrypoint.sh 
EXPOSE 80
EXPOSE 3478/UDP
EXPOSE 443
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "sh", "-c", "derper --a=$ADDR --accept-connection-limit=$ACCEPT_CONNECTION_LIMIT --accept-connection-burst=$ACCEPT_CONNECTION_BURST --bootstrap-dns-names=$BOOTSTRAP_DNS --c=$CONFIG_PATH --certdir=$CERT_DIR --certmode=$CERT_MODE --derp=$RUN_DERP --dev=$DEV --home=$FLAGHOME --hostname=$HOSTNAME --http-port=$HTTP_PORT --mesh-psk-file=$MESH_PSKFILE --mesh-with=$MESH_WITH --secrets-cache-dir=$SECRETS_CACHEDIR --secrets-path-prefix=$SECRETS_PREFIX --secrets-url=$SECRETS_URL --socket=$SOCKET --stun=$RUN_STUN --stun-port=$STUN_PORT --tcp-keepalive-time=$TCP_KEEPALIVE_TIME --tcp-user-timeout=$TCP_USER_TIMEOUT --tcp-write-timeout=$TCP_WRITE_TIMEOUT --unpublished-bootstrap-dns-names=$UNPUBLISHED_DNS  --verify-client-url=$VERIFY_CLIENT_URL --verify-client-url-fail-open=$VERIFY_FAIL_OPEN --verify-clients=$VERIFY_CLIENTS --version=$VERSION_FLAG" ]
