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

function die {
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

function now {
    date --rfc-3339=seconds
}
