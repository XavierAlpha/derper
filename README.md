# Derp

- 若使用 letencry
```sh
# test
# run
docker run --rm -it derper /bin/sh
```

```sh
docker run --restart=always \
-name derper -p 443:443 -p 3478:3478/udp \
-e CERTMODE=manual \
-e ADDR=:443 \
-e STUN_PORT=3478 \
-e VERIFY_CLIENTS=true \
-v /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock \
-d ghcr.io/xavieralpha/derper:latest
```

```yml
# docker compose
services:
  derper:
    image: ghcr.io/xavieralpha/derper
    container_name: derper
    restart: always
    environment:
      - CERTMODE=manual
      - ADDR=:443
      - STUN_PORT=3478
      - VERIFY_CLIENTS=true
    ports:
      - "443:443"
      - "3478:3478/udp"
    volumes:
      - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock
```