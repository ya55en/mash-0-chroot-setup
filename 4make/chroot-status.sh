#! /bin/sh

#: Returns rc=0 if nothing is mount on $CHROOT,
#: rc=11 if the chroot root only is mounted on headless;
#: rc=12 if the chroot root only is mounted on mate-desktop;
#: rc=21 if chroot fully mounted on headless;
#: rc=22 if chroot fully mounted on mate-desktop.
#: rc=81 if chroot partially mounted on headless;
#: rc=82 if chroot partially mounted on mate-desktop;
#: rc=90 if mounts are more than expected

[ -n "$CHROOT" ] || {
    printf '%s: Missing mandatory variable: CHROOT\n' "$(basename "$0")"
    exit 2
}

UMOUNT_SCRIPT='./umount-chroot.sh'

count="$(mount | grep -c "$CHROOT")"

if [ -e './umount-chroot.sh' ]; then
    expected="$(grep -Ec '^\s*sudo\s+umount' './umount-chroot.sh')"
else
    expected=6
    printf '%s: Warning: Cannot find %s; setting expected=%u.\n' \
        "$(basename "$0")" "$UMOUNT_SCRIPT" "$expected"
fi

#printf 'expected=%u, count=%u\n' "$expected" "$count"

rc_base=0
result_msg=''

# nothing mounted
if [ "$count" = 0 ]; then
    printf '@@ NOTHING mounted, no active chroot.\n'
    exit 0
fi

# unusual, more mounts than expected
if [ "$count" -gt "$expected" ]; then
    printf '@@ TOO-MANY mounts! UNEXPECTED, terminating.\n'
    exit 90
fi

# else:
# chroot root (possibly) only mounted
if [ "$count" = 1 ]; then
    rc_base=10
    result_msg="@@ SINGLE chroot mount"
elif [ "$count" = "$expected" ]; then
    rc_base=20
    result_msg="@@ FULL chroot mount"
elif [ "$count" -lt "$expected" ]; then
    rc_base=80
    result_msg="@@ PARTIAL chroot mount"
else
    {
        values="count='$count', expected='$expected'"
        printf "%s: UNEXPECTED error: count does not qualify: %s\n" "$(basename "$0")" "$values"
        exit 5
    }
fi

if sudo ls -l /tmp/mash-ramdisk/root/ | grep -Eq 'inside-.*-mate-desktop'; then
    rc_base="$(expr $rc_base + 2)"
    result_msg="${result_msg} of mate-desktop."
elif sudo ls -l /tmp/mash-ramdisk/root/ | grep -Eq 'inside-.*-headless'; then
    rc_base="$(expr $rc_base + 1)"
    result_msg="${result_msg} of headless."
else
    rc_base="$(expr $rc_base + 9)"
    result_msg="${result_msg} of UNKNOWN."
    printf "%s: UNKNOWN chroot environment - neither headless nor mate-desktop\n" "$(basename "$0")"
fi

echo ''
echo "$result_msg"
echo ''
mount | grep "$CHROOT"
echo ''
sudo ls -l "$CHROOT/root/" | grep -E 'inside-.*\.sh'
exit "$rc_base"
