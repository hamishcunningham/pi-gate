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
    n)	USEDNS="" ;;
    i)	INSTANCE="${OPTARG}" ;;
    *)	usage 1 ;;
  esac
done 
shift `expr $OPTIND - 1`
FILES=$*
$DBG doing summut on $TODAY

# do some stuff
replace-meta-tags-etc() {
  for f in $*
  do
    TITLE=`grep -i '<title' $f |sed -e 's,<title>,,I' -e 's,</title>,,I'`
    FBASE=`basename $f |sed 's,\.html$,,'`
    METAS="\n\
<meta name=\"date\" contents=\"${TODAY}\" />\n\
<meta name=\"slug\" contents=\"${FBASE}\" />\n\
<meta name=\"category\" contents=\"Tutorials\" />\n\
<meta name=\"author\" contents=\"Hamish Cunningham\" />\n\
<meta name=\"summary\" contents=\"${TITLE}\" />\n\
"
# no tags for now, use categories instead
# <meta name=\"tags\" contents=\"pimoroni,learn\" />\n\

    (
      sed -n '1,/<meta /Ip' $f |grep -vi '<meta '
      echo -e $METAS
      tac $f |sed -n -e '1,/<meta/Ip' |tac |sed -n '2,$p'
    ) | sed \
        -e 's,\(src="\)\(images/\),\1|filename|\2,g' \
    > ${f}-$$
    mv ${f}-$$ $f
  done
}
replace-meta-tags-etc $FILES
