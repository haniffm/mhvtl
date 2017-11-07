#!/bin/bash
set -x

# upload to our artifactory repo for public rpms
./jfrog rt upload "upload_rpms/*.rpm" public-rpm
