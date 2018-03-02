#!/bin/bash
set -x

# upload to our artifactory repo for public rpms

if [[ -z "${DISTRO_VERS}" ]]; then
    echo "ERROR: DISTRO_VERS must be set to your minor OS version (e.g. 6.9, 7.4.1708)"
    exit 1
fi

case "${DISTRO_VERS}" in
    "7.x")
        EL_VERSION="7.4.1708"
        ;;
    "7.3")
        EL_VERSION="7.3.1611"
        ;;
    "6.x")
        EL_VERSION="6.9"
        ;;
    "*")
        echo "Undetected patch level"
        exit 1
        ;;
esac

REPO="public-rpms/${EL_VERSION}/"

PATTERN="${DISTRO_VERS}/*.rpm"

./jfrog rt upload "upload_rpms/${PATTERN}" "${REPO}"
