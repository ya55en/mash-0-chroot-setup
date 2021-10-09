#! /bin/sh

# shellcheck disable=2034

MASH_USER=mash
MASH_UID=1234


expand_vars() {
    local file="$1"
    local varnames="$2"

    content="$(cat "$1")"
    for varname in $varnames; do
        sed_arg="s:\${\?$varname}\?:$(eval "echo \$$varname"):g"
        printf '\n%s\n\n' "$sed_arg"
        content="$(printf '%s' "$content" | sed "$sed_arg" )"
    done
    printf '%s' "$content"
}

expand_vars ./run-tests.sh "MASH_USER MASH_UID"
