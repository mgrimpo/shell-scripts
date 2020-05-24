#!/bin/bash

# parsing arguments / flags
# following https://pretzelhands.com/posts/command-line-flags
OTHER_ARGUMENTS=()
for arg in "$@"
do
    case $arg in
        -n|--dry-run)
            DRY_RUN=1
            shift # Remove -n / --dry-run from positional arguments
            ;;
        *)
            OTHER_ARGUMENTS+=("$1")
    esac
done


ERROR_OCURRED=false
LOG_FILE="move-to-own-folder.sh.log"
if [[ -f  "$LOG_FILE" ]] ; then
    rm "$LOG_FILE"
fi

for f in *\(*\)*; do
  [[ -f "$f" ]] || continue # skip if not regular file
  #dir="${f%.*}"
  dir="${f%)*}"
  dir="$dir"")"
  if [[ $DRY_RUN ]]; then
      echo "mv -i "'"'"$f"'"' '"'"$dir"'"'
  else
      printf "MOVE '%s'  TO '%s'\n" "$f" "$dir"
      mkdir -p "$dir"
      if [[ ! -d "$dir" ]]; then
          printf "The target directory '%s' could not be created. Skipping to next file" "$dir"
          continue # skip if no directory
      fi
      mv -i "$f" "$dir";
      if [[ -f "$dir/$f" ]]; then
          printf "Move successful\n"
      else
          printf "Error. File was not moved\n"
          ERROR_OCURRED=true
          printf "could not move %s" "$f" >> "$LOG_FILE"
      fi
  fi
  printf '\n'
done

if [[ "$ERROR_OCURRED" = true ]]; then
    printf "\nAN ERROR OCURRED, ONE OR MORE FILES COULD NOT BE MOVED! VIEW %s\n" "$LOG_FILE"
fi

if [[ $DRY_RUN ]]; then
    printf "\nThis was a DRY RUN\n"
fi
