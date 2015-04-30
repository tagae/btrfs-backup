BTRFS backup scripts
====================

Setup
-----




Usage
-----



Snapshots are taken by specifying a source subvolume, and a target subvolume
pool where all snapshots are stored:

    btrfs-backup-snapshot / /var/backup

Snapshots can be cleaned up to remove old snapshots:

    btrfs-backup-clean /var/backup

The current cleanup policy is rather simple and should be improved (see source
code).

Snapshots can be sent to another subvolume pool with

    btrfs-backup-send /var/backup /mnt/backup/root

This will send the most recent snapshot that can be sent incrementally to
/var/backup.  The destination will be mounted and unmounted automatically if
possible.


Acknowledgements
----------------

Some of the scripts draw inspiration from
https://btrfs.wiki.kernel.org/index.php/Incremental_Backup
