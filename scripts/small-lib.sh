#! /bin/sh
#
# small-lib.sh -- a small library of helper funcions.
# This file is supposed to be sourced; shebang is only for shellcheck
# to know the shell and for running the tests.

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
    [ -z "$2" ] && return 2 # illegal call with empty substring
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
