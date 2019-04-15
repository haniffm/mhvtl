#!/bin/bash

set -x

docker run --privileged=true -e USER=root -e DISTRO=$DISTRO -e DISTRO_VERS=$DISTRO_VERS --rm -v $(pwd):/src -w /src versity/rpm-build:${VERSION} make rpm
find rpmbuild -name "*.x86_64.rpm" | xargs -n1 cp --target-directory=$(pwd)/

docker run --privileged=true -e USER=root -e DISTRO=$DISTRO -e DISTRO_VERS=$DISTRO_VERS --rm -v $(pwd):/src -w /src versity/rpm-build:${VERSION} make kmod-rpm
find rpmbuild -name "*.x86_64.rpm" | xargs -n1 cp --target-directory=$(pwd)/


