Cleanup Filters
===============

The filters in the `cleanup.d` directory describe the snapshots that are
cleaned up by the `btrfs-backup-cleanup` command.  For instance,

    not today

means that the snapshots taken today will be spared from deletion —although in
this case, _all other_ snapshots will be deleted.

Often it is more useful to have a combination of two filters. For instance,

    neither this-year last-for-month

means that neither the snapshots from this year, nor the last available
snapshot for each month of previous years, will be deleted.


Execution
---------

By specifying different filters such as shown previously, flexible cleanup
strategies can be expressed.

There is one deletion round per filter: for each filter, the list of
_remaining_ snapshots is passed as input, and the resulting output of the
filter constitutes the list of snapshots to delete.  Each filter successively
leaves less and less snapshots for the following filter to process.

The order in which filters execute is irrelevant.
