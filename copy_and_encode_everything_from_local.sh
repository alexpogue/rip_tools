#!/usr/bin/env zsh

. ~/.zshrc

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/config.sh"

movie_dir_names="$(find "$DVD_RIP_DIR" -type d -maxdepth 1 -mindepth 1 | awk -F/ '{print $NF}')"

num_movies="$(echo "$movie_dir_names" | grep -vce "^\s*$")"

dir_names_to_skip="$(< skip_dirs.txt)"

for i in {1..$num_movies}; do

  movie_dir_name="$(echo "$movie_dir_names" | sed "${i}q;d")"

  if grep -q "$movie_dir_name" <<< "$dir_names_to_skip"; then
    echo "found $movie_dir_name in dir_names_to_skip.. Skipping"
    continue
  fi
  main_movie_dir="${DVD_RIP_DIR}/${movie_dir_name}"
  movie_file_name="$(< ${main_movie_dir}/movietitle.txt)"

  if ! [[ -f "${main_movie_dir}/title_num_to_rip.txt" ]]; then
    echo "didn't find ${main_movie_dir}/title_num_to_rip.txt, skipping"
    continue
  fi
  if ! [[ -f "${main_movie_dir}/movietitle.txt" ]]; then
    echo "didn't find ${main_movie_dir}/movietitle.txt, skipping"
    continue
  fi

  encoded_mkv_dir="${main_movie_dir}/mkvs_encoded"

  echo "Copying and encoding locally for movie $movie_dir_name"

  # If we have all the encode resolutions, can quit early
  encode_resolution_pairs="$(< "$SCRIPT_DIR/encode_resolutions.txt")"
  resolution_names="$(awk '{print $1}' <<< "$encode_resolution_pairs")"

  needs_encoding=0 #false
  while read -r resolution_name; do
    final_movie_already_there="$(ls "$encoded_mkv_dir" | grep "${resolution_name}\.mkv$")"
    if [[ "$(grep -cve '^\s*$' <<< "$final_movie_already_there")" -gt 0 ]]; then
      echo "Already found movie ${movie_dir_name} with resolution $resolution_name in $encoded_mkv_dir."
      continue
    else
      echo "Couldn't find ${movie_dir_name} with resolution $resolution_name in $encoded_mkv_dir.. Marking movie as 'needs encoding'"
      needs_encoding=1 # true
    fi
  done <<< "$resolution_names"

  if [[ "$needs_encoding" -eq 1 ]]; then
    echo "Found at least one encoding that needs to be done (see above). Running the script"
  else
    echo "Found properly encoded movie. Skipping to next movie"
    continue
  fi

  # here we need to do the full encode, so copy locally, and encode_everything

  echo "Copying $main_movie_dir to ${LOCAL_DVD_RIP_DIR}"
  cp -r "${main_movie_dir}" "${LOCAL_DVD_RIP_DIR}/"

  echo "Running encode all on ${LOCAL_DVD_RIP_DIR}"
  TMP_DVD_RIP_DIR="$DVD_RIP_DIR"
  export DVD_RIP_DIR="$LOCAL_DVD_RIP_DIR"
  ./encode_everything.sh -d
  export DVD_RIP_DIR="$TMP_DVD_RIP_DIR"

  echo "Copying mkv_original back to DVD_RIP_DIR dir (${LOCAL_DVD_RIP_DIR}/${movie_dir_name}/mkv_original -> ${main_movie_dir}/mkv_original)"
  mkdir -p "${main_movie_dir}/mkv_original"
  cp -rf "${LOCAL_DVD_RIP_DIR}/${movie_dir_name}/mkv_original"/* "${main_movie_dir}/mkv_original/"

  echo "Copying mkvs_encoded back to DVD_RIP_DIR dir (${LOCAL_DVD_RIP_DIR}/${movie_dir_name}/mkvs_encoded -> ${main_movie_dir}/mkvs_encoded)"
  mkdir -p "${main_movie_dir}/mkvs_encoded"
  if [[ "$(ls -1 "${LOCAL_DVD_RIP_DIR}/${movie_dir_name}/mkvs_encoded" 2> /dev/null | grep -c "\.mkv$")" -eq 0 ]]; then
    echo "ERROR: No mkvs_encoded after encoding attempt"
  else
    cp -rf "${LOCAL_DVD_RIP_DIR}/${movie_dir_name}/mkvs_encoded"/* "${main_movie_dir}/mkvs_encoded/"
  fi

  echo "Deleting $movie_dir_name from ${LOCAL_DVD_RIP_DIR}"
  rm -r "${LOCAL_DVD_RIP_DIR}/${movie_dir_name}"
done
