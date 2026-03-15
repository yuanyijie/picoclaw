# ============================================================
# Stage 1: Build the picoclaw binary
# ============================================================
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git make

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN make build

# ============================================================
# Stage 2: Extend AIO Sandbox image with picoclaw
# ============================================================
FROM registry.cn-shanghai.aliyuncs.com/fc-demo2/custom-container-repository:sandbox-all-in-one-extend_v0.8.33

LABEL layer="picoclaw-extension"
LABEL description="PicoClaw AI agent extension based on All-in-One Extend"

USER root

# Copy picoclaw binary
COPY --from=builder /src/build/picoclaw /usr/local/bin/picoclaw
RUN chmod +x /usr/local/bin/picoclaw

# First-run setup: create default config and workspace
RUN /usr/local/bin/picoclaw onboard

# Process Compose config — auto-discovered by entrypoint.sh
COPY docker/config/process-compose.picoclaw.yaml /etc/sandbox/config/process-compose.picoclaw.yaml

# Nginx configs — auto-discovered by entrypoint.sh
RUN mkdir -p /etc/sandbox/config/nginx/http.d /etc/sandbox/config/nginx/conf.d
COPY docker/config/nginx-picoclaw-upstream.conf /etc/sandbox/config/nginx/http.d/picoclaw-upstream.conf
COPY docker/config/nginx-picoclaw-routes.conf   /etc/sandbox/config/nginx/conf.d/picoclaw-routes.conf

ENV PICOCLAW_GATEWAY_HOST=0.0.0.0 \
    PICOCLAW_GATEWAY_PORT=18790
