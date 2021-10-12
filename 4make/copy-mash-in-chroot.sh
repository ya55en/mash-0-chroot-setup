#! /bin/sh

# Install mash core and mash tests into the chroot environment.

set -xe

_DOWNLOAD_CACHE=/tmp

# Override HOME to get a proper path expansion for install.sh
MASH_USER_HOME="/home/${MASH_USER}"



main() {
    echo "Installing mash + tests in chrooted env..."
    cwd="$(pwd)"
    cd ..  # go to the main project root
    _mash_version_="$(./scripts/4make/dump-version.sh)"
    make dist
    sudo mkdir -p "${CHROOT}${_DOWNLOAD_CACHE}/"
    ls -la ./dist/*
    sudo cp -p ."/dist/mash-v${_mash_version_}.tgz" "${CHROOT}${_DOWNLOAD_CACHE}/"
    sudo cp -a ./test "${CHROOT}${MASH_USER_HOME}/"

    # Override HOME to get a proper path expansion for install.sh
    # OLD_HOME="$HOME"
    # export HOME="/home/${MASH_USER}"
    sudo cp -a ./src/install.sh "${CHROOT}${MASH_USER_HOME}/"
    sudo rm -rf "${CHROOT}${MASH_USER_HOME}/.local/opt/mash"

    # export HOME="$OLD_HOME"
    echo "====> Running ${MASH_USER_HOME}/install.sh..."
    # sudo HOME="${MASH_USER_HOME}" chroot "${CHROOT}" "${MASH_USER_HOME}/install.sh"
    sudo chroot "${CHROOT}" sudo -u mash "${MASH_USER_HOME}/install.sh" "$_mash_version_"
    sudo chroot "${CHROOT}" chown -R "${MASH_USER}:${MASH_USER}" "${MASH_USER_HOME}/test"
    cd "$cwd" || true
}

main
