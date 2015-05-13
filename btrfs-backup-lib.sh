# Copyright 2015 Sebastian Gonzalez
# http://www.apache.org/licenses/LICENSE-2.0

# Common code for btrfs-backup scripts.

# Inspired on
# http://marc.merlins.org/linux/scripts/btrfs-subvolume-backup

set -o nounset
set -o errexit
set -o pipefail

[ -v DEBUG ] && set -o xtrace

if [ ! -v script ]; then
    script=${0##*/} # shortcut for `basename $0`.
fi

if [ ! -v this ]; then
    this=$(realpath "$0")
fi

if [ ! -v lockfile ]; then
    lockfile=.btrfs-backup-lock
fi

if [ ! -v mountfile ]; then
    mountfile=.btrfs-backup-mount-point
fi

die() {
    # Don't loop on ERR.
    trap '' ERR

    # Process options.
    TEMP=$(getopt --longoptions line:,status: -o l:,s: -- "$@")
    eval set -- $TEMP
    while true; do
        case "$1" in
            --line|-l)
                shift
                line=$1
                shift
                ;;
            --status|-s)
                shift
                status=$1
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Unexpected output from getopt" >&2
                exit 1
                ;;
        esac
    done

    # Show error message (if any).
    echo -n "$script error${line:+ on line $line}${status:+ with status $status}" >&2

    if (( $# > 0)); then
        echo ": $1" >&2
        shift
    else
        echo >&2
    fi

    # Dump code.
    if [ -v line ]; then
        echo "Code dump:" >&2
        nl -ba "$this" | grep --color -5 "\b$line\b" >&2
    fi

    # At last, die in peace.
    exit 1
}

# Trap errors for logging before dying.
trap 'die --line $LINENO --status $?' ERR

#---[ Utils ]---

# join , a "b c" d  -> a,b c,d
# join / var local tmp -> var/local/tmp
# FOO=( a b c ); join , "${FOO[@]}" -> a,b,c
function join {
    local IFS="$1"
    shift
    echo "$*";
}

ensure-command() {
    (( 1 <= $# && $# <= 2 )) || echo "Usage: ensure-command <command> [package]"
    command="$1"
    package="${2:-$1}"
    command -v "$command" > /dev/null || \
        die "Command $command not found, please install the $package package."
}

now() {
    (( $# == 0 )) || die "Usage: now"
    date --rfc-3339=seconds
}

mount-points() {
    (( $# == 0 )) || die "Usage: mount-points"
    awk '/^[[:space:]]*[^#]/ { print $2 }' /etc/fstab
}

bring-up() {
    (( $# == 1 )) || die "Usage: bring-up <pool>"
    local pool=$1
    local mountPoint=$(realpath "$pool")
    while true; do
        [ -d "$pool" ] && return
        if mount-points | grep -E "$mountPoint/?$" > /dev/null; then
            echo "Mounting $mountPoint"
            mount "$mountPoint"
            [ -d "$pool" ] || die "Could not find $pool under mount point $mountPoint"
            echo "$mountPoint" > "$pool/$mountfile"
            return
        fi
        mountPoint=$(dirname "$mountPoint")
        [ "$mountPoint" == "/" ] && die "Nonexistent snapshot pool $pool"
    done
}

bring-down() {
    (( $# == 1 )) || die "Usage: bring-down <pool>"
    local pool=$1
    if [ -v inProgress ] && [ -d "$inProgress" ]; then
        echo "Removing incomplete subvolume: $inProgress" >&2
        btrfs subvolume delete "$inProgress" > /dev/null
    fi
    if [ -e "$pool/$mountfile" ]; then
        mountPoint=$(<"$pool/$mountfile")
        rm "$pool/$mountfile"
        echo "Unmounting $mountPoint"
        umount "$mountPoint"
    fi
}

use-pool() {
    (( $# == 1 )) || die "Usage: ensure-pool <pool>"
    local pool=$1

    # TODO [race condition]: the mounting and unmounting of the pool are
    # outside the lock barrier.

    # Mount if necessary.
    bring-up "$pool"

    # Open pool lockfile with fresh file descriptor. See bash(1) / REDIRECTION.
    exec {fd}>"$pool/$lockfile"

    # Block if pool is being used.
    flock $fd

    # Release lock and unmount pool when done.
    trap "exec "$fd">&-; bring-down '$pool'" EXIT
}

# List subvolume names from most to least recent (irrespective of the name).
subvolume-names() {
    local order=-
    # Process options.
    TEMP=$(getopt --longoptions ascending -o a -- "$@")
    eval set -- $TEMP
    while true; do
        case "$1" in
            --ascending|-a)
                shift
                order=+
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Unexpected output from getopt" >&2
                exit 1
                ;;
        esac
    done
    (( $# == 1 )) || die "Usage: list-subvolume-names [--ascending|-a] <pool>"
    local pool=$1
    local parent=$(dirname "$pool")
    btrfs subvolume list -o --sort=${order}gen "$pool" | \
        while read line; do
            echo ${line##*/} # keep volume name only
        done
}

ensure-command flock util-linux
ensure-command btrfs btrfs-progs
