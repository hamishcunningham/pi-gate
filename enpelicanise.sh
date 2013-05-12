#!/usr/bin/env bash
#
# template.sh

# standard locals
alias cd='builtin cd'
P="$0"
USAGE="`basename ${P}` [-h(elp)] [-d(ebug)] [-n(no dns)] [-i [1|2|3|...]"
DBG=:
OPTIONSTRING=hdni:

# specific locals
INSTANCE=0
DNS=""
USEDNS="1"

# message & exit if exit num present
usage() { echo -e Usage: $USAGE; [ ! -z "$1" ] && exit $1; }

# process options
while getopts $OPTIONSTRING OPTION
do
  case $OPTION in
    h)	usage 0 ;;
    d)	DBG=echo ;;
    n)	USEDNS="" ;;
    i)	INSTANCE="${OPTARG}" ;;
    *)	usage 1 ;;
  esac
done 
shift `expr $OPTIND - 1`

# do some stuff
afunction() {
  ...
}
