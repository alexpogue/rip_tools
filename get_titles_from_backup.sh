#!/usr/bin/env zsh

. ~/.zshrc

movie_file="$1"

makemkv_info="$(makemkvcon info -r file:"$movie_file" | grep "TINFO:" | cut -d':' -f2-)"
#makemkv_info="$(< info_out.txt)"
#makemkv_info="$(cat info_out.txt | grep "TINFO:" | cut -d':' -f2-)"

title_durations="$(grep ",9,0," <<< "$makemkv_info")"
title_sizes="$(grep ",10,0," <<< "$makemkv_info")"
title_names="$(grep ",16,0," <<< "$makemkv_info")"

i=1
while read -r duration_line; do
  size_line="$(echo "$title_sizes" | head -n "$i" | tail -n 1)"
  name_line="$(echo "$title_names" | head -n "$i" | tail -n 1)"

  name="$(echo "$name_line" | cut -d',' -f4 | tr -d '"')"
  if [[ -z "$name" ]]; then
    name="Title"
  fi
  size="$(echo "$size_line" | cut -d',' -f4 | tr -d '"')"
  duration="$(echo "$duration_line" | cut -d',' -f4 | tr -d '"')"

  echo "$(( i - 1 )): $name, $duration, $size"
  (( i++ ))
done <<< "$title_durations"
