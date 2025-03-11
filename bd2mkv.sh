#!/usr/bin/env zsh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"
source ~/.zshrc

echo "$DVD_RIP_DIR"

while read -r index_bdmv_file; do
  movie_root_dir="$(cut -d'/' -f1-5 <<< "$index_bdmv_file")" 
  echo "checking $movie_root_dir..."
  makemkvcon info -r file:"$index_bdmv_file" | grep -i Mainfeature

# TODO:
# 1. Choose the correct Title,
# 2. rip it to $movie_root/original_mkv
# 3. continue below

  mkv_file_name="$(ls "$movie_root_dir/original_mkv/")"
  mkv_original_path="${movie_root_dir}/original_mkv/${mkv_file_name}"

  mkv_info="$(makemkvcon -r info "$mkv_original_path")"
  aac_lines="$(echo "$mkv_info" | grep ",5," | grep "A_AAC")"
  h264_lines="$(echo "mkv_info" | grep ",5," | grep "V_MPEG4/ISO/AVC")"

  ffmpeg_audio_flag="-c:a copy"
  ffmpeg_video_flag="-c:v copy"
  ffmpeg_subtitles_flag="-c:s copy"

  needs_encoding=1 #false

  if [[ $(grep -c "[^[:space:]]" <<< "$aac_lines") -eq 0 ]]; then
    ffmpeg_audio_flag="-c:a aac -ac 2"
    needs_encoding=0 #true
  fi
  if [[ $(grep -c "[^[:space:]]" <<< "$h264_lines") -eq 0 ]]; then
    ffmpeg_video_flag="-c:v libx264 -crf 18"
    needs_encoding=0 #true
  fi

  mkdir -p "${movie_root_dir}/encoded_mkv/"
  mkv_encoded_path="${movie_root_dir}/encoded_mkv/${mkv_file_name}"
  if [[ "$needs_encoding" -eq 0 ]]; then
    echo "${mkv_original_path} encoding..."
    ffmpeg -i "$mkv_original_path" -map 0 $ffmpeg_video_flag $ffmpeg_audio_flag $ffmpeg_subtitles_flag "$mkv_encoded_path"
  else
    echo "${mkv_original_path} already encoded properly, copying to encoded..."
    cp "$mkv_original_path" "$mkv_encoded_path"
  fi

# TODO: manually enter final jellyfin file name in a text file for use in next step.. Look it up here

# TODO: detect aspect ratio, e.g. if encoded file is 1080p:
# 1. copy it to "aspect_mkv" directory, named properly like ${mkv_file_name(without mkv suffix)}-1080p.mkv
# 2. run ffmpeg commands to reencode the original file to the new aspect ratio for whichever aspect ratios are still missing (same command as original encoding one, but with `-vf "scale=1280:720"` and friends added)

# TODO: Log to a file inside $movie_root_dir

done <<< $(find "$DVD_RIP_DIR" | grep BDMV/index.bdmv | grep -v "BDMV/BACKUP")
