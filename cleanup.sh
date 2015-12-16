# © 2015–2016 Sebastián González
# http://www.apache.org/licenses/LICENSE-2.0

set -o nounset

#---[ Private functions ]---

-patch-day-field () {
    # Replace the separator of date and time with a dash.
    while read line; do
        echo ${line:0:10}-${line:11}
    done
}

-restore-day-field () {
    # Replace the separator of date and time with a space.
    while read line; do
        echo ${line:0:10} ${line:11}
    done
}

-filter-date() {
    (( 1 <= $# && $# <= 2)) || die "Usage: filter-date <key1> [key2]"
    sort --unique --key=$1${2:+,$2} --field=- --stable
}

-without-repetitions() {
    sort --reverse | uniq --unique
}

#---[ Vocabulary ]---

last-for-day() {
    # Help `sort` find the third field (the day).
    # (could be avoided if `sort` supported multiple field separators)
    -patch-day-field | -filter-date 1 3 | -restore-day-field
}

last-for-month() {
    -filter-date 1 2
}

last-for-year() {
    -filter-date 1 1
}

now=$(now)
this_day=${now%% *}
this_month=${this_day%-*}
this_year=${this_month%-*}

this-day() {
    egrep "^$this_day.*"
}

this-month() {
    egrep "^$this_month.*"
}

this-year() {
    egrep "^$this_year.*"
}

today() {
    this-day
}

last-3-years() {
    egrep "^($this_year|$((this_year-1))|$((this_year-2))).*"
}

# Prints input lines that are not filtered out.
not() {
    (( $# == 1)) || die "Usage: not <filter>"
    # Duplicate undesired entries and eliminate them.
    tee >($1) | -without-repetitions
}

neither() {
    (( $# == 2)) || die "Usage: neither <filter1> <filter2>"
    # Replicate the entries that should be eliminated.
    tee >($1) >($2) | -without-repetitions
}
