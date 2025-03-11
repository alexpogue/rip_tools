#!/usr/bin/env zsh

. ~/.zshrc

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"

movie_dir_name="$1"

main_movie_dir="${DVD_RIP_DIR}/${movie_dir_name}"

original_movie_encoding_dir="${main_movie_dir}/mkv_original"
if ! [[ -d "$original_movie_encoding_dir" ]]; then
  echo "Error: couldn't find original movie encoding dir $original_movie_encoding_dir"
  exit 1
fi

original_movie_matches="$(ls "$original_movie_encoding_dir" | grep ".mkv$")"
num_original_movie_matches="$(grep -cve '^\s*$' <<< "$original_movie_matches")"
if [[ "$num_original_movie_matches" -gt 1 ]]; then
  echo "Error: found more than one original movie in $original_movie_encoding_dir"
  exit 2
elif [[ "$num_original_movie_matches" -lt 1 ]]; then
  echo "Error: didn't find any original movies in $original_movie_encoding_dir"
  exit 3
fi
original_movie_file_name="$(echo "$original_movie_matches" | awk '{$1=$1};1')"
original_movie_file_path="${original_movie_encoding_dir}/${original_movie_file_name}"

resolution_aspect_ratio_pairs="$(< "${SCRIPT_DIR}/resolutions.txt")"

movie_file_name="$(< ${main_movie_dir}/movietitle.txt)"

encoded_mkv_dir="${main_movie_dir}/mkvs_encoded"
mkdir -p "$encoded_mkv_dir"

while read -r resolution_aspect_ratio_pairs; do
  resolution_name="$(awk '{print $1}' <<< "$resolution_aspect_ratio_pairs")"
  final_file_name="${movie_file_name} - ${resolution_name}.mkv"

  final_movie_already_there="$(ls "$encoded_mkv_dir" | grep "${resolution_name}\.mkv$")"
  if [[ "$(grep -cve '^\s*$' <<< "$final_movie_already_there")" -gt 0 ]]; then
    echo "Already found movie ${movie_dir_name} with resolution $resolution_name in $main_movie_dir."
    continue
  fi
  final_file_path="${encoded_mkv_dir}/${final_file_name}"

  mkv_info="$("${SCRIPT_DIR}/get_mkv_info.sh" "$original_movie_file_path")"
  aac_lines="$(echo "$mkv_info" | grep "aac")"
  h264_lines="$(echo "$mkv_info" | grep "h264")"

  original_movie_aspect_ratio="$(echo "$mkv_info" | grep "resolution" | cut -f2)"
  desired_aspect_ratio="$(awk '{print $2}' <<< "$resolution_aspect_ratio_pairs")"

  ffmpeg_audio_flag="-c:a copy"
  ffmpeg_video_flag="-c:v copy"
  ffmpeg_aspect_ratio_flags=""
  ffmpeg_subtitles_flag="-c:s copy"

  needs_encoding=0

  if [[ $(grep -cve '^\s*$' <<< "$aac_lines") -eq 0 ]]; then
    ffmpeg_audio_flag="-c:a aac -ac 2"
    needs_encoding=1
  fi
  if [[ $(grep -cve '^\s*$' <<< "$h264_lines") -eq 0 ]]; then
    ffmpeg_video_flag="-c:v libx264 -crf 18"
    needs_encoding=1
  fi
  if [[ "$original_movie_aspect_ratio" != "$desired_aspect_ratio" ]]; then
    ffmpeg_aspect_ratio_flags="-vf scale=${desired_aspect_ratio}"
    ffmpeg_video_flag="-c:v libx264 -crf 18"
    needs_encoding=1
  fi

  if [[ "$needs_encoding" -eq 1 ]]; then
    echo "Encoding $movie_dir_name : $resolution_name..."
    output_log_path="${encoded_mkv_dir}/${resolution_name}.out"
    ffmpeg_command="ffmpeg -i \"$original_movie_file_path\" -map 0 $ffmpeg_aspect_ratio_flags $ffmpeg_video_flag $ffmpeg_audio_flag $ffmpeg_subtitles_flag \"$final_file_path\""
    #echo "ffmpeg_command: $ffmpeg_command"
    #eval "$ffmpeg_command"
    zsh -c "$ffmpeg_command"
    #zsh -c "echo \"hi\"; exit 1"
    echo "Aspect Ratio Flags: $ffmpeg_aspect_ratio_flags"
    echo "Video Flags: $ffmpeg_video_flag"
    echo "Audio Flags: $ffmpeg_audio_flag"
    echo "Subtitles Flags: $ffmpeg_subtitles_flag"
      #-vf scale=1920:1080
    ffmpeg_cmd=(
      -i "$original_movie_file_path"
      -map 0
      #$ffmpeg_aspect_ratio_flags
      $ffmpeg_video_flag
      $ffmpeg_audio_flag
      $ffmpeg_subtitles_flag
      $final_file_path
    )
    #ffmpeg -i "$original_movie_file_path" -map 0 $ffmpeg_aspect_ratio_flags $ffmpeg_video_flag $ffmpeg_audio_flag $ffmpeg_subtitles_flag "$final_file_path"
    #zsh -c "ffmpeg ${ffmpeg_cmd[@]}"
    #echo "ffmpeg command: ffmpeg ${ffmpeg_cmd[@]}"
  else
    echo "$movie_dir_name is already in the correct format and resolution - copying to final file..."
    cp "$original_movie_file_path" "$final_file_path"
  fi
  echo "hello"

done <<< "$resolution_aspect_ratio_pairs"
