#!/bin/sh

# Install TI Compilers on Travis
# https://github.com/nemequ/ti-compiler-install-travis
#
# To the extent possible under law, the author(s) of this script have
# waived all copyright and related or neighboring rights to this work.
# See <https://creativecommons.org/publicdomain/zero/1.0/> for
# details.

TEMPORARY_FILES="/tmp"
INSTALL_DIR="${HOME}/ti"
VERBOSE=0

echo_verbose () {
    if [ $VERBOSE -gt 0 ]; then
	echo "$@" >&2
    fi
}

do_curl () {
    curl \
	 --location \
	 --user-agent "ti-compiler-install (https://github.com/nemequ/ti-compiler-install-travis; ${TRAVIS_REPO_SLUG})" \
	 --header "X-Travis-Build-Number: ${TRAVIS_BUILD_NUMBER}" \
	 --header "X-Travis-Event-Type: ${TRAVIS_EVENT_TYPE}" \
	 --header "X-Travis-Job-Number: ${TRAVIS_JOB_NUMBER}" \
	 "$@"
}

do_install_compiler () {
    CGT_NAME=
    case "$1" in
	"armcl")
	    CGT_NAME=ARM
	    ;;
	"cl430")
	    CGT_NAME=MSP
	    ;;
	"cl2000")
	    CGT_NAME=C2000
	    ;;
	"cl6x")
	    CGT_NAME=C6000
	    ;;
	"cl7x")
	    CGT_NAME=C7000
	    ;;
	"clpru")
	    CGT_NAME=PRU
	    ;;
	*)
	    echo_verbose "Unknown compiler ($1)"
	    return
	    ;;
    esac

    echo_verbose "Installing $1 ($CGT_NAME)..."

    # Find the page for the latest major version
    DL_URL="https:$(do_curl -s "https://www.ti.com/tool/${CGT_NAME}-CGT" | grep -Po "//www\.ti\.com/tool/download/${CGT_NAME}-CGT-([0-9\-]+)" | head -n1)"
    echo_verbose "Found page for $1 at ${DL_URL}"

    # Find the installer URL
    DL_URL="$(do_curl -s "$DL_URL" | grep -Po '(?<=href=\")[^\"]+_linux[^\"]*_installer[^\"]*\.bin')"
    if [ "x" = "x${DL_URL}" ]; then
	echo "Unable to find $1 installer to download." >&2
	exit 1
    fi

    # Download the installer
    INSTALLER_FILENAME="$(echo "${DL_URL}" | grep -oP '[^/]+$')"
    COMPILER_NAME="$(echo "${INSTALLER_FILENAME}" | grep -oP '(?<=ti_cgt_)([0-9a-z]+)')"
    COMPILER_VERSION="$(echo "${INSTALLER_FILENAME}" | grep -oP '[0-9a-z\.]+\.(STS|LTS)')"
    INSTALLER_LOCATION="${TEMPORARY_FILES}/${INSTALLER_FILENAME}"
    echo_verbose "Downloading $1 ($COMPILER_NAME) $INSTALLER_VERSION from ${DL_URL}"
    do_curl -o "${INSTALLER_LOCATION}" "${DL_URL}"
    if [ ! -e "${INSTALLER_LOCATION}" ]; then
	echo "Failed to download $1 installer" >&2
	exit 1
    elif [ $VERBOSE -gt 0 ]; then
	echo "SHA-1 checksum for installer: $(sha1sum "${INSTALLER_LOCATION}" | awk '{ print $1 }')" >&2
    fi

    # Install
    if [ ! -e "${INSTALL_DIR}" ]; then
	mkdir -p "$INSTALL_DIR" || (echo "Unable to create installation directory (${INSTALL_DIR})" >&2 && exit 1)
    fi
    chmod u+x "${INSTALLER_LOCATION}"
    ldd "${INSTALLER_LOCATION}" >/dev/null 2>/dev/null || (echo "Unable to execute installer... you probably need to install gcc-multilib." >&2 && exit 1)
    "${INSTALLER_LOCATION}" --mode unattended --unattendedmodeui none --prefix "${INSTALL_DIR}" || \
	(echo "Installation failed." >&1 && exit 1)

    INSTALL_BINDIR="${HOME}/bin"
    # symlink the installed binaries to something in $PATH
    for destfile in "$(dirname "$(ls "${INSTALL_DIR}"/*/bin/$1)")"/*; do
	ln -s "$destfile" "${INSTALL_BINDIR}"/"$(basename "$destfile")"
    done
}

COMPILER_INSTALLED=no
while [ $# != 0 ]; do
    case "$1" in
	"--dest")
	    export INSTALL_DIR="$(realpath "$2")"; shift
	    ;;
	"--tmpdir")
	    TEMPORARY_FILES="$2"; shift
	    ;;
	"--verbose")
	    VERBOSE=1
	    ;;
	"all")
	    for compiler in armcl cl430 cl2000 cl6x cl7x clpru; do
		do_install_compiler "${compiler}"
	    done
	    COMPILER_INSTALLED=yes
	    ;;
	*)
	    do_install_compiler "$1"
	    COMPILER_INSTALLED=yes
	    ;;
    esac
    shift
done

if [ "$COMPILER_INSTALLED" != "yes" ]; then
    if [ "x$CC" != "x" ]; then
	do_install_compiler "$CC"
    elif [ "x$CXX" != "x" ]; then
	do_install_compiler "$CXX"
    fi
fi
