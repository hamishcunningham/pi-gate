#!/usr/bin/env bash

# standard locals
alias cd='builtin cd'
P="$0"
USAGE="`basename ${P}` [-h(elp)] [-d(ebug)] [-n(o) metas] file(s)\n
\tmunge html files to conform to pelican expectations"
DBG=:
OPTIONSTRING=hdn

# specific locals
FILES=
#TODAY=`date +"%b %d %Y"`
#TODAY=`date +"%a %d %B %Y"`
TODAY=`date +"%Y-%m-%d %H:%M"`
NOMETAS=

# message & exit if exit num present
usage() { echo -e Usage: $USAGE; [ ! -z "$1" ] && exit $1; }

# process options
while getopts $OPTIONSTRING OPTION
do
  case $OPTION in
    h)	usage 0 ;;
    d)	DBG=echo ;;
    n)	NOMETAS=1 ;;
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
    echo enpelicanisating $f ...

    # set up metadata for this file
    TITLE=`grep -i '<title' $f |sed -e 's,<title>,,I' -e 's,</title>,,I'`
    FBASE=`basename $f |sed -e 's,\.html$,,' -e 's,[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-,,'`
    METAS="\n\
<meta name=\"slug\" contents=\"${FBASE}\" />\n\
<meta name=\"category\" contents=\"News\" />\n\
<meta name=\"author\" contents=\"Hamish Cunningham\" />\n\
<meta name=\"summary\" contents=\"${TITLE}\" />\n\
"
# no tags for now, use categories instead
# <meta name=\"tags\" contents=\"pimoroni,learn\" />\n\

    # set date from filename, or use TODAY
    if `echo $f | grep -q '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-'`
    then
      :
      # set date from filename instead
    else
      METAS="${METAS}\n\
<meta name=\"date\" contents=\"${TODAY}\" />\n\
"
    fi

    # add the metas
    if [ x"${NOMETAS}" != x1 ]
    then
      (
        sed -n '1,/<meta /Ip' $f |grep -vi '<meta '
        echo -e $METAS
        tac $f |sed -n -e '1,/<meta/Ip' |tac |sed -n '2,$p'
      ) >${f}-$$
    else
      cp $f ${f}-$$
    fi

    # tell pelican about relative links
    sed \
      -e 's,\(src="\)\(images/\),\1|filename|\2,g' \
      -e 's,?m=1",",g' \
      -e 's,h\(ref="#\),hX\1,g' \
      -e 's,h\(ref="/\),hX\1,g' \
      -e 's,h\(ref="http\),hX\1,g' \
      -e 's,h\(ref=".filename\),hX\1,g' \
      -e 's,\(href="\),\1|filename|,g' \
      -e 's,hXref,href,g' \
      ${f}-$$ \
    > ${f}-$$-2

    # remove first h1 heading
    sed -n '1,/^<h1 class/p' ${f}-$$-2 | grep -v '^<h1 class' >${f}
    sed -n '/^<h1 class/,$p' ${f}-$$-2 | sed -n '2,$p' >>${f}
    rm ${f}-$$*
  done
}
replace-meta-tags-etc $FILES
