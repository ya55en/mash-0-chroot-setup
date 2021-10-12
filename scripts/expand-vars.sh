#! /bin/sh
#: expand-vars.sh - part of ma'shmallow chroot setup sub-project.
#:
#: Process a file from standard input, line by line, substituting
#: shell variables in each line with their values (if any) and
#: printing the resulting line, thus effectively expanding all known
#: variables.
#: Usage:
#:  $  cat /path/to/input.file | ./scripts/expand-vars.sh > /path/to/output.file
#:
#: For example, resources/run-tests.sh needs substitution:
#:  $ cat resources/run-tests.sh | ./scripts/expand-vars.sh

# shellcheck disable=2034

MASH_USER=mash
MASH_UID=1234

main_loop() {
    local varnames="$1"
    local line

    _process_line() {
        for varname in $varnames; do
            sed_arg="s:\${\?$varname}\?:$(eval "echo \$$varname"):g"
            line="$(printf '%s' "$line" | sed "$sed_arg")"
        done
    }

    while read -r line; do
        _process_line
        echo $line
    done
}

main() {
    main_loop 'MASH_USER MASH_UID'
}

main
