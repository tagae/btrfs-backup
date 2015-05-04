Btrfs backup scripts
====================

Setup
-----

1.  Create the main btrfs filesystem in the block device of your choice:

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

    And proceed to create the respective pools:

        btrfs subvolume create /mnt/main/backup/root
        btrfs subvolume create /mnt/main/backup/home

    The advantage of this setup is that mounting / and /home does not result in
    the backups being mounted as well. Indexing tools will not traverse the
    backups unnecessarily.

    In `fstab` you can specify the mount points of each subvolume:

        LABEL=main    /            btrfs    subvol=root                    0 0
        LABEL=main    /home        btrfs    subvol=home                    0 0
        LABEL=main    /var/backup  btrfs    subvol=backup,noauto,compress  0 0


Usage
-----

Store a read-only snapshot of a subvolume into a pool:

    btrfs-backup-snapshot /home /var/backup/home

Pools can be cleaned up to remove old snapshots:

    btrfs-backup-clean /var/backup/home

Pools can be sent to other pools:

    btrfs-backup-send /var/backup/home /mnt/external/backup/home

Note that any snapshot pool can be cleaned up, in particular external ones:

    btrfs-backup-clean /mnt/external/backup/home

To take a snapshot, send it and cleanup all at once, do

    btrfs-backup / /var/backup/home /mnt/external/backup/home


Acknowledgements
----------------

Some of the scripts draw inspiration from
https://btrfs.wiki.kernel.org/index.php/Incremental_Backup
