#!/bin/bash
set -x

# upload to our artifactory repo for public rpms

REPO="public-rpm"

if [[ "$VERSION" == "el6x" ]]; then
    REPO="$REPO-el6"
fi

./jfrog rt upload "upload_rpms/*.rpm" $REPO
