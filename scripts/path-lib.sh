#! /bin/sh
# path-lib.sh should be sourced.


#: Return a relative part of given path $1 from given directory $2 to
#: the end of the path, stripping the part from the beginning to the
#: given directory.
relpath_from_dir() {
    local path="$1"
    local dir="$2"

    echo "$path" | sed "s:^.*/\?\($dir/.*$\):\1:"
}

# TODO: provide proper tests based on lib-4test.

test_relpath_from_dir() {
    res="$(relpath_from_dir '/one/two/three/four/five' 'three')"  # expected three/four/five
    echo $res
    res="$(relpath_from_dir '/one/two/three/four/five' 'one')"  # expected one/two/three/four/five
    echo $res
    res="$(relpath_from_dir '/one/two/three/four/five' 'five')"  # expected three/four/five'
    echo $res
}

# test_relpath_from_dir
