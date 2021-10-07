#! /bin/sh
#: Parse `.env.sample` and spit an output to stdout which is suitable
#: to become the `.env` of the chroot-setup.

_name_="$(basename "$0")"

die() {
    rc="$1"
    errmsg="$2"

    printf "%s\n" "$errmsg"
    exit "$rc"
}

#: Return success if "$2" is found within "$1", otherwise fail.
#: If $1 is empty, fail with '1', If $2 is empty, die promptly with 101
#: as behavior is undefined for $2=''.
has_substr() {
    [ -z "$1" ] && return 1 # empty string does not contain anything
    [ -z "$2" ] && die 101 "has_substr(): illegal call with empty substring."
    [ -z "${1##*$2*}" ]
}

#: Evaluates the string argument and prints the resulting string.
reeval() {
    eval "printf '%s' $1"
}

#: Assign multiple space-delimited values of "$1" to multiple variables
#: given as the remaining arguments. Example:
#:   assing_multiple "ONE TWO THREE" one two three
assing_multiple() {
    # IMPORTANT: IFS *must* be set *first* as it affects $* and $@!
    OIFS_1="$IFS"
    IFS=' '

    multiple_values="$1"
    shift
    varnames="$*"

    # shellcheck disable=2086,2229
    read -r $varnames << EOS
$multiple_values
EOS
    IFS="$OIFS_1"
}

#: If this is an assignment, split the line into lhs (the lhs) and rhs
#: and echo back the lhs, the assign operator and the rhs, space-delimited;
#: othereise fail.
split_line() {
    line="$1"

    # just double-checking
    has_substr "$line" '=' || {
        die 101 "$_name_: Expected line with assignment, got [$line]"
    }

    assign='??'
    lhs='??'
    rhs='??'

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

should_not_be_processed() {
    line="$1"
    ! has_substr "$line" '=' || {
        has_substr "$line" '$$' && ! has_substr "$line" '$${'
    }
}

main() {
    OIFS_2="$IFS"
    IFS=''
    while read -r line; do

        if ! has_substr "$line" '='; then
            printf '%s\n' "$line"
            continue
        elif has_substr "$line" '$$' && ! has_substr "$line" '$${'; then
            # preserve lines that happen to have $$ but it is not a variable reference
            printf '%s\n' "$line"
            continue
        fi

        #else:
        lhs='??'
        assign='??'
        rhs='??'

        splitted="$(split_line "$line" || die 102 'INTERNAL (51965)')"
        assing_multiple "$splitted" lhs assign rhs

        if has_substr "$rhs" '$${'; then
            rhs="$(echo "$rhs" | sed 's:\$\${:\${:g')"
            rhs="$(reeval "$rhs")"
        fi
        echo "${lhs} ${assign} ${rhs}"

    done < .env.sample
    IFS="$OIFS_2"
}

test_has_substr() {
    printf '%s\n' 'POSITIVE:'
    has_substr 'abc' 'a'
    echo "rc=$?"
    has_substr 'abc' 'ab'
    echo "rc=$?"
    has_substr 'abc' 'bc'
    echo "rc=$?"
    has_substr 'abc' 'abc'
    echo "rc=$?"
    has_substr 'ab$$c' '$$'
    echo "rc=$?"

    printf '%s\n' 'NEGATIVE:'
    has_substr '' 'ab'
    echo "rc=$?"
    has_substr 'abc' 'ac'
    echo "rc=$?"
    has_substr 'abc' 'ba'
    echo "rc=$?"
    has_substr 'aabca' 'ba'
    echo "rc=$?"

    # must be last as the call exits
    printf '%s\n' 'DIES:'
    has_substr "abc" ''
    echo "rc=$?"
}

test_assign_multiple() {
    assing_multiple 'CHROOT  :=  /tmp/mash-ramdisk' lhs assign rhs
    printf 'lhs=[%s] assign=[%s] rhs=[%s]\n' "$lhs" "$assign" "$rhs"
}

test() {
    test_assign_multiple

    # must be last as it exits at the end
    test_has_substr
}

if [ "${1:-main}" = test ]; then
    test
else
    main
fi
