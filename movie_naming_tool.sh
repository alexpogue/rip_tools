#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"

mapfile directories < <(find "$DVD_RIP_DIR" -type d -mindepth 1 -maxdepth 1 | sort)

for dir in "${directories[@]}"; do
  trimmed_dir="$(echo "$dir" | awk '{$1=$1};1')"
  movie_title_file="${trimmed_dir}/movietitle.txt"
  if [ -f "$movie_title_file" ]; then
    echo -n "Which movie is \"$(basename $trimmed_dir)\"? ($(< "$movie_title_file" )) "
  else
    echo -n "Which movie is \"$(basename $trimmed_dir)\"? "
  fi
  read -r line
  trimmed_line="$(echo "$line" | awk '{$1=$1};1')"
  if [ -n "$trimmed_line" ]; then
    echo "$trimmed_line" > "${trimmed_dir}/movietitle.txt"
  fi
done
