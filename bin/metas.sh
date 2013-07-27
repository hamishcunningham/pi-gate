#!/usr/bin/env bash

DBG=:

for f in $*
do
    unset SUMMARY AUTHOR SLUG PUBDATE TAGS
    OIFS="${IFS}"
    IFS='
'
    for line in `grep '^<meta name=' ${f}`
    do
      IFS="${OIFS}"
      set `echo ${line} |sed -e 's,[^"]*",,' -e 's,"[^"]*", ,' -e 's,".*,,'`
      KEY="$1"
      $DBG -en "${KEY}= "
      shift
      $DBG $*
      case "${KEY}" in
        author)  AUTHOR="$*" ;;
        summary) SUMMARY="$*" ;;
        slug)    SLUG="$*" ;;
        tags)    TAGS="$*" ;;
        pubdate) PUBDATE="$*" ;;
      esac
    done
    IFS="${OIFS}"
    echo metadata for $f is: SUMMARY=$SUMMARY, AUTHOR=$AUTHOR, SLUG=$SLUG, PUBDATE=$PUBDATE, TAGS=$TAGS
done
