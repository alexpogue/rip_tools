#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"

movie_dir_name="$1"

main_movie_dir="${DVD_RIP_DIR}/${movie_dir_name}"

RESOLUTIONS="$(cat "${SCRIPT_DIR}/upload_resolutions.txt")"
FILE_EXTENSION="mkv"
REMOTE_MOVIES_DIR="/media/devmon/Sandisk7/JellyfinMediaDest/Movies"

movie_title="$(< "${main_movie_dir}/movietitle.txt")"

remote_movie_dir="${REMOTE_MOVIES_DIR}/${movie_title}"

echo "Creating directory $remote_movie_dir"
ssh -p527 casaos@192.168.0.83 "sudo mkdir -p \"${remote_movie_dir}\""

while read -r resolution; do
  local_file_name="${movie_title} - ${resolution}.${FILE_EXTENSION}"
  local_file_path="${main_movie_dir}/mkvs_encoded/${local_file_name}"

  if ! [ -f "$local_file_path" ]; then
    echo "File not found locally $local_file_path . Skipping $resolution resolution."
    continue
  fi

  echo "Uploading $local_file_path to the server..."

  cd "${main_movie_dir}/mkvs_encoded"
  tar -c "$local_file_name" | ssh -p527 casaos@192.168.0.83 "sudo tar -x --no-same-owner -C \"$remote_movie_dir\""
  cd -

done <<< "$RESOLUTIONS"
