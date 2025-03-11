#!/usr/bin/env bash

VERSION_PREFIX="output_"
RESOLUTIONS="480p 720p 1080p"
FILE_EXTENSION="mkv"
REMOTE_MOVIES_DIR="/media/devmon/Sandisk7/JellyfinMediaDest/Movies"

movie_title="$(< movietitle.txt)"

remote_movie_dir="${REMOTE_MOVIES_DIR}/${movie_title}"

echo "Creating directory $remote_movie_dir"
ssh -p527 casaos@192.168.0.83 "sudo mkdir -p \"${remote_movie_dir}\""

for resolution in $RESOLUTIONS; do
  local_file_name="${VERSION_PREFIX}${resolution}.${FILE_EXTENSION}"

  remote_file_path="${remote_movie_dir}/${movie_title} - ${resolution}.${FILE_EXTENSION}"

  echo "Copying to casaos's ${remote_movie_dir}/${local_file_name}"
  tar -c "$local_file_name" | ssh -p527 casaos@192.168.0.83 "sudo tar -x --no-same-owner -C \"$remote_movie_dir\""

  echo "renaming ${remote_movie_dir}/${local_file_name} to $remote_file_path"
  ssh -p527 casaos@192.168.0.83 "sudo mv \"${remote_movie_dir}/${local_file_name}\" \"${remote_file_path}\""
done
