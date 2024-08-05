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
  cd -
else
  echo "Skipping image build. IMAGE_BULID: ${IMAGE_BUILD}"
fi
echo " ================================================================================== "

podman images | head -1
podman images | grep $IMAGE_TAG
echo "Pushing ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}..."
podman push "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
echo " ================================================================================== "

ISO_TMPDIR=$(mktemp -d /tmp/iso-$IMAGE_TAG-XXXX)
echo "Build artifacts: $ISO_TMPDIR"
cd $ISO_TMPDIR

# FLATPAK_SONIC_PI="app/net.sonic_pi.SonicPi/x86_64/stable runtime/org.kde.Platform/x86_64/5.15-23.08"
# FLATPAK_ECLIPSE="app/org.eclipse.Java/x86_64/stable runtime/org.gnome.Platform/x86_64/45"

echo " ================================================================================== "

sudo podman run --rm --privileged \
                --volume .:/github/workspace/build \
		docker.io/heyste/build-container-installer:latest \
		VERSION=39  \
		IMAGE_REPO=${REGISTRY} \
		IMAGE_NAME=${IMAGE_NAME} \
		IMAGE_TAG=${IMAGE_TAG} \
		VARIANT=Server
#		FLATPAK_REMOTE_REFS="$FLATPAK_ECLIPSE $FLATPAK_SONIC_PI" \
#		FLATPAK_REMOTE_URL="https://flathub.org/repo/flathub.flatpakrepo"

echo " ================================================================================== "
echo "Build artifacts: $ISO_TMPDIR"
ls -lh $ISO_TMPDIR
echo "Build process has completed! Enjoy testing your new iso"
echo " ================================================================================== "
