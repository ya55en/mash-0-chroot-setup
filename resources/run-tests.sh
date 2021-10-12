#! /bin/sh

# shellcheck disable=1091
. /etc/default/locale

echo "$MASH_UID ${MASH_UID}" > /dev/null  # making sure this has expanded as it should

#: mash: sourcing initializing scripts from ~/.bashrc.d/*.sh (We need to do
#: this for non-interactive execution when .bashrc does not work.)
for file in "/home/${MASH_USER}/.bashrc.d/"*.sh; do
    # shellcheck disable=1090
    . "$file"
done

cd "/home/$MASH_USER/" && ./test/e2e/smoke-e2e.sh "$1"
