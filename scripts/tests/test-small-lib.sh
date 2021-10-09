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

test_has_substr_OLD() {
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
    has_substr "abc" ''
    echo "rc=$?"
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
    has_substr "abc" ''
    echo "rc=$?"
}

test_assign_multiple() {
    assing_multiple 'CHROOT  :=  /tmp/mash-ramdisk' lhs assign rhs
    printf 'lhs=[%s] assign=[%s] rhs=[%s]\n' "$lhs" "$assign" "$rhs"
}

test_reeval() {
    blah
}

test() {
    test_assign_multiple
    test_has_substr
    printf '_name_=[%s]  _tsl_name_=[%s]' "$_name_" "$_tsl_name_"
}

if [ "$_name_" = "$_tsl_name_" ]; then
    test
fi
