#! /bin/sh
#
# lib-4tests.py
# Library with test utility functions like `assert_equal()`.
# Should be sourced; execution makes sense only for running its own tests.
# (Use 'test' as first (and only) argument when you want to do do.)

# TODO: currently print_pass executes always,
#   even if one or more of the sub-tests fail.

_name_="$(basename "$0")"
_l4t_name_='lib-4test.sh'
echo "$_l4t_name_: _name_=[$_name_], _l4t_name_=[$_l4t_name_]"

_curr_test_=''

is_num() {
    [ "$1" -eq "$1" ] 2> /dev/null
}

# shellcheck disable=2120
print_pass() {
    passmsg="${1:-passed}"
    printf 'ok %u - %s: %s\n' $no $_curr_test_ "$passmsg"
}

print_fail() {
    failmsg="$1"
    printf 'not ok %u - %s: %s\n' $no $_curr_test_ "$failmsg"
}

print_error() {
    failmsg="$1"
    out=${2:-/dev/stderr}
    printf '%s: %s\n' $_curr_test_ "$failmsg" >> $out
}

check_arg_is_num() {
    local arg="$1"
    local arg_name="$2"

    is_num "$arg" || {
        print_error "$arg_name=[$arg] is NOT an integer"
        return 1
    }
}

check_two_args_are_num() {
    local actual="$1"
    local expected="$2"

    check_arg_is_num "$expected" expected && check_arg_is_num "$actual" actual
}

assert_equal() {
    local actual="$1"
    local expected="$2"
    # printf '===> assert_equal [%s] [%s] called\n' "$actual" "$expected"

    if [ "$actual" != "$expected" ]; then
        print_fail "assert_equal FAILED: '$actual' != '$expected'"
        return 1
    fi
}

assert_equal_num() {
    check_two_args_are_num "$1" "$2" || return 1

    local actual="$1"
    local expected="$2"

    # shellcheck disable=2086
    if [ $actual -ne $expected ] 2> /dev/null; then
        print_fail "assert_equal_num FAILED: '$actual' != '$expected'"
        return 1
    fi
}

assert_not_equal() {
    local actual="$1"
    local expected="$2"

    # shellcheck disable=2003,2086
    if [ "$actual" = "$expected" ]; then
        print_fail "assert_not_equal FAILED: '$actual' = '$expected'"
        return 1
    fi
}

assert_not_equal_num() {
    check_two_args_are_num "$1" "$2" || return 1

    local actual="$1"
    local expected="$2"

    # shellcheck disable=2003,2086
    if [ $actual -eq $expected ]; then
        print_fail "assert_not_equal_num FAILED: '$actual' != '$expected'"
        return 1
    fi
}

assert_true() {
    "$@" || {
        print_fail "assert_true FAILED for [$*]"
        return 1
    }
}

assert_false() {
    ! "$@" || {
        print_fail "assert_false FAILED for [$*]"
        return 1
    }

    # Trying to provide a way to have a dooubkle ! but failed
    # if "$@"; then
    #     print_fail "assert_false FAILED for [$cmd]"
    #     return 1
    # else
    #     return 0
    # fi
}

assert_rc_equal() {
    local expected_rc="$1"
    check_arg_is_num "$expected_rc" expected_rc || return 1
    shift
    local cmd="$*"

    $cmd
    [ "$?" != "$expected_rc" ]
}

# ___________________________________________
# Test section below

test_is_num__true() {
    _curr_test_=test_is_num__true
    no=$(expr $no + 1)

    is_num 345 || print_fail "345 not accepted as integer"
    is_num 34 || print_fail "34 not accepted as integer"
    is_num 3 || print_fail "3 not accepted as integer"
    is_num 0 || print_fail "0 not accepted as integer"
    is_num -0 || print_fail "-0 not accepted as integer"
    is_num -345 || print_fail "-345 not accepted as integer"
    is_num +345 || print_fail "+345 not accepted as integer"

    # shellcheck disable=2119
    print_pass
}

test_is_num__false() {
    _curr_test_=test_is_num__false
    no=$(expr $no + 1)

    is_num '34a' && print_fail "34a accepted as integer"
    is_num '34.5' && print_fail "34.5 accepted as integer"
    is_num '' && print_fail "empty string accepted as integer"

    # shellcheck disable=2119
    print_pass
}

test_assert_equal__positive() {
    _curr_test_=test_assert_equal__positive
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_equal tata tata
    assert_equal 123 123
    assert_equal '' ''
    assert_equal 'tata 123' 'tata 123'

    # shellcheck disable=2119
    print_pass
}

test_assert_equal__negative() {
    _curr_test_=test_assert_equal__negative
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_equal tata toto 1> /dev/null && print_fail 'assert_equal tata toto DID NOT fail'
    assert_equal '' toto 1> /dev/null && print_fail 'assert_equal '' toto DID NOT fail'
    assert_equal tata '' 1> /dev/null && print_fail 'assert_equal tata '' DID NOT fail'
    assert_equal ' ' '' 1> /dev/null && print_fail 'assert_equal ' ' '' DID NOT fail'

    # shellcheck disable=2119
    print_pass
}

test_assert_not_equal__positive() {
    _curr_test_=test_assert_not_equal__positive
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_not_equal tata toto
    assert_not_equal '' toto
    assert_not_equal tata ''
    assert_not_equal ' ' ''

    # shellcheck disable=2119
    print_pass
}

test_assert_not_equal__negative() {
    _curr_test_=test_assert_not_equal__negative
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_not_equal tata tata 1> /dev/null && print_fail 'assert_not_equal tata toto DID NOT fail'
    assert_not_equal 123 123 1> /dev/null && print_fail 'assert_not_equal 123 123 DID NOT fail'
    assert_not_equal '' '' 1> /dev/null && print_fail 'assert_not_equal '' '' DID NOT fail'

    # shellcheck disable=2119
    print_pass
}

test_assert_equal_num__positive() {
    _curr_test_=test_assert_equal_num__positive
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_equal_num 123 123
    assert_equal_num 123 0123
    assert_equal_num -000123 -0123
    assert_equal_num 0 0
    assert_equal_num -0 +0
    assert_equal_num '123' '123'
    assert_equal_num 123 '123'
    assert_equal_num '123' 123
    assert_equal_num '123 ' ' 123'

    # shellcheck disable=2119
    print_pass
}

test_assert_equal_num__negative() {
    _curr_test_=test_assert_equal_num__negative
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    # 2> /dev/null

    assert_equal_num 123 124 1> /dev/null && print_fail 'assert_equal_num 123 124 DID NOT fail'
    assert_equal_num -1 1 1> /dev/null && print_fail 'assert_equal_num -1 1 DID NOT fail'
    assert_equal_num 2 2a 1> /dev/null && print_fail 'assert_equal_num 2 2a DID NOT fail'

    # shellcheck disable=2119
    print_pass
}

test_assert_not_equal_num__positive() {
    _curr_test_=test_assert_not_equal_num__positive
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_not_equal_num 123 124
    assert_not_equal_num 1 -1
    assert_not_equal_num 1 -1a

    # shellcheck disable=2119
    print_pass
}

test_assert_not_equal_num__negative() {
    _curr_test_=test_assert_not_equal_num__negative
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_not_equal_num 123 123 1> /dev/null && print_fail 'assert_not_equal_num 123 123 DID NOT fail'
    assert_not_equal_num 0234 00234 1> /dev/null && print_fail 'assert_not_equal_num 0234 00234 DID NOT fail'
    assert_not_equal_num '  234 ' 0000234 1> /dev/null && print_fail 'assert_not_equal_num ' 234 ' 0000234 DID NOT fail'

    # shellcheck disable=2119
    print_pass
}

test_assert_true__positive() {
    _curr_test_=test_assert_true__positive
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_true true
    assert_true [ 1 -eq 1 ]
    assert_true [ abc = abc ]

    # shellcheck disable=2119
    print_pass
}

test_assert_true__negative() {
    _curr_test_=test_assert_true__negative
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_true false 1> /dev/null && print_fail 'assert_true false DID NOT fail'
    assert_true [ 1 -eq 0 ] 1> /dev/null && print_fail 'assert_true [ 1 -eq 0 ] DID NOT fail'
    assert_true [ abc = cba ] 1> /dev/null && print_fail 'assert_true [ abc = cba ] DID NOT fail'

    # shellcheck disable=2119
    print_pass
}

test_assert_true__special_case() {
    _curr_test_=test_assert_true__special_case
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    accepts_complex_string() {
        # echo "accepts_complex_string: arg1=[$1], arg2=[$2]"
        [ "$1" = 'abc def' ]
    }
    assert_true accepts_complex_string 'abc def'

    # shellcheck disable=2119
    print_pass
}

test_assert_false__positive() {
    _curr_test_=test_assert_false__positive
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_false false
    assert_false [ 1 -eq 2 ]
    assert_false [ abc = asd ]

    # shellcheck disable=2119
    print_pass
}

test_assert_false__negative() {
    _curr_test_=test_assert_false__negative
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_false true 1> /dev/null && print_fail 'assert_false true DID NOT fail'
    assert_false [ 3 -eq 3 ] 1> /dev/null && print_fail 'assert_false [ 3 -eq 3 ] DID NOT fail'
    assert_false [ asd = asd ] 1> /dev/null && print_fail 'assert_false [ asd = asd ] DID NOT fail'

    # shellcheck disable=2119
    print_pass
}

test_assert_false__special_case() {
    _curr_test_=test_assert_false__special_case
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    accepts_complex_string() {
        assert_equal "$1" 'abc def'
        return 1
    }
    assert_false accepts_complex_string 'abc def'

    # shellcheck disable=2119
    print_pass
}

test_assert_rc_equal__positive() {
    _curr_test_=test_assert_rc_equal__positive
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_rc_equal 1 true
    assert_rc_equal 0 false
    assert_rc_equal 5 return 5
    assert_rc_equal 127 return 127

    # shellcheck disable=2119
    print_pass
}
test_assert_rc_equal__negative() {
    _curr_test_=test_assert_rc_equal__negative
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    assert_rc_equal 1 false 1> /dev/null && print_fail 'assert_rc_equal 1 false DID NOT fail'
    assert_rc_equal 0 true 1> /dev/null && print_fail 'assert_rc_equal 0 true DID NOT fail'
    assert_rc_equal 5 return 6 1> /dev/null && print_fail 'assert_rc_equal 5 return 6 DID NOT fail'
    assert_rc_equal 127 return 126 1> /dev/null && print_fail 'assert_rc_equal 127 return 126 DID NOT fail'
    assert_rc_equal abs return 0 && print_fail 'assert_rc_equal abs return 0 DID NOT fail'

    # shellcheck disable=2119
    print_pass
}

test_assert_rc_equal__special_case() {
    _curr_test_=test_assert_false__special_case
    # shellcheck disable=2003,2086
    no=$(expr $no + 1)

    accepts_complex_string() {
        [ "$1" = 'abc def' ]
    }
    assert_rc_equal 0 accepts_complex_string 'abc def'

    # shellcheck disable=2119
    print_pass
}

# shellcheck disable=2003,2086
test() {
    set +x
    local no=0

    test_is_num__true
    test_is_num__false
    test_assert_equal__positive
    test_assert_equal__negative
    test_assert_not_equal__positive
    test_assert_not_equal__negative
    test_assert_equal_num__positive
    test_assert_equal_num__negative
    test_assert_not_equal_num__positive
    test_assert_not_equal_num__negative
    test_assert_true__positive
    test_assert_true__negative
    test_assert_true__special_case
    test_assert_false__positive
    test_assert_false__negative
    test_assert_false__special_case
    test_assert_rc_equal__positive
    test_assert_rc_equal__negative
    test_assert_rc_equal__special_case
}

if [ "$_name_" = "$_l4t_name_" ]; then
    if [ "$1" = test ]; then
        test
    else
        echo "$_l4t_name_ is a library - not callable directly."
        echo "If you want to run the tests -- use 'test' argument."
        exit 1
    fi
fi
