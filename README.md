# docker-koja

Docker images for the [Koja](https://github.com/koja-lang/koja) compiler toolchain.

The image contains the `koja` compiler, the `koja-lsp` language server, and the tools that `koja` invokes: `gcc`, `g++`, and `libc6-dev` for linking, `git` for `koja deps get`, and `ca-certificates`. The standard library is embedded in the compiler binary. Images install the prebuilt binaries from the matching [GitHub release](https://github.com/koja-lang/koja/releases), verified against pinned checksums.

## Supported tags

| Tag                        | Dockerfile   | Base                 |
| -------------------------- | ------------ | -------------------- |
| `0.16.0`, `0.16`, `latest` | [0.16](0.16) | `debian:trixie-slim` |

Images are published for `linux/amd64` and `linux/arm64` to two registries:

- Docker Hub: `kojalang/koja`
- GitHub Container Registry: `ghcr.io/koja-lang/koja`

Each maintained version keeps its Dockerfile in a `major.minor` directory. A push to `main` and a monthly schedule rebuild and republish every maintained version, so base image security fixes reach older tags too. The workflow can also run manually, as a dry run by default or with its `push` input set to publish.

## Quick start

Run a script from your working directory:

```console
docker run --rm -v "$PWD":/app kojalang/koja koja run script.kojs
```

Or open a shell inside a Koja project:

```console
docker run --rm -it -v "$PWD":/app kojalang/koja bash
koja deps get
koja test
```

## Deploying a compiled program

Koja compiles to a native binary that needs only glibc and libstdc++ at run time. Both are present in `debian:trixie-slim`. Use the toolchain image as a build stage and copy the binary into a plain base image:

```dockerfile
FROM kojalang/koja:0.16 AS build
WORKDIR /app
COPY . .
RUN koja deps get && koja build --release

FROM debian:trixie-slim
COPY --from=build /app/build/release/myapp /usr/local/bin/myapp
CMD ["myapp"]
```

## Using Koja in your own image

If you need a different base image, for example one with extra C libraries, copy the compiler out of this image instead of rebuilding it. The binary is self-contained. The base needs glibc 2.39 or newer.

```dockerfile
FROM your-base:tag
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates g++ gcc git libc6-dev \
    && rm -rf /var/lib/apt/lists/*
COPY --from=kojalang/koja:0.16.0 /usr/local/bin/koja /usr/local/bin/
```

The packages cover what `koja` invokes: `gcc`, `g++`, and `libc6-dev` for the link step, `git` for `koja deps get`, and `ca-certificates` for fetching dependencies over HTTPS.

## Why there is no Alpine variant

The release binaries link against glibc. An Alpine image needs musl builds of the compiler, which do not exist yet. This also rules out glibc bases older than 2.39, such as Debian bookworm.

## Tag policy

A version tag always installs that exact Koja version. Version tags are never re-pointed to a different Koja release. Tags can be rebuilt on an updated base image so that base security fixes reach users. The `latest` and minor tags (for example `0.16`) move forward with releases.

## Releasing a new version

1. Run `./update.sh <version>`. The script stamps `<major.minor>/Dockerfile` with the version and its release checksums, creating the directory from the newest existing one when needed.
2. Open a PR. Merging to `main` builds and publishes every maintained version, with `latest` pointing at the newest.
3. To drop support for a version, delete its directory. Published tags stay on the registries.

## License

Copyright (c) 2026 Henry Popp

This project is MIT licensed. See the [LICENSE](LICENSE) for details.
