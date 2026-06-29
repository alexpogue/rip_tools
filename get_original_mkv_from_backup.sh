#!/usr/bin/env zsh

. ~/.zshrc

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ -z "$DVD_RIP_DIR" ]]; then
  source "$SCRIPT_DIR/config.sh"
fi

movie_dir_name="$1"

main_movie_dir="${DVD_RIP_DIR}/${movie_dir_name}"
backup_dir_name="$(ls "${main_movie_dir}/backup/")"
num_backup_dirs="$(grep -c "^" <<< "$backup_dir_name")"
if [[ "$num_backup_dirs" -eq 0 ]]; then
  echo "Error: found zero backup dirs for movie \"$(basename "$main_movie_dir")\""
  exit 1
elif [[ "$num_backup_dirs" -gt 1 ]]; then
  echo "Error: found more than one backup dir for movie \"$(basename "$main_movie_dir")\""
  exit 2
fi

iso_file_or_dir="${main_movie_dir}/backup/${backup_dir_name}/${backup_dir_name}.iso"
if ! [[ -f "$iso_file_or_dir" ]] && ! [[ -d "$iso_file_or_dir" ]]; then
  echo "Error: ISO not found for movie \"$(basename "$main_movie_dir")\""
  echo "Tried to get iso: $iso_file_or_dir"
  continue
fi

title_mpls_to_rip_file_path="${main_movie_dir}/title_mpls_file_to_rip.txt"
if ! [[ -f "$title_mpls_to_rip_file_path" ]]; then
  echo "Error: couldn't decide which .mpls to rip, because can't find file: $title_mpls_to_rip_file_path"
  exit 3
fi
title_mpls_file_to_rip="$(< "$title_mpls_to_rip_file_path")"

original_mkv_dir="${main_movie_dir}/mkv_original"

mkdir -p "$original_mkv_dir"

mkv_file_already_there="$(find "$original_mkv_dir" -maxdepth 1 -name '*.mkv')"
echo "mkv_file_already_there = $mkv_file_already_there"
echo "line count = $(echo "$mkv_file_already_there" | grep -cve '^\s*$')"
if [[ "$(grep -cve "^\s*$" <<< "$mkv_file_already_there")" -gt 0 ]]; then
  echo "Already found mkv file in directory.. delete it to restart copy: $original_mkv_dir"
  exit 4
fi

titles_list="$(./get_titles_from_backup.sh "$iso_file_or_dir")"
echo "For movie $movie_dir_name, ripping title $title_mpls_file_to_rip ($(grep -F ", ${title_mpls_file_to_rip}$" <<< "$titles_list"))"

makemkv_title_num_to_rip="$(${SCRIPT_DIR}/extract_title_id_from_mpls.sh "${main_movie_dir}" "${title_mpls_file_to_rip}")"
echo "title num = $makemkv_title_num_to_rip"

makemkvcon mkv file:"$iso_file_or_dir" "$makemkv_title_num_to_rip" "$original_mkv_dir" | tee "${original_mkv_dir}/out.log"
