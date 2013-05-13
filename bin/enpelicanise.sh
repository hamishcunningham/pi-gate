#!/usr/bin/env bash

# standard locals
alias cd='builtin cd'
P="$0"
USAGE="`basename ${P}` [-h(elp)] [-d(ebug)] file(s)\n
\tmunge html files to conform to pelican expectations"
DBG=:
OPTIONSTRING=hd

# specific locals
FILES=
#D=`date +"%b %d %Y"`
#D=`date +"%a %d %B %Y"`
D=`date +"%Y-%m-%d %H:%M"`

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
FILES=$*
$DBG doing summut on $D

# do some stuff
afunction() {
  for f in $*
  do
    TITLE=`grep -i '<title' $f |sed -e 's,<title>,,I' -e 's,</title>,,I'`
    METAS="\n\
<meta name=\"tags\" contents=\"pimoroni,learn\" />\n\
<meta name=\"date\" contents=\"${D}\" />\n\
<meta name=\"category\" contents=\"pimo\" />\n\
<meta name=\"author\" contents=\"Hamish Cunningham\" />\n\
<meta name=\"summary\" contents=\"${TITLE}\" />\n\
"
    (
      sed -n '1,/<meta /Ip' $f |grep -vi '<meta '
      echo -e $METAS
      tac $f |sed -n -e '1,/<meta/Ip' |tac |sed -n '2,$p'
    ) > ${f}-$$
    mv ${f}-$$ $f
  done
}
afunction $FILES
