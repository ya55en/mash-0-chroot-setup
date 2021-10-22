#! /bin/sh
#: Parse `.env.mk.sample` and spit an output to stdout which is suitable
#: to become the `.env` of the chroot-setup.

# Fails during CI build:
. "$MASH_HOME/lib/sys.sh"
#import small-lib

. ./scripts/small-lib.sh

_name_="$(basename "$0")"
_cde_name_='create-dot-env.sh'
#echo "$_cde_name_: _name_=[$_name_], _cde_name_=[$_cde_name_]"

_CDE__ENV_SAMPLE_FILE='.env.mk.sample'

#: If this is an assignment, split the line into lhs (the lhs) and rhs
#: and echo back the lhs, the assign operator and the rhs, space-delimited;
#: otherwise fail.
split_line() {
    local line="$1"

    # must already be true but we double-check
    has_substr "$line" '=' || {
        die 101 "$_name_: Expected line with assignment, got [$line]"
    }

    local assign='??'
    local lhs='??'
    local rhs='??'

    if has_substr "$line" ':='; then
        assign=':='
        lhs="${line%:=*}"
        rhs="${line#*:=}"

    elif has_substr "$line" '='; then
        assign='='
        lhs="${line%=*}"
        rhs="${line#*=}"
    else
        errmsg="$_name_: INTERNAL: expected assignment in line $line! Terminating."
        die 199 "$errmsg"
    fi
    printf '%s %s %s\n' "$lhs" "$assign" "$rhs"
}

should_be_processed() {
    local line="$1"
    has_substr "$line" '=' && has_substr "$line" '$${'
}

main() {
    local OIFS="$IFS"
    local IFS=''
    while read -r line; do

        if ! should_be_processed "$line"; then
            printf '%s\n' "$line"
            continue
        fi

        #else:

        local lhs='??'
        local assign='??'
        local rhs='??'

        splitted="$(split_line "$line" || die 102 'INTERNAL (51965)')"
        assing_multiple "$splitted" lhs assign rhs

        if has_substr "$rhs" '$${'; then
            rhs="$(echo "$rhs" | sed 's:\$\${:\${:g')"
            rhs="$(reeval "$rhs")"
        fi
        echo "${lhs} ${assign} ${rhs}"

    done < "$_CDE__ENV_SAMPLE_FILE"
    IFS="$OIFS"
}

if [ "$_name_" = "$_cde_name_" ]; then
    main
fi
