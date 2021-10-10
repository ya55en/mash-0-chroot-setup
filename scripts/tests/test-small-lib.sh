#! /bin/sh
# Tests for small-lib.sh. Can be executed directly or sourced.

# shellcheck disable=1091
{
    # Paths are relative to the chroot-setup project root
    . ./scripts/small-lib.sh
    . ./scripts/tests/lib-4test.sh
}

# must follow the imports otherwise _tsl_name_ gets overriden
_name_="$(basename "$0")"
_tsl_name_='test-small-lib.sh'
echo "$_tsl_name_: _name_=[$_name_], _tsl_name_=[$_tsl_name_]"

test_has_substr__true() {
    _curr_test_=test_has_substr__true
    no=$(expr $no + 1)

    assert_true has_substr 'abc' 'a'
    assert_true has_substr 'abc' 'ab'
    assert_true has_substr 'abc' 'bc'
    assert_true has_substr 'abc' 'abc'
    assert_true has_substr 'ab$$c' '$$'

    print_pass
}

test_has_substr__false() {
    _curr_test_=test_has_substr__false
    no=$(expr $no + 1)

    assert_false has_substr 'abc' 'x'
    assert_false has_substr '' 'ab'
    assert_false has_substr 'abc' 'ac'
    assert_false has_substr 'abc' 'ba'
    assert_false has_substr "abc" ''

    print_pass
}

test_assign_multiple__case_exact() {
    _curr_test_=test_assign_multiple__case_exact
    no=$(expr $no + 1)

    local lhs assign rhs
    assing_multiple 'CHROOT  :=  /tmp/mash-ramdisk' lhs assign rhs
    assert_equal $lhs 'CHROOT'
    assert_equal $assign ':='
    assert_equal $rhs '/tmp/mash-ramdisk'

    print_pass
}

test_assign_multiple__case_leftover() {
    _curr_test_=test_assign_multiple__case_leftover
    no=$(expr $no + 1)

    local left right leftover
    assing_multiple 'LEFT  RIGHT one two three' left right leftover
    assert_equal "$left" 'LEFT'
    assert_equal "$right" 'RIGHT'
    assert_equal "$leftover" 'one two three'

    print_pass
}

# shellcheck disable=2034
test_assign_multiple__case_not_enough_data() {
    _curr_test_=test_assign_multiple__case_not_enough_data
    no=$(expr $no + 1)

    local one two three
    assing_multiple 'one two' one two three
    assert_equal "$one" 'one'
    assert_equal "$two" 'two'
    assert_equal "$three" ''

    print_pass
}

test_reeval() {
    #TODO: implement
    false
}

test() {
    set +x
    local no=0

    test_has_substr__true
    test_has_substr__false
    test_assign_multiple__case_exact
    test_assign_multiple__case_leftover
    test_assign_multiple__case_not_enough_data
}

if [ "$_name_" = "$_tsl_name_" ]; then
    test
fi
