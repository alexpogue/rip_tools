#!/usr/bin/env bash

function has_volume_been_added() {
  earlier_volume_ls="$1"

  new_volumes="$(diff -u <(echo "$earlier_volume_ls") <(ls /Volumes) | grep "^+" | grep -v "+++" | sed '/^$/d' | cut -b2-)"
  num_new_volumes="$(grep -c . <<< "$new_volumes")"
  if [ "$num_new_volumes" -lt 1 ]; then
    return 1
  fi
  if [ "$num_new_volumes" -gt 1 ]; then
    2>&1 echo "Error: Found 2 new volumes. Expected only 1. Volumes:"
    2>&1 echo "$new_volumes"
    return 2
  fi
  echo "$new_volumes"
}

function run_progress_checker() {
  current_volume=""

  volume_ls="$(ls /Volumes)"

  current_volume="QUACK_D1"
  while true; do
    added_volume="$(has_volume_been_added "$volume_ls")"
    retcode=$?
    volume_ls="$(ls /Volumes)"
    if [ "$retcode" -eq 0 ]; then
      current_volume="$added_volume"
    fi
    du -d0 -h "/Volumes/DVDRipping/RippedMovies/${current_volume}/backup/${current_volume}"
    sleep 15
  done
}

run_progress_checker
