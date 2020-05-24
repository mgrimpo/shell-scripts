#!/bin/bash

# This script moves files to folders with a name that matches the beginning of
# the filename, before a separator character. The default separator is '.', so
# that files are moved to a folder matching their filename without the
# extension:
#       'example.jpg' and 'example.txt' will be moved to the folder 'example'.
# This script greedily matches the longest possible sequence before the separator:
#       'example.txt.old' will be moved to the folder 'example.txt'



# Globals
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(greadlink -m $(dirname $0))
readonly ARGS="$@"
# the character that separates the folder name from the rest of the file name
SEP='.'
# whether or not to include the separator character at the end of the folder name
INCLUDE_SEP=false

ERROR_OCURRED=false

LOG_FILE="move-to-own-folder.sh.log"

OTHER_ARGUMENTS=()

# parsing arguments / flags
# following https://pretzelhands.com/posts/command-line-flags
parse_arguments(){
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
}

delete_old_log() {
    if [[ -f  "$LOG_FILE" ]] ; then
        rm "$LOG_FILE"
    fi
}

print_affected_files() {
    printf 'The following files will be processed:\n'
    shopt -s nullglob
    for f in *"$SEP"*; do
        printf '%s\n' "$f"
    done
    shopt -u nullglob
    printf '\n'
}

directory_name_from_filename() {
    local filename=$1

    local dir="${filename%$SEP*}"
    [[ $INCLUDE_SEP = true ]] && dir="$dir""$SEP";
    echo "$dir"
}

create_target_directory() {
    local dir=$1
    mkdir -p "$dir"
    if [[ ! -d "$dir" ]]; then
        printf "The target directory '%s' could not be created. Skipping to next file" "$dir"
        dir=''
    fi
    echo "$dir"
}

move_file() {
    local file=$1
    local dir=$2
    local MV_ERROR=$(mv -i "$file" "$dir" 2>&1 /dev/null)
    if [[ ! $MV_ERROR ]]; then
        printf "Move successful\n"
    else
        printf "Error. File was not moved\n"
        ERROR_OCURRED=true
        printf "could not move '%s' : %s\n" "$f" "$MV_ERROR" >> "$LOG_FILE"
    fi
}

print_error_notice() {
    if [[ "$ERROR_OCURRED" = true ]]; then
        printf "\nAN ERROR OCURRED, ONE OR MORE FILES COULD NOT BE MOVED! VIEW %s\n" "$LOG_FILE"
    fi
}

print_dry_run_notice() {
    if [[ $DRY_RUN = true ]]; then
        printf "\nThis was a DRY RUN\n"
    fi
}

main() {
    parse_arguments $ARGS
    print_affected_files
    local f
    for f in *"$SEP"*; do
        [[ -f "$f" ]] \
            || continue # skip if not regular file
        dir=$(directory_name_from_filename "$f")
        printf "MOVE '%s'  TO '%s'\n" "$f" "$dir"
        [[ $DRY_RUN = true ]] \
            && continue
        delete_old_log
        [[ $(create_target_directory "$dir") ]] \
            || continue
        move_file "$f" "$dir"
        printf '\n'
    done
    print_error_notice
    print_dry_run_notice
}

main
