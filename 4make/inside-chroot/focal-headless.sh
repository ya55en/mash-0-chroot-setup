#! /bin/bash
#: Execute certain tasks inside the chroot after it has been built via bootstrap.

set -xe

TEMP_LOG="/tmp/$(basename "$0").log"

# shellcheck disable=SC1091
. '/etc/environment'
export DEBIAN_FRONTEND=noninteractive

# Fix locales issue as soon as we enter the chroot; source env after that
/usr/sbin/locale-gen en_US.UTF-8
# shellcheck disable=SC1091
. '/etc/default/locale'

dump_vars() {
    printf "MASH_USER=%s\n" "${MASH_USER}"
    printf "MASH_UID=%s\n" "${MASH_UID}"
    cat /etc/environment
}

do_distupgrade() {
    apt-get update >> "$TEMP_LOG"
    apt-get dist-upgrade -y >> "$TEMP_LOG"
}

install_apt_packages() {
    apt-get install -y curl vim >> "$TEMP_LOG"
}

create_mash_user() {
    echo "MASH_PSSWD_HASH=$MASH_PSSWD_HASH"
    useradd \
        -l -u "${MASH_UID}" \
        -UG sudo \
        -md "/home/${MASH_USER}" \
        -s /bin/bash \
        -p "$MASH_PSSWD_HASH" \
        "${MASH_USER}"
}

setup_mashuser_sudo() {
    cat > "/etc/sudoers.d/${MASH_USER}-nopass" << EOS
# mash: setup p_sswdless sudo for $MASH_USER
$MASH_USER ALL=(ALL) NOPASSWD:ALL
EOS
}

add_locale_source_snippet() {
    for file in /root/.bashrc /home/${MASH_USER}/.bashrc; do
        cat >> "$file" << EOS

# $(basename "$0"): sourcing locale:
source /etc/default/locale
EOS

    done
}

set_hostname() {
    # hstnamectl set-hostname "${CODENAME}-headless-chrooted"
    printf "%s-headless-chrooted\n" focal > /etc/hostname
}

do_cleanup() {
    apt-get update
    apt-get autoremove -y
    apt-get autoclean
    apt-get clean
}

main() {
    dump_vars

    do_distupgrade
    install_apt_packages
    create_mash_user
    setup_mashuser_sudo
    add_locale_source_snippet
    set_hostname
    do_cleanup
}

main
