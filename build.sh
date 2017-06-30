#!/bin/bash
set -e -o pipefail
IFS=$'\n\t'

DOCKER_SOCKET=/var/run/docker.sock

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi

if [ -n "${VERSION}" ]; then
  OUTPUT_IMAGE="${NAMESPACE}${BASE_IMAGE_NAME}-${VERSION//./}-centos7"
else
  OUTPUT_IMAGE="${NAMESPACE}${BASE_IMAGE_NAME}-centos7"
fi

if [ -n "${OUTPUT_IMAGE}" ]; then
  TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
fi

if [[ "${SOURCE_REPOSITORY}" != "git://"* ]] && [[ "${SOURCE_REPOSITORY}" != "git@"* ]]; then
  URL="${SOURCE_REPOSITORY}"
  if [[ "${URL}" != "http://"* ]] && [[ "${URL}" != "https://"* ]]; then
    URL="https://${URL}"
  fi
  curl --head --silent --fail --location --max-time 16 $URL > /dev/null
  if [ $? != 0 ]; then
    echo "Could not access source url: ${SOURCE_REPOSITORY}"
    exit 1
  fi
fi

BUILD_DIR=$(mktemp --directory)
git clone --recursive "${SOURCE_REPOSITORY}" "${BUILD_DIR}"
if [ $? != 0 ]; then
  echo "Error trying to fetch git source: ${SOURCE_REPOSITORY}"
  exit 1
fi
if [ -n "${SOURCE_REF}" ]; then
  pushd "${BUILD_DIR}"
  git checkout "${SOURCE_REF}"
  if [ $? != 0 ]; then
    echo "Error trying to checkout branch: ${SOURCE_REF}"
    exit 1
  fi
  popd
fi

if [[ -d /var/run/secrets/openshift.io/pull ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/pull/.dockercfg /root/.dockercfg
fi

pushd "${BUILD_DIR}"
make build NAMESPACE=${NAMESPACE} VERSION=${VERSION} BASE_IMAGE_NAME=${BASE_IMAGE_NAME} 
popd

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi

echo "Start to sleep 180 seconds for debugging ..."
sleep 180

if [ -n "${OUTPUT_IMAGE}" ] || [ -s "/root/.dockercfg" ]; then
  docker tag "${OUTPUT_IMAGE}" "${TAG}" 
  docker push "${TAG}"
fi
