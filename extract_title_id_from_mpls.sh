#!/usr/bin/env zsh
. ~/.zshrc

main_movie_dir="$1"
mpls_name="$2"

movie_file_name="$(basename "$main_movie_dir")"
iso_file_path="${main_movie_dir}/backup/${movie_file_name}/${movie_file_name}.iso"

movie_info="$(makemkvcon info -r file:"$iso_file_path" | grep "TINFO:" | cut -d':' -f2-)"

mpls_matching_line="$(grep ",16,0,\"${mpls_name}\"$" <<< "$movie_info")"

num_matching_lines="$(grep -c "[^[:space:]]" <<< "$mpls_matching_line")"
if [[ "$num_matching_lines" -eq 0 ]]; then
  echo "Error: found zero matching .mpls file lines for movie \"${movie_file_name}\", (file name: ${mpls_name})" >&2
  exit 1
elif [[ "$num_matching_lines" -gt 1 ]]; then
  echo "Error: found more than one matcing .mpls file lines for movie \"${movie_file_name}\", (file name: ${mpls_name})" >&2
  exit 2
fi

title_id="$(awk -F',' '{print $1}' <<< "$mpls_matching_line")"

title_info="$(grep "^${title_id}," <<< "$movie_info")"
echo "selected title details:" >&2
echo "$title_info" >&2

echo "$title_id"
