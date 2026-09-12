FROM debian:trixie-slim

ENV KOJA_VERSION=0.18.4

LABEL org.opencontainers.image.authors="Henry Popp <hello@hpopp.dev>" \
      org.opencontainers.image.base.name="docker.io/library/debian:trixie-slim" \
      org.opencontainers.image.description="Koja compiler toolchain" \
      org.opencontainers.image.documentation="https://github.com/koja-lang/docker-koja#readme" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/koja-lang/docker-koja" \
      org.opencontainers.image.title="Koja" \
      org.opencontainers.image.url="https://hub.docker.com/r/kojalang/koja" \
      org.opencontainers.image.version="${KOJA_VERSION}"

# koja build shells out to cc and links -lstdc++ (BoringSSL's libssl
# is C++), koja deps get shells out to git. libstdc++-14-dev covers
# the -lstdc++ link without pulling in the g++ compiler.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gcc \
        git \
        libc6-dev \
        libstdc++-14-dev \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl; \
    case "$TARGETARCH" in \
        amd64) target="linux-x86_64"; sha256="5b5d8f95322e79dcf3d5c72c32f287d038290d0b264e7add17cc70059c78e722" ;; \
        arm64) target="linux-arm64"; sha256="c2eb6cc0d5077991a0376e9a3f953ae38b7dec701b649334b830baa893f3a7c1" ;; \
        *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    name="koja-v${KOJA_VERSION}-${target}"; \
    curl -fsSLO "https://github.com/koja-lang/koja/releases/download/v${KOJA_VERSION}/${name}.tar.gz"; \
    echo "${sha256}  ${name}.tar.gz" | sha256sum -c -; \
    tar -xzf "${name}.tar.gz"; \
    mv "${name}/koja" "${name}/koja-lsp" /usr/local/bin/; \
    rm -rf "${name}" "${name}.tar.gz"; \
    apt-get purge -y --auto-remove curl; \
    rm -rf /var/lib/apt/lists/*

# Smoke test: koja run exercises the embedded stdlib, koja build
# exercises the cc link path.
RUN set -eux; \
    echo 'IO.puts("hello from koja")' > /tmp/smoke.kojs; \
    [ "$(koja run /tmp/smoke.kojs)" = "hello from koja" ]; \
    koja build -o /tmp/smoke /tmp/smoke.kojs; \
    [ "$(/tmp/smoke)" = "hello from koja" ]; \
    rm -f /tmp/smoke /tmp/smoke.kojs

WORKDIR /app
CMD ["koja"]
