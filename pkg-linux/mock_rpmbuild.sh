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

# build against the debug kernel
DEBUG_KERN=${DEBUG_KERN:-"no"}

# turn off safety for speed
UNCLEAN_MOCK=${UNCLEAN_MOCK:-"no"}

# default to a unique dir per user
MOCK_UNIQUE=${MOCK_UNIQUE:-$USER}

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
    echo "KVERSION: -> '$KVERSION'"

    echo
    echo "Flags:"
    echo "DEV_BUILD: -> $DEV_BUILD ($(string_flag "$DEV_BUILD"))"
    echo "DEBUG_KERN: -> $DEBUG_KERN ($(string_flag "$DEBUG_KERN"))"
    echo "UNCLEAN_MOCK: -> $UNCLEAN_MOCK ($(string_flag "$UNCLEAN_MOCK"))"
    echo

}

build_rpmbuild_flags() {
    local optargs

    # other macros to add ?
    optargs="--define 'vendor ${VENDOR}'"

    if [ "${KVERSION}" != "" ]; then
        optargs="$optargs --define 'kversion ${KVERSION}'"
    fi

    if test_flag "$DEBUG_KERN"; then
        optargs="$optargs --define 'kerndebug 1'"
    fi

    echo "$optargs"
}

mock_init() {
    if ! test_flag "$UNCLEAN_MOCK"; then
        eval mock "$MOCK_OPTS" --init --scrub=yum-cache
    fi
}

mock_build () {
    local spec_file
    local rpm_flags

    spec_file="$1"

    test -f "$spec_file"

    rpm_flags=$(build_rpmbuild_flags)

    if test_flag "$DEBUG_KERN"; then
        MOCK_UNIQUE="$MOCK_UNIQUE.debug"
    fi

    if test_flag "$UNCLEAN_MOCK"; then
        MOCK_OPTS="$MOCK_OPTS --no-clean --no-cleanup-after"
    fi

    MOCK_OPTS="$MOCK_OPTS --uniqueext=${MOCK_UNIQUE}"

    echo "MOCK_OPTS: $MOCK_OPTS"
    echo "RPM flags: $rpm_flags"

    eval mock --buildsrpm "${MOCK_OPTS}" \
    "$rpm_flags" \
    --spec "$spec_file" --sources "${RPM_DIR}/SOURCES" \
    --resultdir "${RESULT_DIR}" --no-cleanup-after \
    --disable-plugin=package_state

    eval mock --rebuild "${MOCK_OPTS}" \
    "$rpm_flags" \
    --resultdir "${RESULT_DIR}" --no-clean \
    "${RESULT_DIR}/$PKG_NAME-*.src.rpm"
}

common_build () {
    MOCK_OPTS=" -r ${MOCK_CONFIG}"

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

# Centos 6.x (latest)
build_centos_6x() {
    MOCK_CONFIG=${MOCK_CONFIG:-"epel-6-x86_64"}
    KVERSION=${KVERSION:-"2.6.32-642.13.1.el6.x86_64"}
    common_build
}

# Centos 7.x (latest)
build_centos_7x() {
    MOCK_CONFIG=${MOCK_CONFIG:-"epel-7-x86_64"}
    KVERSION=${KVERSION:-"3.10.0-514.6.1.el7.x86_64"}
    common_build
}

# allows users to set DISTRO_VERS environment config
DISTRO_VERS=${DISTRO_VERS:-"$1"}

case "$DISTRO_VERS" in
 "6.x")
    build_centos_6x
    ;;
 "7.x")
    build_centos_7x
    ;;
 *)
    DISTRO_VERS="default"
    build_centos_6x
    ;;
esac
