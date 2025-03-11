#!/usr/bin/env zsh

source ~/.zshrc

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"

mapfile directories < <(find "$DVD_RIP_DIR" -type d -mindepth 1 -maxdepth 1 | sort)

for dir in "${directories[@]}"; do
  trimmed_dir="$(echo "$dir" | awk '{$1=$1};1')"
  picked_title_file="${trimmed_dir}/title_num_to_rip.txt"
  echo "Titles for \"$(basename $trimmed_dir)\":"

  backup_dir_name="$(ls "${trimmed_dir}/backup/")"
  num_backup_dirs="$(grep -c "^" <<< "$backup_dir_name")"
  if [[ "$num_backup_dirs" -eq 0 ]]; then
    echo "Error: found zero backup dirs for movie \"$(basename $trimmed_dir)\""
    continue
  elif [[ "$num_backup_dirs" -gt 1 ]]; then
    echo "Error: found more than one backup dir for movie \"$(basename $trimmed_dir)\""
    continue
  fi

  iso_file_or_dir="${trimmed_dir}/backup/${backup_dir_name}/${backup_dir_name}.iso"
  if ! [[ -f "$iso_file_or_dir" ]] && ! [[ -d "$iso_file_or_dir" ]]; then
    echo "Error: ISO not found for movie \"$(basename $trimmed_dir)\""
    echo "Tried to get iso: $iso_file_or_dir"
    continue
  fi

  if [[ "$(basename "$trimmed_dir")" == "BOURNE_LEGACY_DOM" ]]; then
    echo "GOT MOVIE FROM SKIP LIST. skipping \"$(basename $trimmed_dir)\""
    continue
  fi

  title_info_cache_file="${trimmed_dir}/title_info_cache.txt"
  if [[ -f "$title_info_cache_file" ]]; then
    cat "$title_info_cache_file"
  else
    echo "trying to get titles for dir $iso_file_or_dir"
    "${SCRIPT_DIR}/get_titles_from_backup.sh" "$iso_file_or_dir" | tee "$title_info_cache_file"
    if [[ "$(grep -c "^" "$title_info_cache_file")" -eq 0 ]]; then
      rm "$title_info_cache_file"
    fi
  fi

  if [ -f "$picked_title_file" ]; then
    echo -n "Which title to rip for \"$(basename $trimmed_dir)\"? ($(< "$picked_title_file" )) "
  else
    echo -n "Which title to rip for \"$(basename $trimmed_dir)\"? "
  fi
  read -r line
  trimmed_line="$(echo "$line" | awk '{$1=$1};1')"
  if [ -n "$trimmed_line" ]; then
    echo "$trimmed_line" > "${trimmed_dir}/title_num_to_rip.txt"
  fi
done
