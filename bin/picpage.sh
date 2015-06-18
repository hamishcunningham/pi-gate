#!/bin/bash
#
# picpage.sh

# standard locals
alias cd='builtin cd'
P="$0"
USAGE="`basename ${P}` [-h(elp)] [-d(ebug)] dir"
DBG=:
OPTIONSTRING=hdni:

# specific locals
ABC=0
USEXYZ="1"
DIR=""

# message & exit if exit num present
usage() { echo -e Usage: $USAGE; [ ! -z "$1" ] && exit $1; }

# process options
while getopts $OPTIONSTRING OPTION
do
  case $OPTION in
    h)	usage 0 ;;
    d)	DBG=echo ;;
    n)	USEXYZ="" ;;
    i)	ABC="${OPTARG}" ;;
    *)	usage 1 ;;
  esac
done 
shift `expr $OPTIND - 1`

# what's left should be a directory name
DIR=$1
[ -d "$DIR" ] || { echo $P: no directory name; usage 2; }
echo creating picpage in `pwd`...
sleep 1

# create picpage.html in .
doit() {
  OUT=picpage.yam
  echo -e "Images from `pwd`\\n\\n" >$OUT
  for pat in jpg jpeg png
  do
    for f in `find $DIR -name '*.'"${pat}" |grep -v thumbs`
    do
      SIZING=""
      set `identify $f`
      SIZE=`echo $3 |sed 's,x.*,,'`
      [ "$SIZE" -gt 600 ] && SIZING=", 500"
      echo '%(/'`echo $f |sed 's,-[x0-9]*\.,.,'`', %image(/'$f', CAPTION '${SIZING}'))'
      echo
    done >>$OUT
  done
  yam2html -n $OUT
}
doit
