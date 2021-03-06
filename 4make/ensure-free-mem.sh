#! /bin/sh
# Pass silently if there is enough memory, fail (rc=9) otherwise.
# Provide minimal required memory (in GB) as first (and only) argument.
# rc=2 on missing or illegal argument
# rc=9 on required memory unavailable

stderr='/dev/stderr'
wrong_arg=2
mem_unavailable=9
required_arg="$1"

is_numeric() {
    test -n "$1" -a "$1" -eq "$1" 2> /dev/null
}

chop_last() {
    printf "${1%?}"
}

assert() {
    # errmsg"=$1"
    # shift
    cmd="$@"

    if ! "$cmd"; then
        echo "(rc=$?) assertion FAILED: $cmd" >> $stderr
        return $?
    fi
}

main() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "$(basename "$0"): Github CI environment detected; skipping check."
        return 0
    fi

    if [ -z "$required_arg" ]; then
        errmsg='Missing argument: Provide minimal required memory (in GB)'
        printf "%s\n" "${errmsg}" >> $stderr
        return $wrong_arg
    fi

    case "${required_arg}" in
        *K | *k) # kilobytes
            factor=1
            ;;
        *M | *m) # megabytes
            factor=1024
            ;;
        *G | *g) # gigabytes
            factor=$((1024 * 1024))
            ;;
        *)
            echo "Unknown/illegal units in '${required_arg}'" > $stderr
            return $wrong_arg
            ;;
    esac

    required="$(chop_last "$required_arg")"
    if ! is_numeric "${required}"; then
        echo "Illegal mem size expression; $1" >> $stderr
        return $wrong_arg
    fi

    avail=$(awk '/^MemAvailable:/ {printf "%.0f", $2/'$factor'}' /proc/meminfo)
    [ "$avail" -ge "$required" ] || {
        printf 'Insufficent memory: required=%s, available=%s\n' "$required_arg" "$avail"
        return $mem_unavailable
    }
}

main "$@"
