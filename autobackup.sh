#!/usr/bin/env zsh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"
source ~/.zshrc

function play_beep_sound() {
  echo -n -e \\a
}

function wait_for_new_volume() {
  original_volume_ls="$(ls /Volumes/)"
  num_new_volumes=0
  while [ "$num_new_volumes" -eq 0 ]; do
    new_volumes="$(diff -u <(echo "$original_volume_ls") <(ls /Volumes) | grep "^+" | grep -v "+++" | sed '/^$/d' | cut -b2-)"
    num_new_volumes="$(grep -c . <<< "$new_volumes")"
    if [ "$num_new_volumes" -eq 0 ]; then
      >&2 play_beep_sound
      sleep 3
    fi
  done
  if [ "$num_new_volumes" -gt 1 ]; then
    2>&1 echo "Error: Found 2 new volumes. Expected only 1. Volumes:"
    2>&1 echo "$new_volumes"
    return 1
  fi

  echo "$new_volumes"
}

function backup_discs_loop() {
  while true; do
    echo "Waiting for a new disc to be inserted..."
    volume_name="$(wait_for_new_volume)"
    backup_dir="${DVD_RIP_DIR}/${volume_name}/backup/${volume_name}"
    if [ -d "$backup_dir" ]; then
      echo "Warning: already found backup directory in $backup_dir. Press enter to continue and risk overwriting"
      read -p "Press enter to continue. Ctrl-C to exit."
    fi
    mkdir -p "$backup_dir"
    echo "backing up to $backup_dir, monitor with:"
    echo "while true; do du -d0 -h ${backup_dir}; sleep 15; done"
    makemkvcon backup disc:${volume_name} "${backup_dir}/"
    echo "done, check logs, and eject and insert another disc"
    play_beep_sound
    play_beep_sound
    play_beep_sound
  done
}

backup_discs_loop
