#!/usr/bin/env bash
# Stamp a version directory from a Koja release.
#
#   ./update.sh 0.17.0
#
# Creates or refreshes <major.minor>/Dockerfile with the version and
# the sha256 checksums fetched from the GitHub release. New
# directories copy the newest existing Dockerfile as their template.
# The README tag table follows: a known minor gets its patch version
# swapped, a new minor gets a new top row that takes over latest and
# the build stage example. Prettier realigns the table when installed.

set -euo pipefail

fail() {
  echo "update.sh: $*" >&2
  exit 1
}

version="${1:?usage: ./update.sh <version>}"
version="${version#v}"
dir="${version%.*}"
base="https://github.com/koja-lang/koja/releases/download/v${version}"

fetch_sha() {
  curl -fsSL "$base/koja-v${version}-$1.tar.gz.sha256" | awk '{print $1}' ||
    fail "could not fetch the $1 checksum for v$version (does the release exist?)"
}

sha_amd64="$(fetch_sha linux-x86_64)"
sha_arm64="$(fetch_sha linux-arm64)"
[ -n "$sha_amd64" ] && [ -n "$sha_arm64" ] || fail "empty checksum for v$version"

if [ ! -f "$dir/Dockerfile" ]; then
  template="$(find . -maxdepth 2 -name Dockerfile -path './[0-9]*' | sort -t/ -k2 -V | tail -n 1)"
  [ -n "$template" ] || fail "no existing version directory to use as a template"
  mkdir -p "$dir"
  cp "$template" "$dir/Dockerfile"
  echo "created $dir/ from $template"
fi

sed -E -i.bak \
  -e "s|^ENV KOJA_VERSION=.*|ENV KOJA_VERSION=${version}|" \
  -e "s|(amd64\) target=\"linux-x86_64\"; sha256=)\"[^\"]*\"|\1\"${sha_amd64}\"|" \
  -e "s|(arm64\) target=\"linux-arm64\"; sha256=)\"[^\"]*\"|\1\"${sha_arm64}\"|" \
  "$dir/Dockerfile"
rm -f "$dir/Dockerfile.bak"

echo "stamped $dir/Dockerfile for koja $version"

readme="README.md"
dir_re="${dir//./\\.}"

if grep -Fq "| [$dir]($dir) |" "$readme"; then
  sed -E -i.bak \
    -e "s#^\| \`[0-9]+\.[0-9]+\.[0-9]+\`(.*\| \[${dir_re}\]\(${dir_re}\) \|)#| \`${version}\`\1#" \
    "$readme"
  rm -f "$readme.bak"
  echo "updated the $dir row in $readme"
else
  base_image="$(sed -n 's/^FROM \(.*\)$/\1/p' "$dir/Dockerfile" | head -n 1)"
  [ -n "$base_image" ] || fail "could not read the base image from $dir/Dockerfile"
  row="| \`${version}\`, \`${dir}\`, \`latest\` | [${dir}](${dir}) | \`${base_image}\` |"
  # The new row goes under the header separator. The old newest row
  # loses the latest tag and the build stage example moves to the new
  # minor.
  awk -v row="$row" '
    /^\| -+ \|/ && !inserted { print; print row; inserted = 1; next }
    /^\| `/ { sub(/, `latest`/, "") }
    { print }
  ' "$readme" > "$readme.tmp"
  mv "$readme.tmp" "$readme"
  sed -E -i.bak \
    -e "s#^FROM kojalang/koja:[0-9]+\.[0-9]+ AS build#FROM kojalang/koja:${dir} AS build#" \
    "$readme"
  rm -f "$readme.bak"
  echo "added the $dir row to $readme"
fi

if command -v prettier >/dev/null 2>&1; then
  prettier --log-level warn --write "$readme"
else
  echo "update.sh: prettier not found, $readme table alignment not refreshed" >&2
fi
