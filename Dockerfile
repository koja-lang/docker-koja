FROM debian:trixie-slim

LABEL org.opencontainers.image.source="https://github.com/koja-lang/docker-koja" \
      org.opencontainers.image.description="Koja compiler toolchain" \
      org.opencontainers.image.licenses="MIT"

# koja build shells out to cc and links -lstdc++ (BoringSSL's libssl
# is C++), koja deps get shells out to git. g++ provides the
# libstdc++ dev files.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        g++ \
        gcc \
        git \
        libc6-dev \
    && rm -rf /var/lib/apt/lists/*

ARG KOJA_VERSION=0.16.0
ARG KOJA_SHA256_AMD64=2947209065f9badcea58ddd326ccbaf74dc3ac4a259f3cb809a2a3a6ce06ac89
ARG KOJA_SHA256_ARM64=2488f3e60810e23fbf84cca44acb41891c4f4c9345fe4e5e032f94b632c1472c
ARG TARGETARCH

ENV KOJA_VERSION=$KOJA_VERSION

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl; \
    case "$TARGETARCH" in \
        amd64) target="linux-x86_64"; sha256="$KOJA_SHA256_AMD64" ;; \
        arm64) target="linux-arm64"; sha256="$KOJA_SHA256_ARM64" ;; \
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
