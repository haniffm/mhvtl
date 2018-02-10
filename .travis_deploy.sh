#!/bin/bash
set -x

# upload to our artifactory repo for public rpms

REPO="public-rpm"

if [[ "$VERSION" == "el6x" ]]; then
    REPO="$REPO-el6"
    PATTERN="*el6*.rpm"
else
    PATTERN="*el7*.rpm"
fi

./jfrog rt upload "upload_rpms/$PATTERN" $REPO
