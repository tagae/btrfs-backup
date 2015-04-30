BTRFS backup scripts
====================

Setup
-----

See `btrfs-backup.d/setup` in the `config` branch of the repository.


Usage
-----

Snapshots are taken by specifying a source subvolume, and a target subvolume
pool where all snapshots are stored:

    btrfs-backup-snapshot / /var/backup

Snapshots can be cleaned up to remove old snapshots:

    btrfs-backup-clean /var/backup

Snapshots can be sent to another subvolume pool with

    btrfs-backup-send /var/backup /mnt/backup/root

This will send the most recent snapshot in `/var/backup` that can be sent
incrementally to `/mnt/backup/root`.  The destination will be mounted and
unmounted automatically if needed.

Note that any snapshot pool can be cleaned up, in particular external ones:

    btrfs-backup-clean /mnt/backup/root

To take a snapshot, send it and cleanup all at once, do

    btrfs-backup / /var/backup /mnt/backup/root

Acknowledgements
----------------

Some of the scripts draw inspiration from
https://btrfs.wiki.kernel.org/index.php/Incremental_Backup
