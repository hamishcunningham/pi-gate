#!/usr/bin/env bash

# standard locals
alias cd='builtin cd'
P="$0"
USAGE="`basename ${P}` [-h(elp)] [-d(ebug)] file\n
\textract metadata from pandoc mkd files and output appropriate html"
DBG=:
OPTIONSTRING=hd

# specific locals
#TODAY=`date +"%b %d %Y"`
#TODAY=`date +"%a %d %B %Y"`
TODAY=`date +"%Y-%m-%d %H:%M"`

# message & exit if exit num present
usage() { echo -e Usage: $USAGE; [ ! -z "$1" ] && exit $1; }

# process options
while getopts $OPTIONSTRING OPTION
do
  case $OPTION in
    h)	usage 0 ;;
    d)	DBG=echo ;;
    i)	INSTANCE="${OPTARG}" ;;
    *)	usage 1 ;;
  esac
done 
shift `expr $OPTIND - 1`
$DBG doing summut on $TODAY

# function to extract meta data from a .mkd
extract-metadata() {
  f=$1
  case $f in
    *.mkd) ;;
    *) echo 'ignoring non-pandoc file '$f; return; ;;
  esac

  # the metadata
  MD=""

  # temp file
  TMPF=$$--`basename $f`--tmp

  # get the yaml metadata block
  sed -n '/^---$/,/^---$/p' $f |grep -v -- '---' >$TMPF

  # process each line
  OIFS="${IFS}"
  IFS='
'
  for line in `cat $TMPF`
  do
    IFS="${OIFS}"
    set `echo $line |sed 's,:,,'`
    N="$1"
    shift
    MD="${MD}<meta name='${N}' content='$*'>"
  done
  IFS="${OIFS}"

  # pass back result
  echo "${MD}"

  # clean up
  rm $TMPF
}

extract-metadata $1
