#!/usr/bin/env bash

function addNum () {
  if [ -z ${ADDNUM_BASE+x} ]; then
    >&2 echo "Error: ADDNUM_BASE is undefined"
    exit 1
  fi
  if ! [[ "$ADDNUM_BASE" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    >&2 echo "Error: ADDNUM_BASE is not a number, ADDNUM_BASE=$ADDNUM_BASE"
    exit 2
  fi
  echo -n "$1,"
  printf "%.6f," $(echo "$2 + $ADDNUM_BASE" | bc)
  printf "%.6f\n" $(echo "$3 + $ADDNUM_BASE" | bc)
}

function concat() {
  csvFirstFile="$1"
  csvSecondFile="$2"
  
  height="$(csvtool height "$csvFirstFile")"
  secondFileOffset="$(csvtool sub $height 2 1 1 $csvFirstFile)"

  export -f addNum
  export ADDNUM_BASE="$secondFileOffset"
  #csvtool call addNum "$csvSecondFile" > csvSecondFileOffsetTmp.csv
  csvSecondFileWithOffset="$(csvtool call addNum "$csvSecondFile")"

  #csvtool take $(( height - 1 )) "$csvFirstFile" > csvFirstFileShorterTmp.csv
  csvFirstFileShorter="$(csvtool take $(( height - 1 )) "$csvFirstFile")"
  #csvtool cat csvFirstFileShorterTmp.csv csvSecondFileOffsetTmp.csv > output.csv
  csvtool cat <(echo "$csvFirstFileShorter") <(echo "$csvSecondFileWithOffset")
}

concat "$1" "$2"
