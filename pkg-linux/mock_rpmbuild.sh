#!/bin/bash
#
#    VSM_notice_begin
#
#       VSM - Versity Storage Management File System
#
#       Copyright (c) 2015  Versity Software, Inc.
#       All Rights Reserved
#
#    VSM_notice_end
#

set -e

# env flags to change RPM build behavior
DEV_BUILD=${DEV_BUILD:-"no"}

# the user passes in these things:
# argv $1: RPM_TAR_FILE  - .tar.gz ready for rpmbuild -ts, -ta, etc
# env PKG_NAME: name of package
# env FULL_VERSION: entire version string for package
#  - these two together get PKG_NAME-FULL_VERSION in the RPM name, etc
#
RPM_TAR_FILE=$1

if [[ -z "$RPM_TAR_FILE" ]]; then
    echo "usage: $0 /path/to/rpm/ready/file.tar.gz"
    exit 1
fi

if [[ -z "$PKG_NAME" ]] || [[ -z "$FULL_VERSION" ]]; then
    echo "environment missing PKG_NAME or FULL_VERSION"
    exit 1
fi

RPM_DIR=${RPM_DIR:-"${HOME}/rpmbuild"}
mkdir -p "${RPM_DIR}"/{SOURCES,BUILD,BUILDROOT,RPMS,SRPMS}

export RESULT_DIR RPM_DIR

# mock ignores $HOME/.rpmmacros, so set here
VENDOR="Versity Software, Inc."

test_flag() {
    flag=$1

    if [ "$flag" == "yes" ]; then
        /bin/true
    else
        /bin/false
    fi
}

string_flag() {
    flag=$1

    if test_flag "$flag" == /bin/true; then
        echo "true"
    else
        echo "false"
    fi
}

# print flag value and status to command line/logs
print_vars_and_flags() {
    echo
    echo "Variables:"

    echo "PKG_NAME: -> '$PKG_NAME'"
    echo "FULL_VERSION: -> '$FULL_VERSION'"
    echo "DISTRO_VERS: -> '$DISTRO_VERS'"
    echo "MOCK_CONFIG: -> '$MOCK_CONFIG'"
    echo "RESULT_DIR: -> '$RESULT_DIR'"
    echo "RPM_DIR: -> '$RPM_DIR'"

    echo
    echo "Flags:"
    echo "DEV_BUILD: -> $DEV_BUILD ($(string_flag "$DEV_BUILD"))"
    echo

}

mock_init() {
    mock "$MOCK_OPTS" --init
}

mock_build () {
    local spec_file

    spec_file="$1"

    test -f "$spec_file"

    # no DEV_BUILD handling here yet - spec file(s) don't support it for mhvtl
    #
    # other macros to add
    OPTARGS="--define 'vendor ${VENDOR}'"

    echo "MOCK_OPTS: $MOCK_OPTS"
    echo "OPTARGS: $OPTARGS"

    eval mock --buildsrpm "${MOCK_OPTS}" "${OPTARGS}" \
    --spec "$spec_file" --sources "${RPM_DIR}/SOURCES" \
    --resultdir "${RESULT_DIR}" --no-cleanup-after \
    --disable-plugin=package_state

    eval mock --rebuild "${MOCK_OPTS}" "${OPTARGS}" \
    --resultdir "${RESULT_DIR}" --no-clean \
    "${RESULT_DIR}/$PKG_NAME-*.src.rpm"
}

common_build () {
    MOCK_OPTS=" --uniqueext=${USER} -r ${MOCK_CONFIG}"

    # pull the spec file out, as that is the bit mock wants to start with
    spec_file=$(tar xvf "$RPM_TAR_FILE" "*/$PKG_NAME*.spec")
    echo "SPEC: -> '$spec_file'"

    RESULT_DIR=$(pwd)/$(dirname "$spec_file")

    print_vars_and_flags

    cp -v "$RPM_TAR_FILE" "$RPM_DIR/SOURCES/"
    mock_init

    # mock needs full path, as it'll cd around before copying in.
    mock_build "$(pwd)/$spec_file"
}

# Centos 6.6
build_centos_66() {
    MOCK_CONFIG=${MOCK_CONFIG:-"centos-6.6-x86_64"}
    common_build
}

# Centos 6.7
build_centos_67() {
    MOCK_CONFIG=${MOCK_CONFIG:-"centos-6.7-x86_64"}
    common_build
}

# Centos 6.x (latest), currently 6.7
build_centos_6x() {
    MOCK_CONFIG=${MOCK_CONFIG:-"centos-6.x-x86_64"}
    common_build
}

# allows users to set DISTRO_VERS environment config
DISTRO_VERS=${DISTRO_VERS:-"$1"}

case "$DISTRO_VERS" in
 "6.6")
    build_centos_66
    ;;
 "6.7")
    build_centos_67
    ;;
 "6.x")
    build_centos_6x
    ;;
 *)
    DISTRO_VERS="default"
    build_centos_67
    ;;
esac
