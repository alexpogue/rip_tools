#!/usr/bin/env zsh
. ~/.zshrc

main_movie_dir="$1"
mpls_name="$2"

movie_file_name="$(basename "$main_movie_dir")"
iso_file_path="${main_movie_dir}/backup/${movie_file_name}/${movie_file_name}.iso"

if ! [[ -e "$iso_file_path" ]]; then
  echo "Couldn't find expected path ${iso_file_path}, trying to use the present path" >&2
  backup_dir_path="${main_movie_dir}/backup"
  backup_dir_subdir_path=$(find "$backup_dir_path" -mindepth 1 -maxdepth 1 -type d)
  if [[ "$(printf '%s\n' "$backup_dir_subdir_path" | wc -l)" -ne 1 ]]; then
    echo "CRITICAL ERROR: Expected exactly one backup subdirectory." >&2
    exit 1
  fi

  iso_file_path="$(find "$backup_dir_subdir_path" -mindepth 1 -maxdepth 1 -name '*.iso')"

  if [[ "$(printf '%s\n' "$iso_file_path" | wc -l)" -ne 1 ]]; then
    echo "CRITICAL ERROR: Expected exactly one .iso file in $backup_dir_subdir_path." >&2
    exit 1
  fi
fi

echo "iso_file_path = $iso_file_path" >&2

movie_info="$(makemkvcon info -r file:"$iso_file_path" | grep "TINFO:" | cut -d':' -f2-)"

echo "movie_info:" >&2
echo "$movie_info" >&2

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
