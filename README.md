Btrfs backup scripts
====================

These scripts are a thin wrapper around `btrfs` for the sake of easily
creating, copying and cleaning up backups.


Setup
-----

Create a btrfs filesystem in the block device of your choice:

    mkfs.btrfs -L main /dev/sda3

You can use this filesystem as a source of snapshots, or any subvolume
thereof.

A typical setup is to create separate subvolumes for the directories you
wish to backup independently (say, the root and home directories):

    mkdir /mnt/main
    mount /dev/sda3 /mnt/main
    btrfs subvolume create /mnt/main/root
    btrfs subvolume create /mnt/main/home

Create then a backup subvolume that will contain snapshot pools:

    btrfs subvolume create /mnt/main/backup

and proceed to create the respective pools for your subvolumes of interest:

    btrfs subvolume create /mnt/main/backup/root
    btrfs subvolume create /mnt/main/backup/home

In `fstab` you can specify the mount points of each subvolume:

    LABEL=main    /            btrfs    subvol=root                    0 0
    LABEL=main    /home        btrfs    subvol=home                    0 0
    LABEL=main    /var/backup  btrfs    subvol=backup,noauto,compress  0 0

The advantage of this setup is that mounting `/` and `/home` does not result in
the backups (i.e. `/var/backup`) being mounted as well. Indexing tools will not
traverse the backups unnecessarily.

The `/var/backup` pool acts as a local _time machine_ to which you can resort
when needed.


Usage
-----

Store a read-only snapshot of a subvolume into a pool:

    btrfs-backup-snapshot /home /var/backup/home

Entire pools can be sent to other pools:

    btrfs-backup-send /var/backup/home /mnt/external/backup/home

In this way you can copy your local snapshots to external storage.

Pools can be cleaned up to remove old snapshots:

    btrfs-backup-clean /var/backup/home
    btrfs-backup-clean /mnt/external/backup/home

The cleanup policy (i.e., what an "old" snapshot is) is expressed in terms of
_filters_ defined in the `cleanup.d` directory.

The following is an all-in-one command that is equivalent to all commands shown
previously:

    btrfs-backup /home /var/backup/home /mnt/external/backup/home

It will take a snapshot of `/home`, store it in the pool `/var/backup/home`,
send this pool to another pool `/mnt/external/backup/home`, and cleanup both
pools.

### Running prediodically

Usually the commands described previously will be invoked on a regular basis
from a cron job or systemd timer, for instance to create a snapshot every hour,
cleanup the pools once a day, and send your local pools to external storage
every 3 hours.

The `config` branch of this repository contains examples of scripts you can
invoke as a periodic job. These can be symlinked to your `/usr/local/bin`.


Possible improvements
---------------------

* Have pool-specific cleanup policies, when a `.btrfs-backup-cleanup.d`
  subdirectory is found inside a snapshot pool.  The current global 'cleanup.d`
  directory would serve as default policy.


Acknowledgements
----------------

https://btrfs.wiki.kernel.org/index.php/Incremental_Backup
