Cleanup Filters
===============

The filters in this directory describe the snapshots that are spared from
deletion.  For instance,

    not today

means that the snapshots taken today will be omitted from the deletion list
(mind though that in this case _all other_ snapshots will be deleted!).

Often it is more useful to have a combination of two filters. For instance,

    neither this-year last-for-month

means that all snapshots taken this year will be kept, and also the last
snapshot of each month (for other years).


Execution
---------

There is one deletion round per filter —that is, for each filter, the list of
_existing_ snapshots is passed as input, and the resulting output of the filter
constitutes the list of snapshots that is be deleted.  Each filter successively
leaves less and less snapshots for the following filter to process.

The order in which filters execute is irrelevant.
