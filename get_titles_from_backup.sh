#!/usr/bin/env zsh

. ~/.zshrc

movie_file="$1"

makemkv_info="$(makemkvcon info -r file:"$movie_file" | grep "TINFO:" | cut -d':' -f2-)"

title_durations="$(grep ",9,0," <<< "$makemkv_info")"
title_sizes="$(grep ",10,0," <<< "$makemkv_info")"
title_names="$(grep ",27,0," <<< "$makemkv_info")"
title_mpls="$(grep ",16,0,"   <<< "$makemkv_info")"

# Build tab-separated lines: mpls<TAB>name<TAB>duration<TAB>size
# then sort by mpls filename, then strip it and print with new index
paste \
  <(awk -F'"' '{print $2}' <<< "$title_mpls") \
  <(awk -F'"' '{print $2}' <<< "$title_names") \
  <(awk -F'"' '{print $2}' <<< "$title_durations") \
  <(awk -F'"' '{print $2}' <<< "$title_sizes") \
| sort -k1,1 \
| awk -F'\t' '{printf "%d: %s, %s, %s, %s\n", NR-1, $2, $3, $4, $1}'
