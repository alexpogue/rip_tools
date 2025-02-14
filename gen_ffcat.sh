#!/usr/bin/env bash

function getLine() {
  echo "file $1"
}

function gen_ffcat() {
  segments_csv_file="$1"
  export -f getLine
  csvtool call getLine "$segments_csv_file"
}

gen_ffcat "$1"
