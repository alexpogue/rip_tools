#!/usr/bin/env bash

video_file="$1"

ffprobe_output="$(ffprobe -v quiet -print_format json -show_format -show_streams "$video_file")"

audio_codec="$(echo "$ffprobe_output" | jq -r 'if has("streams") then (first(.streams[] | select(.codec_type == "audio").codec_name) // null) else null end')"
[ "$?" -eq 0 ] || exit 1
video_codec="$(echo "$ffprobe_output" | jq -r 'if has("streams") then (first(.streams[] | select(.codec_type == "video").codec_name) // null) else null end')"
[ "$?" -eq 0 ] || exit 2
video_width="$(echo "$ffprobe_output" | jq 'if has("streams") then (first(.streams[] | select(.codec_type == "video").coded_width) // null) else null end')"
[ "$?" -eq 0 ] || exit 3
video_height="$(echo "$ffprobe_output" | jq 'if has("streams") then (first(.streams[] | select(.codec_type == "video").coded_height) // null) else null end')"
[ "$?" -eq 0 ] || exit 4

echo "audio: $audio_codec"
echo "video: $video_codec"
echo "resolution: ${video_width}:${video_height}"




