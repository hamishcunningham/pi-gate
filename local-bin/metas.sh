#!/usr/bin/env bash

extract-metadata() {
  unset AUTHOR CATEGORY PUBDATE SLUG SUMMARY TAGS
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
      author)   AUTHOR="$*" ;;
      category) CATEGORY="$*" ;;
      pubdate)  PUBDATE="$*" ;;
      slug)     SLUG="$*" ;;
      summary)  SUMMARY="$*" ;;
      tags)     TAGS="$*" ;;
    esac
  done
  IFS="${OIFS}"
  echo metadata for $f is: AUTHOR=$AUTHOR, CATEGORY=$CATEGORY, PUBDATE=$PUBDATE, SLUG=$SLUG, SUMMARY=$SUMMARY, TAGS=$TAGS
}

DBG=:
for f in $*
do
  extract-metadata $f
done
