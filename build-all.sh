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
		VARIANT=Kinoite

echo " ================================================================================== "
echo "Build artifacts: $ISO_TMPDIR"
ls -lh $ISO_TMPDIR
echo "Build process has completed! Enjoy testing your new iso"
echo " ================================================================================== "
