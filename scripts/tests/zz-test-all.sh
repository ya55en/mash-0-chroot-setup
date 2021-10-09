#! /bin/sh

# Run all tests in chroot-setup/scripts/tests

_name_="$(basename "$0")"
_ta_name_345_='zz-test-all.sh'
echo "$_ta_name_345_: _name_=[$_name_], _ta_name_345_=[$_ta_name_345_]"

print_header() {
    local filename="$1"
    printf '\n=== Running %s ===\n' $filename
}

test() {
    # rc=0
    print_header ./scripts/tests/lib-4test.sh
    ./scripts/tests/lib-4test.sh test
    # rc=$(expt $rc + $?)

    print_header ./scripts/tests/test-small-lib.sh
    ./scripts/tests/test-small-lib.sh
    # rc=$(expt $rc + $?)

    print_header ./scripts/tests/test-create-dot-env.sh
    ./scripts/tests/test-create-dot-env.sh
    # rc=$(expt $rc + $?)

    printf '\nTOTAL: Tests failed: %u\n' $rc
    return $rc
}

if [ "$_name_" = "$_ta_name_345_" ]; then
    test
fi
