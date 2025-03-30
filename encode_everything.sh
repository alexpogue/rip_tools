#!/usr/bin/env zsh

. ~/.zshrc

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ -z "$DVD_RIP_DIR" ]]; then
  source "$SCRIPT_DIR/config.sh"
fi

DELETE_BACKUP_DIR=1 #false
if [[ "$#" -ge 1 ]] && [[ "$1" == "-d" ]]; then
  DELETE_BACKUP_DIR=0 #true
fi

echo "DELETE_BACKUP_DIR = $DELETE_BACKUP_DIR"

echo "using DVD_RIP_DIR=$DVD_RIP_DIR"

movie_dir_names="$(find "$DVD_RIP_DIR" -type d -maxdepth 1 -mindepth 1 | awk -F/ '{print $NF}')"

num_movies="$(echo "$movie_dir_names" | grep -vce "^\s*$")"

for i in {0..$num_movies}; do
  movie_dir_name="$(echo "$movie_dir_names" | sed "${i}q;d")"

  echo "Running full encoding process on movie $movie_dir_name"

  echo "getting original from backup for movie $movie_dir_name"
  "${SCRIPT_DIR}/get_original_mkv_from_backup.sh" "$movie_dir_name"
  ret="$?"
  if [[ "$ret" -ne 0 ]] && [[ "$ret" -ne 4 ]]; then
    echo "Error getting original mkv, continue to next movie"
    continue
  fi
  if [[ "$ret" -eq 4 ]]; then
    echo "Original mkv already present, moving onto encoding"
  fi

  if [[ "$DELETE_BACKUP_DIR" -eq 0 ]]; then
    echo "Deleting backup directory, as specified by '-d' flag"
    movie_dir_full_path="${DVD_RIP_DIR}/${movie_dir_name}"
    rm -r "${movie_dir_full_path}/backup"
  fi

  echo "encoding mkv for movie $movie_dir_name"
  "${SCRIPT_DIR}/encode_original_mkv.sh" "$movie_dir_name"
  ret="$?"
  if [[ "$ret" -ne 0 ]]; then
    echo "Error encoding original mkv, continue to next movie"
    continue
  fi

  echo "uploading to server: movie $movie_dir_name"
  "${SCRIPT_DIR}/final_to_server.sh" "$movie_dir_name"
  ret="$?"
  if [[ "$ret" -ne 0 ]]; then
    echo "Error uploading mkv, continue to next movie"
    continue
  fi
done
