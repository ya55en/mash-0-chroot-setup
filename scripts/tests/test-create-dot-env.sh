#! /bin/sh
# Tests for create-dot-env.sh. Can be executed directly or sourced.

. "$MASH_HOME/lib/sys.sh"

_name_="$(basename "$0")"
_tcde_name_='test-create-dot-env.sh'
#echo "$_tcde_name_: _name_=[$_name_], _tcde_name_=[$_tcde_name_]"

import lib-4test
import create-dot-env.sh

# shellcheck disable=2003,2016
test_split_line() {
    _curr_test_=test_split_line
    no=$(expr $no + 1)

    assert_equal 'TAR_EXT := $${MASH_CHROOT_TAR_EXT:-gz}' "$(split_line 'TAR_EXT:=$${MASH_CHROOT_TAR_EXT:-gz}')"
    assert_equal 'TAR_EXT  :=  $${MASH_CHROOT_TAR_EXT:-gz}' "$(split_line 'TAR_EXT := $${MASH_CHROOT_TAR_EXT:-gz}')"

    print_pass
}

# shellcheck disable=2003,2016
test_should_be_processed() {
    _curr_test_=test_should_be_processed
    no=$(expr $no + 1)

    assert_true should_be_processed 'TAR_EXT := $${MASH_CHROOT_TAR_EXT:-gz}'
    assert_true should_be_processed 'MASH_PSSWD_HASH := $${MASH_CHROOT_USER_PSSWD_HASH:-\$(MASH_PSSWD_HASH_DEFAULT)}'
    assert_false should_be_processed 'MASH_PSSWD_HASH_DEFAULT := $$6$$coq/LvbNy'
    assert_false should_be_processed 'MASH_USER := mash'
    # assert_true should_be_processed 'MASH_USER := mash'  # fails - for checking how it runs with a failng test

    print_pass
}

# shellcheck disable=2003,2016,2034
test_e2e() {
    _curr_test_=test_e2e
    no=$(expr $no + 1)
    local rc=0

    local tmp_file='/tmp/create-dot-env-4test.dump'
    local ref_file='scripts/tests/expected-output-create-dot-env.dump'

    main > "$tmp_file"
    if diff -u "$tmp_file" "$ref_file"; then
        print_pass
    else
        print_fail 'e2e test FAILED; diff is above ^^'
        rc=1
    fi
    rm $tmp_file
    return $rc
}

# shellcheck disable=2003,2086
test() {
    set +x
    local no=0

    test_split_line
    test_should_be_processed
    # Consider GITHUB_ACTIONS - see issue ya55en/mash-0-chroot-setup#3
    [ "$GITHUB_ACTIONS" = true ] || test_e2e
}

if [ "$_name_" = "$_tcde_name_" ]; then
    test
fi
