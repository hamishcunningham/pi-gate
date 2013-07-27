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
    echo enpelicanisating ${f} ...

    # allow over-riding of METAs from the file itself
# <meta name=\"tags\" contents=\"pi,gate,raspberrypi,raspi\" />\n\
    #TODO
    unset SUMMARY AUTHOR SLUG PUBDATE TAGS

    # default the metadata if not supplied
    [ -z "$SUMMARY" ] && SUMMARY=`grep -i '<title' ${f} |sed -e 's,<title>,,I' -e 's,</title>,,I'`
    [ -z "$AUTHOR" ]  && AUTHOR='Hamish Cunningham'
    [ -z "$SLUG" ]    && SLUG=`basename ${f} |sed -e 's,\.html$,,' -e 's,[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-,,'`

    # the base text to add into the header
    METAS="<meta name=\"slug\" contents=\"${SLUG}\" />\n\
<meta name=\"category\" contents=\"News\" />\n\
<meta name=\"author\" contents=\"${AUTHOR}\" />\n\
<meta name=\"summary\" contents=\"${SUMMARY}\" />"

    # add tags if we got any
    if [ ! -z "${TAGS}" ]
    then
      METAS="${METAS}\n\
<meta name=\"tags\" contents=\"${TAGS}\" />"
    fi

    # set date from filename, or PUBDATE from file, or use TODAY
    if `echo ${f} | grep -q '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-'`
    then
      # set date from filename instead (done by pelican)
      :
    elif [ ! -z "${PUBDATE}" ]
    then
      METAS="${METAS}\n\
<meta name=\"date\" contents=\"${PUBDATE}\" />"
    else
      METAS="${METAS}\n\
<meta name=\"date\" contents=\"${TODAY}\" />"
    fi

    # add the metas etext
    if [ x"${NOMETAS}" != x1 ]
    then
      (
        sed -n '1,/<meta /Ip' ${f} |grep -vi '<meta '
        echo -e $METAS
        tac ${f} |sed -n -e '1,/<meta/Ip' |tac |sed -n '2,$p'
      ) >${f}-$$
    else
      cp ${f} ${f}-$$
    fi

    # tell pelican about relative links
    # (to workaround pelican bug with anchors in relative pathnames we 
    # move anchors out of the way and enclose in XXX...XXX; the finalise
    # target in the Makefile will put them back where they belong)
    sed \
      -e 's,\(src="\)\(images/\),\1|filename|\2,g' \
      -e 's,?m=1",",g' \
      -e 's,h\(ref="#\),hX\1,g' \
      -e 's,h\(ref="/\),hX\1,g' \
      -e 's,h\(ref="http\),hX\1,g' \
      -e 's,h\(ref=".filename\),hX\1,g' \
      -e 's,href="\([^"#]*\)\(#[^"]*\)">,href="\1">XXX\2XXX,g' \
      -e 's,\(href="\),\1|filename|,g' \
      -e 's,hXref,href,g' \
      ${f}-$$ \
    > ${f}-$$-2
    mv ${f}-$$-2 ${f}

    # remove the title h1 heading, if it exists as first line after the start
    # of the body element
    sed -n '1,/^<body /p' ${f}                  >${f}-$$-head
    sed -n '/^<body /,$p' ${f} | sed -n '2,$p'  >${f}-$$-tail
    FIRST_LINE="`head -1 ${f}-$$-tail`"
    ${DBG} "===${FIRST_LINE}==="
    case "${FIRST_LINE}" in
      '<h1 class'*) mv ${f}-$$-head ${f}; sed -n '2,$p' ${f}-$$-tail >>${f} ;;
    esac

    # clean up
    rm ${f}-$$*
  done
}
replace-meta-tags-etc $FILES
