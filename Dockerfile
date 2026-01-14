# Multi-stage Dockerfile for BIRD Internet Routing Daemon
# https://bird.network.cz/

# =============================================================================
# Build stage
# =============================================================================
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    flex \
    bison \
    m4 \
    ncurses-dev \
    libreadline-dev \
    libssh-gcrypt-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY . .

RUN autoreconf && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc/bird \
        --runstatedir=/run/bird \
        --enable-libssh && \
    make -j$(nproc)

# =============================================================================
# Runtime stage
# =============================================================================
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libreadline8 \
    libncurses6 \
    libssh-gcrypt-4 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/bird /run/bird

COPY --from=builder /build/bird /usr/sbin/bird
COPY --from=builder /build/birdc /usr/sbin/birdc
COPY --from=builder /build/birdcl /usr/sbin/birdcl

COPY bird.conf /etc/bird/bird.conf

EXPOSE 179

VOLUME ["/etc/bird", "/run/bird"]

ENTRYPOINT ["/usr/sbin/bird"]
CMD ["-f", "-c", "/etc/bird/bird.conf", "-s", "/run/bird/bird.ctl"]
