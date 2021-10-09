#! /bin/sh
# Tests for create-dot-env.sh. Can be executed directly or sourced.

# shellcheck disable=1091
{
    # Paths are relative to the chroot-setup project root
    . ./scripts/create-dot-env.sh
    . ./scripts/tests/lib-4test.sh
}

# must follow the imports otherwise _tcde_name_ gets overriden
_name_="$(basename "$0")"
_tcde_name_='test-create-dot-env.sh'
echo "$_tcde_name_: _name_=[$_name_], _tcde_name_=[$_tcde_name_]"

# shellcheck disable=2003,2016
test_split_line() {
    printf '%s\n' 'test_split_line:'
    local no=0

    _assert_equal() {
        no=$(expr $no + 1)
        expected="$1"
        actual="$2"
        if [ "$actual" = "$expected" ]; then echo " case-$no OK"; else
            echo " case-$no FAILED: [$actual] != [$expected]"
        fi
    }

    _assert_equal 'TAR_EXT := $${MASH_CHROOT_TAR_EXT:-gz}' "$(split_line 'TAR_EXT:=$${MASH_CHROOT_TAR_EXT:-gz}')"
    rc=$(expr $rc + $?)
    _assert_equal 'TAR_EXT  :=  $${MASH_CHROOT_TAR_EXT:-gz}' "$(split_line 'TAR_EXT := $${MASH_CHROOT_TAR_EXT:-gz}')"
    rc=$(expr $rc + $?)
    return $rc
}

# shellcheck disable=2003,2016
test_should_be_processed() {
    printf '%s\n' 'test_should_be_processed:'
    local rc=0
    local no=0 # test case number

    do_positive_test() {
        no=$(expr $no + 1)
        if should_be_processed "$1"; then echo " case-$no OK"; else
            echo " case-$no FAILED"
            rc=$(expr $rc + 1)
        fi
    }

    do_negative_test() {
        no=$(expr $no + 1)
        if ! should_be_processed "$1"; then echo " case-$no OK"; else
            echo " case-$no FAILED"
            rc=$(expr $rc + 1)
        fi
    }

    do_positive_test 'TAR_EXT := $${MASH_CHROOT_TAR_EXT:-gz}'
    do_positive_test 'MASH_PSSWD_HASH := $${MASH_CHROOT_USER_PSSWD_HASH:-\$(MASH_PSSWD_HASH_DEFAULT)}'
    do_negative_test 'MASH_PSSWD_HASH_DEFAULT := $$6$$coq/LvbNy'
    do_negative_test 'MASH_USER := mash'
    # do_positive_test 'MASH_USER := mash'  # fails - for checking how it runs with a failng test
    return $rc
}

test_e2e() {
    local rc=0
    local tmp_file='/tmp/create-dot-env-4test.dump'
    local ref_file='scripts/tests/expected-output-create-dot-env.dump'

    main > "$tmp_file"
    if diff -u "$tmp_file" "$ref_file"; then
        printf 'e2e test OK\n'
    else
        printf 'e2e test FAILED; diff is above ^^\n'
        rc=1
    fi
    rm $tmp_file
    return $rc
}

# shellcheck disable=2003,2086
test() {
    local rc=0

    echo ''
    test_split_line
    rc=$(expr $rc + $?)
    echo ''

    test_should_be_processed
    rc=$(expr $rc + $?)
    echo ''

    test_e2e
    rc=$(expr $rc + $?)

    printf "\n%s:" "$_tcde_name_"
    [ "$rc" = 0 ] && printf ' SUCCESS!' || printf '  Testing FAILED.'
    printf '  Failed tests: %u\n' $rc
    return $rc
}

if [ "$_name_" = "$_tcde_name_" ]; then
    test
fi
