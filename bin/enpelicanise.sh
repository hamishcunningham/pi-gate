#!/usr/bin/env bash

# standard locals
alias cd='builtin cd'
P="$0"
USAGE="`basename ${P}` [-h(elp)] [-d(ebug)] [-n(o) metas] [-M metadata] file(s)\n
\tmunge html files to conform to pelican expectations"
DBG=:
OPTIONSTRING=hdnm:

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
    M)	METADATA="${OPTARG}" ;;
    *)	usage 1 ;;
  esac
done 
shift `expr $OPTIND - 1`
FILES=$*
$DBG doing summut on $TODAY

# function to extract existing META tags data from a .html
extract-metadata() {
  INFILE=$1

  # deal with multiple meta tags on single line
  sed 's,><meta ,>\
<meta ,g' $INFILE >$$
  mv $$ $INFILE

  unset AUTHOR CATEGORY PUBDATE SAVEAS SLUG STATUS SUMMARY TAGS TEMPLATE
  OIFS="${IFS}"
  IFS='
'

  for line in `grep '^<meta name=' ${INFILE}`
  do
    IFS="${OIFS}"
    set `echo ${line} |sed -e 's,[^"]*",,' -e 's,"[^"]*", ,' -e 's,".*,,'`
    KEY="$1"
    $DBG -en "${KEY}= "
    shift
    $DBG $*

    case "${KEY}" in
      author)   AUTHOR="$*" ;;
      category) CATEGORY="$*" ;;
      pubdate)  PUBDATE="$*" ;;
      save_as)  SAVEAS="$*" ;;
      slug)     SLUG="$*" ;;
      status)   STATUS="$*" ;;
      summary)  SUMMARY="$*" ;;
      tags)     TAGS="$*" ;;
      template) TEMPLATE="$*" ;;
    esac
  done
  IFS="${OIFS}"
  $DBG metadata for $INFILE is: AUTHOR=$AUTHOR, CATEGORY=$CATEGORY, PUBDATE=$PUBDATE, SAVEAS=$SAVEAS SLUG=$SLUG, STATUS=$STATUS, SUMMARY=$SUMMARY, TAGS=$TAGS, TEMPLATE=$TEMPLATE
}

# function to update the metatags in a set of .htmls, fix relative links, etc.
replace-meta-tags-etc() {
  for f in $*
  do
    echo enpelicanisating ${f} ...

    # allow over-riding of METAs from the file itself
    unset AUTHOR CATEGORY PUBDATE SAVEAS SLUG STATUS SUMMARY TAGS TEMPLATE
    extract-metadata ${f}

    # default the metadata if not supplied
    SAVEAS_MARKUP=""
    STATUS_MARKUP=""
    [ -z "$AUTHOR" ]   && AUTHOR='Hamish Cunningham'
    [ -z "$CATEGORY" ] && CATEGORY='News'
    [ ! -z "$SAVEAS" ] && SAVEAS_MARKUP="<meta name=\"save_as\" content=\"${SAVEAS}\" />"
    [ -z "$SLUG" ]     && SLUG=`basename ${f} |sed -e 's,\.html$,,' -e 's,[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-,,'`
    [ -z "$SUMMARY" ]  && SUMMARY=`grep -i '<title' ${f} |sed -e 's,<title>,,I' -e 's,</title>,,I'`
    [ ! -z "$STATUS" ] && STATUS_MARKUP="<meta name=\"status\" content=\"${STATUS}\" />"
    [ -z "$TAGS" ]     && TAGS="pi,raspberrypi,raspi,gate"
    [ ! -z "$TEMPLATE" ] && TEMPLATE_MARKUP="<meta name=\"template\" content=\"${TEMPLATE}\" />"
#TODO build assoc array of tags and allow default set as previous line

    # the base text to add into the header
    METAS="<meta name=\"author\" content=\"${AUTHOR}\" />\n\
<meta name=\"category\" content=\"${CATEGORY}\" />\n\
<meta name=\"slug\" content=\"${SLUG}\" />\n\
${SAVEAS_MARKUP}\n\
${STATUS_MARKUP}\n\
<meta name=\"summary\" content=\"${SUMMARY}\" />\n\
<meta name=\"tags\" content=\"${TAGS}\" />\n\
${TEMPLATE_MARKUP}"

    # set date from filename, or PUBDATE from file, or use TODAY
    if `echo ${f} | grep -q '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-'`
    then
      # set date from filename instead (done by pelican)
      :
    elif [ ! -z "${PUBDATE}" ]
    then
      METAS="${METAS}\n\
<meta name=\"date\" content=\"${PUBDATE}\" />"
    else
      METAS="${METAS}\n\
<meta name=\"date\" content=\"${TODAY}\" />"
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
