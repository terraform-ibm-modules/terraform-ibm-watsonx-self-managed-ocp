#!/bin/bash

# Installs required CLI binaries into the provided directory (defaults to /tmp).
set -o errexit
set -o pipefail

DIRECTORY=${1:-"/tmp"}
export PATH=$PATH:$DIRECTORY
# renovate: datasource=github-tags depName=terraform-ibm-modules/common-bash-library
TAG=v0.2.0
TMP_DIR=$(mktemp -d "${DIRECTORY}/common-bash-XXXXX")

echo "Downloading common-bash-library version ${TAG}."

# download common-bash-library
curl --silent \
    --connect-timeout 5 \
    --max-time 10 \
    --retry 3 \
    --retry-delay 2 \
    --retry-connrefused \
    --fail \
    --show-error \
    --location \
    --output "${TMP_DIR}/common-bash.tar.gz" \
    "https://github.com/terraform-ibm-modules/common-bash-library/archive/refs/tags/$TAG.tar.gz"

mkdir -p "${TMP_DIR}/common-bash-library"
tar -xzf "${TMP_DIR}/common-bash.tar.gz" -C "${TMP_DIR}"
rm -f "${TMP_DIR}/common-bash.tar.gz"

# shellcheck disable=SC1091,SC1090
source "${TMP_DIR}/common-bash-library-${TAG#v}/common/common.sh"

echo "Installing jq."
install_jq "latest" "${DIRECTORY}" "true"
echo "Installing kubectl."
install_kubectl "latest" "${DIRECTORY}" "true"

rm -rf "$TMP_DIR"

echo "Installation complete successfully"
