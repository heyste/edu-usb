#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo "REGISTRY: ${REGISTRY}"
IMAGE_NAME=${IMAGE_NAME:-aurora}
echo "IMAGE_NAME: ${IMAGE_NAME}"
CURRENT_TIME=$(date +'%Y%m%d-%H%M')
IMAGE_TAG=${IMAGE_TAG:-${CURRENT_TIME}}
echo "IMAGE_TAG: ${IMAGE_TAG}"
IMAGE_BUILD=${IMAGE_BUILD:-true}
echo "IMAGE_BUILD: ${IMAGE_BUILD}"
echo " ================================================================================== "

if [[ $IMAGE_BUILD == 'true' ]] ; then
  cd aurora
  podman build -t ${REGISTRY}/${IMAGE_NAME}:$IMAGE_TAG -f Containerfile .
  podman images | head -1
  podman images | grep $IMAGE_TAG
  echo "Pushing ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}..."
  podman push "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
  cd -
else
  echo "Skipping image build. IMAGE_BULID: ${IMAGE_BUILD}"
fi
echo " ================================================================================== "

# Ref: https://github.com/ublue-os/bluefin/blob/main/.github/workflows/reusable-build-iso.yml#L118
echo "Determine Flatpak Dependencies"
IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

# Make temp space
FLATPAK_REFS_DIR=$(mktemp -d /tmp/flatpak-ref.XXX)
TEMP_FLATPAK_INSTALL_DIR=$(mktemp -d /tmp/flatpak-install.XXX)

# Get list of refs from directory
FLATPAK_REFS_DIR_LIST=$(cat aurora/flatpaks | tr '\n' ' ' )

# Generate install script
cat << EOF > ${TEMP_FLATPAK_INSTALL_DIR}/script.sh
set -ex
cat /temp_flatpak_install_dir/script.sh
mkdir -p /flatpak/flatpak /flatpak/triggers
mkdir /var/tmp || true
chmod -R 1777 /var/tmp
flatpak config --system --set languages "*"
flatpak remote-add --system flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y ${FLATPAK_REFS_DIR_LIST}
ostree refs --repo=\${FLATPAK_SYSTEM_DIR}/repo | grep '^deploy/' | grep -v 'org\.freedesktop\.Platform\.openh264' | sed 's/^deploy\///g' > /output/flatpaks_with_deps
EOF

sudo podman run --rm --privileged \
                --entrypoint bash \
                -e FLATPAK_SYSTEM_DIR=/flatpak/flatpak \
                -e FLATPAK_TRIGGERSDIR=/flatpak/triggers \
                --volume ${FLATPAK_REFS_DIR}:/output \
                --volume ${TEMP_FLATPAK_INSTALL_DIR}:/temp_flatpak_install_dir \
                ${IMAGE} /temp_flatpak_install_dir/script.sh

echo " ================================================================================== "

cat ${FLATPAK_REFS_DIR}/flatpaks_with_deps
FLATPAK_LIST=$(cat ${FLATPAK_REFS_DIR}/flatpaks_with_deps | tr '\n' ' ' )

ISO_TMPDIR=$(mktemp -d /tmp/iso-$IMAGE_TAG-XXXX)
echo "Build artifacts: $ISO_TMPDIR"
cd $ISO_TMPDIR

echo " ================================================================================== "

sudo podman run --rm --privileged \
		--volume .:/build-container-installer/build \
		ghcr.io/jasonn3/build-container-installer:v1.2.2 \
		VERSION=40  \
		IMAGE_REPO=${REGISTRY} \
		IMAGE_NAME=${IMAGE_NAME} \
		IMAGE_TAG=${IMAGE_TAG} \
		VARIANT=Kinoite \
		FLATPAK_REMOTE_REFS="$FLATPAK_LIST" \
		FLATPAK_REMOTE_URL="https://flathub.org/repo/flathub.flatpakrepo"

echo " ================================================================================== "
echo "Build artifacts: $ISO_TMPDIR"
ls -lh $ISO_TMPDIR
echo "Build process has completed! Enjoy testing your new iso"
echo " ================================================================================== "
