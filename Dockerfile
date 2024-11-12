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
ENV VERSION=false
ENV ADDR=":443"
ENV HTTP_PORT=80
ENV STUN_PORT=3478
ENV CONFIG=""
ENV CERTMODE="manual"
ENV CERTDIR="derper-certs"
ENV HOSTNAME="127.0.0.1"
ENV RUNSTUN=true
ENV RUNDERP=true
ENV VERIFY_CLIENTS=true
ENV VERIFY_CLIENT_URL=""
ENV VERIFY_CLIENT_URL_FAIL_OPEN=true
ENV TCP_KEEPALIVE_TIME="10m0s"
ENV TCP_USER_TIMEOUT="15s"
COPY --from=builder /root/derper /usr/local/bin/derper
COPY entrypoint.sh /entrypoint.sh
RUN apk update && apk add --no-cache openssl && chmod +x /entrypoint.sh 
EXPOSE 80
EXPOSE 3478/UDP
EXPOSE 443
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "derper", \
    "--a=$ADDR", \
    "--c=$CONFIG", \
    "--certdir=$CERTDIR", \
    "--hostname=$HOSTNAME", \
    "--certmode=$CERTMODE", \
    "--derp=$RUNDERP", \
    "--dev=$DEV", \
    "--http-port=$HTTP_PORT", \
    "--stun=$RUNSTUN", \
    "--stun-port=$STUN_PORT", \
    "--tcp-keepalive-time=$TCP_KEEPALIVE_TIME", \
    "--tcp-user-timeout=$TCP_USER_TIMEOUT", \
    "--verify-client-url=$VERIFY_CLIENT_URL", \
    "--verify-client-url-faile-open=$VERIFY_CLIENT_URL_FAIL_OPEN", \
    "--verify-clients=$VERIFY_CLIENTS", \
    "--version=$VERSION" \
    ]
