#!/bin/bash

# This script moves files to folders with a name that matches the beginning of
# the filename, before a separator character. The default separator is '.', so
# that files are moved to a folder matching their filename without the
# extension:
#       'example.jpg' and 'example.txt' will be moved to the folder 'example'.
# This script greedily matches the longest possible sequence before the separator:
#       'example.txt.old' will be moved to the folder 'example.txt'



# default values

# the character that separates the folder name from the rest of the file name
SEP='.'

# whether or not to include the separator character at the end of the folder name
INCLUDE_SEP=false

ERROR_OCURRED=false

LOG_FILE="move-to-own-folder.sh.log"

# parsing arguments / flags
# following https://pretzelhands.com/posts/command-line-flags
OTHER_ARGUMENTS=()
for arg in "$@"
do
    case $arg in
        -n|--dry-run)
            DRY_RUN=true
            shift # Remove -n / --dry-run from positional arguments
            ;;
        -s=*|--sep=*)
            SEP="${arg#*=}"
            shift
            ;;
        -i|--include-sep)
            INCLUDE_SEP=true
            shift
            ;;
        *)
            OTHER_ARGUMENTS+=("$1")
    esac
done


if [[ -f  "$LOG_FILE" ]] ; then
    rm "$LOG_FILE"
fi


for f in *"$SEP"*; do
  [[ -f "$f" ]] || continue # skip if not regular file
  #dir="${f%.*}"
  dir="${f%$SEP*}"
  [[ $INCLUDE_SEP = true ]] && dir="$dir""$SEP";
  if [[ $DRY_RUN = true ]]; then
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

if [[ $DRY_RUN = true ]]; then
    printf "\nThis was a DRY RUN\n"
fi
