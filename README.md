# DERP in Docker

## How To Use
> Image Source: camllia/derper:latest OR ghcr.io/xavieralpha/derper:latest


```sh
# install tailscale if VERIFY_CLIENTS=true; otherwise, ignore it.
curl -fsSL https://tailscale.com/install.sh | sh

# if /bin/sh
docker pull camllia/derper:latest
docker run --rm -it camllia/derper /bin/sh
```

### DERP Server Environment Variables and Parameter Comparison Table

This table provides a detailed comparison and command-line parameters for the `derper` server, making it easier to configure and understand each feature.

| **Environment Variable**   | **derper Command Parameter**             | **Default Value**                     |
|----------------------------|------------------------------------------|---------------------------------------|
| DEV                        | `-dev`                                   | `false`                               |
| VERSION_FLAG               | `-version`                               | `false`                               |
| ADDR                       | `-a`                                     | `:443`                                |
| HTTP_PORT                  | `-http-port`                             | `80`                                  |
| STUN_PORT                  | `-stun-port`                             | `3478`                                |
| CONFIG_PATH                | `-c`                                     | `""`                                  |
| CERT_MODE                  | `-certmode`                              | `manual`                              |
| CERT_DIR                   | `-certdir`                               | `derper-certs`                        |
| HOSTNAME                   | `-hostname`                              | `127.0.0.1`                           |
| RUN_STUN                   | `-stun`                                  | `true`                                |
| RUN_DERP                   | `-derp`                                  | `true`                                |
| FLAGHOME                   | `-home`                                  | `""`                                  |
| MESH_PSKFILE               | `-mesh-psk-file`                         | `""`                                  |
| MESH_WITH                  | `-mesh-with`                             | `""`                                  |
| SECRETS_URL                | `-secrets-url`                           | `""`                                  |
| SECRET_PREFIX              | `-secrets-path-prefix`                   | `prod/derp`                           |
| SECRETS_CACHEDIR           | `-secrets-cache-dir`                     | `derper-secrets`                      |
| BOOTSTRAP_DNS              | `-bootstrap-dns-names`                   | `""`                                  |
| UNPUBLISHED_DNS            | `-unpublished-bootstrap-dns-names`       | `""`                                  |
| VERIFY_CLIENTS             | `-verify-clients`                        | `true`                                |
| VERIFY_CLIENT_URL          | `-verify-client-url`                     | `""`                                  |
| VERIFY_FAIL_OPEN           | `-verify-client-url-fail-open`           | `true`                                |
| SOCKET                     | `-socket`                                | `""`                                  |
| ACCEPT_CONNECTION_LIMIT    | `-accept-connection-limit`               | `+Inf`                                |
| ACCEPT_CONNECTION_BURST    | `-accept-connection-burst`               | `9223372036854775807`                 |
| TCP_KEEPALIVE_TIME         | `-tcp-keepalive-time`                    | `10m0s`                               |
| TCP_USER_TIMEOUT           | `-tcp-user-timeout`                      | `15s`                                 |
| TCP_WRITE_TIMEOUT          | `-tcp-write-timeout`                     | `2s`                                  |

### RUN DERPER
```sh
# avoid SNI checks: Make sure certmode=manual and hostname is ip
docker run --restart=unless-stopped \
--name derper \
# -p 80:80 -p 443:443 -p 3478:3478/udp \
# -e CERT_MODE=manual \
# -e HOSTNAME=127.0.0.1 \
# -e ADDR=:443 \
# -e STUN_PORT=3478 \
# -e VERIFY_CLIENTS=true \
# -e CERT_DIR=derper-certs \
-v "$(pwd)"/derper-certs/:/root/derper-certs/ \
-v /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock \
-d camllia/derper:latest
# '-v /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock' Not necessary if VERIFY_CLIENTS=false
```

```yml
# avoid SNI checks: Make sure certmode=manual and hostname is ip
services:
  derper:
    image: camllia/derper
    container_name: derper
    restart: unless-stopped
    environment:
    #   - CERT_DIR=derper-certs   # default
    #   - CERT_MODE=manual        # default
    #   - HOSTNAME=127.0.0.1      # default
    #   - ADDR=:443               # default
    #   - STUN_PORT=3478          # default
    #   - VERIFY_CLIENTS=true     # default
    ports:
      - "80:80"
      - "443:443"
      - "3478:3478/udp"
    volumes:
      - ./derper-certs/:/root/derper-certs/ # Match env "CERT_DIR"
      - /var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock # Not necessary if VERIFY_CLIENTS=false
```

> ~~**THEN** Run `docker logs derper`, copy the displayed "CertName":"sha256-raw:xxx...xxx", and add it to the `Nodes` section within the `derpMap` in ACL policy.~~
> 
> **NOTICE**: It is not yet available. You still need to set `"InsecureForTests": true` in the `Nodes` section of the `derpMap` within the ACL policy if you are **using a self-signed certificate**.
>

### Custom tailscaled socket path (When VERIFY_CLIENTS=true)
If `-socket=""`, the system will search for the socket based on the default location defined by the operating system.

> FROM [DefaultTailscaledSocket in tailscale.](https://github.com/tailscale/tailscale/blob/e80d2b4ad1e427c7700264a05d4bc8a6d95e29d7/paths/paths.go#L23)
```go
// DefaultTailscaledSocket returns the path to the tailscaled Unix socket
// or the empty string if there's no reasonable default.
func DefaultTailscaledSocket() string {
	if runtime.GOOS == "windows" {
		return `\\.\pipe\ProtectedPrefix\Administrators\Tailscale\tailscaled`
	}
	if runtime.GOOS == "darwin" {
		return "/var/run/tailscaled.socket"
	}
	if runtime.GOOS == "plan9" {
		return "/srv/tailscaled.sock"
	}
	switch distro.Get() {
	case distro.Synology:
		if distro.DSMVersion() == 6 {
			return "/var/packages/Tailscale/etc/tailscaled.sock"
		}
		// DSM 7 (and higher? or failure to detect.)
		return "/var/packages/Tailscale/var/tailscaled.sock"
	case distro.Gokrazy:
		return "/perm/tailscaled/tailscaled.sock"
	case distro.QNAP:
		return "/tmp/tailscale/tailscaled.sock"
	}
	if fi, err := os.Stat("/var/run"); err == nil && fi.IsDir() {
		return "/var/run/tailscale/tailscaled.sock"
	}
	return "tailscaled.sock"
}
```
Otherwise, the `SOCKET` environment variable needs to be set manually in docker.

# DERP
> This section is from Tailscale's README file.
>
> BSD 3-Clause License
> 
> Copyright (c) 2020 Tailscale Inc & AUTHORS.

This is the code for the [Tailscale DERP server](https://tailscale.com/kb/1232/derp-servers).

In general, you should not need to or want to run this code. The overwhelming
majority of Tailscale users (both individuals and companies) do not.

In the happy path, Tailscale establishes direct connections between peers and
data plane traffic flows directly between them, without using DERP for more than
acting as a low bandwidth side channel to bootstrap the NAT traversal. If you
find yourself wanting DERP for more bandwidth, the real problem is usually the
network configuration of your Tailscale node(s), making sure that Tailscale can
get direction connections via some mechanism.

If you've decided or been advised to run your own `derper`, then read on.

## Caveats

* Node sharing and other cross-Tailnet features don't work when using custom
  DERP servers.

* DERP servers only see encrypted WireGuard packets and thus are not useful for
  network-level debugging.

* The Tailscale control plane does certain geo-level steering features and
  optimizations that are not available when using custom DERP servers.

## Guide to running `cmd/derper`

* You must build and update the `cmd/derper` binary yourself. There are no
  packages. Use `go install tailscale.com/cmd/derper@latest` with the latest
  version of Go. You should update this binary approximately as regularly as
  you update Tailscale nodes. If using `--verify-clients`, the `derper` binary
  and `tailscaled` binary on the machine must be built from the same git revision.
  (It might work otherwise, but they're developed and only tested together.)

* The DERP protocol does a protocol switch inside TLS from HTTP to a custom
  bidirectional binary protocol. It is thus incompatible with many HTTP proxies.
  Do not put `derper` behind another HTTP proxy.

* The `tailscaled` client does its own selection of the fastest/nearest DERP
  server based on latency measurements. Do not put `derper` behind a global load
  balancer.

* DERP servers should ideally have both a static IPv4 and static IPv6 address.
Both of those should be listed in the DERP map so the client doesn't need to
rely on its DNS which might be broken and dependent on DERP to get back up.

* A DERP server should not share an IP address with any other DERP server.

* Avoid having multiple DERP nodes in a region. If you must, they all need to be
  meshed with each other and monitored. Having two one-node "regions" in the
  same datacenter is usually easier and more reliable than meshing, at the cost
  of more required connections from clients in some cases. If your clients
  aren't mobile (battery constrained), one node regions are definitely
  preferred. If you really need multiple nodes in a region for HA reasons, two
  is sufficient.

* Monitor your DERP servers with [`cmd/derpprobe`](../derpprobe/).

* If using `--verify-clients`, a `tailscaled` must be running alongside the
  `derper`, and all clients must be visible to the derper tailscaled in the ACL.

* If using `--verify-clients`, a `tailscaled` must also be running alongside
  your `derpprobe`, and `derpprobe` needs to use `--derp-map=local`.

* The firewall on the `derper` should permit TCP ports 80 and 443 and UDP port
  3478.

* Only LetsEncrypt certs are rotated automatically. Other cert updates require a
  restart.

* Don't use a firewall in front of `derper` that suppresses `RST`s upon
  receiving traffic to a dead or unknown connection.

* Don't rate-limit UDP STUN packets.

* Don't rate-limit outbound TCP traffic (only inbound).

## Diagnostics

This is not a complete guide on DERP diagnostics.

Running your own DERP services requires exeprtise in multi-layer network and
application diagnostics. As the DERP runs multiple protocols at multiple layers
and is not a regular HTTP(s) server you will need expertise in correlative
analysis to diagnose the most tricky problems. There is no "plain text" or
"open" mode of operation for DERP.

* The debug handler is accessible at URL path `/debug/`. It is only accessible
  over localhost or from a Tailscale IP address.

* Go pprof can be accessed via the debug handler at `/debug/pprof/`

* Prometheus compatible metrics can be gathered from the debug handler at
  `/debug/varz`.

* `cmd/stunc` in the Tailscale repository provides a basic tool for diagnosing
  issues with STUN.

* `cmd/derpprobe` provides a service for monitoring DERP cluster health.

* `tailscale debug derp` and `tailscale netcheck` provide additional client
  driven diagnostic information for DERP communications.

* Tailscale logs may provide insight for certain problems, such as if DERPs are
  unreachable or peers are regularly not reachable in their DERP home regions.
  There are many possible misconfiguration causes for these problems, but
  regular log entries are a good first indicator that there is a problem.
