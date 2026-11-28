# syntax=docker/dockerfile:1
# Production multi-stage container image for the optional `rslbp-serve` web service (R51).
# Build locally with `just docker-web` (or `docker build -t rslbp-web:dev .`).
# Ready for GHCR container publishing on stable releases (owner review-gate 1a-A OVERRIDE of R51, P11).

ARG PROBE_IMAGE=busybox:1.38.0-musl@sha256:80e38f9a1b39188b8bdb28879178edb322a4402b081a9aedda1924609decd6f6
ARG RUST_IMAGE=rust:1.100.0-slim-trixie@sha256:3b199fd6db7d709274df56565b8f4003f9e30d7bfcff9d53148c86053b7855e2
ARG RUNTIME_IMAGE=gcr.io/distroless/cc-debian13:nonroot@sha256:29ee70762214fe8190cea04ef1c0a84a8365879e047ce8f911ae5a5ab2355fa2

FROM ${PROBE_IMAGE} AS probe

FROM ${RUST_IMAGE} AS builder
ARG CARGO_FEATURES=web
WORKDIR /src
ENV CARGO_TERM_COLOR=never \
    CARGO_INCREMENTAL=0 \
    RUSTUP_TOOLCHAIN=1.100.0
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,target=/src/target,sharing=locked \
    cargo build --release --locked --features "${CARGO_FEATURES}" --bin rslbp-serve \
 && install -D -m 0755 target/release/rslbp-serve /out/rslbp-serve

FROM ${RUNTIME_IMAGE}
LABEL org.opencontainers.image.source="https://github.com/smorinlabs/rs-launch-blueprint" \
      org.opencontainers.image.description="Optional HTTP API service for rs-launch-blueprint" \
      org.opencontainers.image.licenses="MIT OR Apache-2.0"
COPY --from=probe /bin/busybox /bin/busybox
COPY --from=builder /out/rslbp-serve /usr/local/bin/rslbp-serve
# Containers bind all interfaces; the in-code default stays loopback (R77).
# RSLBP_WEB_PORT is intentionally omitted so R77's in-code default (8000) stays the single source of truth.
ENV RSLBP_WEB_HOST=0.0.0.0
EXPOSE 8000
USER nonroot:nonroot
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/bin/busybox", "wget", "--spider", "-q", "-T", "2", "http://127.0.0.1:8000/healthz"]
ENTRYPOINT ["/usr/local/bin/rslbp-serve"]
