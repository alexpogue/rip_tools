#!/usr/bin/env zsh

source ~/.zshrc

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"

directories=()
while IFS= read -r line; do
  directories+=("$line")
done < <(find "$DVD_RIP_DIR" -type d -mindepth 1 -maxdepth 1 | sort)

for dir in "${directories[@]}"; do
  trimmed_dir="$(echo "$dir" | awk '{$1=$1};1')"
  picked_title_file="${trimmed_dir}/title_mpls_file_to_rip.txt"
  echo "Titles for \"$(basename $trimmed_dir)\":"

  backup_dir_name="$(ls "${trimmed_dir}/backup/")"
  echo "backup_dir_name = $backup_dir_name"
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
    continue
  else
    echo -n "Which title to rip for \"$(basename $trimmed_dir)\"? "
  fi
  read -r line_num
  trimmed_line_num="$(echo "$line_num" | awk '{$1=$1};1')"
  echo "trimmed_line_num = $trimmed_line_num"
  if [ -n "$trimmed_line_num" ]; then
    echo "title_info_cache_file = $title_info_cache_file"
    line="$(awk "NR==$((trimmed_line_num + 1))" "${title_info_cache_file}")"
    echo "line = $line"
    if [[ -n "$line" ]]; then
      mpls_file="$(awk -F', ' '{print $NF}' <<< "$line")"
      echo "$mpls_file" > "${trimmed_dir}/title_mpls_file_to_rip.txt"
    else
      echo "Invalid line number."
    fi
  fi
done
