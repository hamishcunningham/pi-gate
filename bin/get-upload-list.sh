#!/bin/bash
#
# get-upload-list.sh

# standard locals
alias cd='builtin cd'
P="$0"
USAGE="`basename ${P}` [-h(elp)] [-d(ebug)]"
DBG=:
OPTIONSTRING=hd

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
    *)	usage 1 ;;
  esac
done 
shift `expr $OPTIND - 1`

echo '/'
grep -- " -> 's3:" | \
  sed -e "s, -> 's3:.*,," -e "s,upload 'output,,"
