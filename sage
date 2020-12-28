#!/usr/bin/env bash

        #-----------------------------------------------------------#
        #   This program is used to start sage under ulimit         #
        #                                           -ppurka         #
        #-----------------------------------------------------------#

        #----------------- License: GPL-3 or later -----------------#
        # Copyright (C) 2013-2020  P. Purkayastha                   #
        # Contact: ppurka _at_ gmail _dot_ com                      #
        # This program comes with ABSOLUTELY NO WARRANTY;           #
        # This is free software, and you are welcome to redistribute#
        # it under certain conditions;                              #
        #                                                           #
        # For a brief summary of the license see the file COPYING   #
        # that is distributed with this program.                    #
        #                                                           #
        # For the full text of the license see                      #
        # http://www.gnu.org/licenses/gpl-3.0.html                  #
        #-----------------------------------------------------------#



#-----------: Golden rule of thumb for the user - from here onwards :-----#
#                       "No touching. Only seeing"                        #
#-------------------------------------------------------------------------#

#------------------------- Internal variables --------------------------{{{
declare -A MY_SAGE_INSTALLATIONS
declare -a COLORS
declare -a MY_SAGE_VERSIONS
declare -i cols
declare -i ram
declare -i rows
declare    sagever
NULL="/dev/null"
self="${0##*\/}"
conf="$HOME/.config/$self.conf"
DIALOG="$(which dialog 2> $NULL)"
MY_SAGE_CMD=""
user_conf="${conf%/*}/run_sage.conf"
#-----------------------------------------------------------------------}}}

#--------------- variables and functions from my_bash_functions --------{{{
green="\x1b[1;32m"
normal="\x1b[0m"
pink="\x1b[1;35m"
red="\x1b[1;31m"
yellow="\x1b[1;33m"
COLORS=( green normal pink red yellow )
# Print out information.
# Usage: info "Whatever you want to print"
info(){
    echo -e "  $yellow*$normal ${@}"
}
# Print out error information.
# Usage: Err "For printing errors"
# Usage: Err -w "For printing warnings"
Err(){
    local color="$red" msg="ERROR"
    [[ "$1" = "-w" ]] && color="$pink" && msg="WARNING" && shift
    echo -e "  $color*$normal [$color $msg!!$normal ] ${@}" >&2
}
die() {
    Err "$@"
    exit 1
}
#-----------------------------------------------------------------------}}}



#------------------------ Sanity checks --------------------------------{{{
# 1. Check for a minimum value of bash. Need associative arrays from ver. 4
bash --version | egrep -q 'version [4-9]' || die "Need bash version 4 or higher"

# 2. Check if dialog is present in the system.
[[ -z "$DIALOG" ]] &&
    die "Could not find ${green}dialog$normal in your \$PATH. Please install dialog."

# 3. Make sure we can create the config file.
if [[ ! -f "$conf" ]]; then
    mkdir -p "${conf%/*}" && touch "$conf" ||
        die "Could not create file $yellow$conf$normal"
fi
if [[ ! -f "$user_conf" ]]; then
    # config dir has been created. Try to create another config file.
    touch "$user_conf" ||
        die "Could not create file $yellow$user_conf$normal."
    cat <<END > "$user_conf"
# run_sage config file
#
# Directory where all the sage versions are installed. For instance,
# sage-5.8 may be installed as $MY_SAGE_DIR/sage-5.8
# Default: empty
# my_sage_dir=""
#
# The max amount of virtual memory allowed to Sage. Typically it should be
# at least 1GB. Format is of the form: <number>[kKmMgG], examples being 2G,
# 3000m, etc. For a limit of 1.5GB, you can set this to 1500000, or
# 1500000k or 1500M or 1.5G. If not set, a default of 1/2 * RAM will be
# used.
# max_memory=""
#
# Your favorite terminal. You can give the terminal name, or the full PATH
# to the terminal.
# Default: empty
# terminal=""
#
END
    info "It looks like you are running this script $green$self$normal for
    the first time!
    Please set the 'my_sage_dir' variable in the configuration file:
    ${yellow}$user_conf$normal
    and re-run this script."
    exit 0
fi

# 4. Import user configs
source "$user_conf"
: ${MY_SAGE_DIR:=${my_sage_dir}}
: ${MAX_MEMORY:=${max_memory:-""}}
: ${TERMINAL:=${terminal:-""}}
unset my_sage_dir max_memory terminal


# 5. Check if user provided TERMINAL is valid.
if [[ "$TERMINAL" ]]; then
    TERMINAL="$(which $TERMINAL 2> $NULL)" ||
        die "$green$TERMINAL$normal not found in \$PATH."
fi
#-----------------------------------------------------------------------}}}

# Run script in $TERMINAL if user clicked on the file, or if run via
# a desktop file.
if [[ "$DISPLAY" ]] && ! tty -s; then
    # first find a terminal
    if [[ -z "$TERMINAL" ]]; then
        for t in terminology urxvt konsole gnome-terminal xterm; do
            if which $t >& $NULL; then
                TERMINAL="$t"
                unset t
                break
            fi
        done
    fi
    case "$TERMINAL" in
        *terminology|*gnome-terminal) args="${@}" # a bad hack for disappearing arguments.
            exec $TERMINAL -e "$(dirname "$0")/$(basename "$0") ${args}";;
        *urxvt) exec $TERMINAL -pe "" -e "$(dirname "$0")/$(basename "$0")" $@;;
        *)      exec $TERMINAL -e "$(dirname "$0")/$(basename "$0")" $@;;
    esac
fi

#-------------------------- Internal functions -------------------------{{{
# Usage: determine_dialog_spacing
determine_dialog_spacing()
{
    local out="$( $DIALOG --stdout --print-maxsize )"
    out="${out#*: }"; out="${out/\,}"
    rows="$(( ${out% *} - 7 ))"
    cols="$(( ${out#* } - 7 ))"
}

# Usage: get_max_memory <value>
# Output: output in kB
get_max_memory()
{
    local mem="$1"
    case "$mem" in
        [0-9\.]*[kK]) mem="${mem:0:-1}" ;;
        [0-9\.]*[mM]) mem=$(awk "BEGIN{print ${mem:0:-1}*1024}") ;;
        [0-9\.]*[gG]) mem=$(awk "BEGIN{print ${mem:0:-1}*1024*1024}") ;;
        [0-9\.]*)     ;;
        *)            return 1;;
    esac
    echo "${mem%.*}" # Remove floating point
}

# Usage: get_sage_list
# Output: sage-ver sage-ver on/off sage-ver2 sage-ver2 on/off ....
get_sage_list()
{
    local last_used_ver="$( cat $conf )"
    for s in ${MY_SAGE_VERSIONS[@]}; do
        if [[ "$last_used_ver" = "${MY_SAGE_INSTALLATIONS[$s]}" ]]; then
            echo -n "$s $s on "
        else
            echo -n "$s $s off "
        fi
    done
}
#-----------------------------------------------------------------------}}}


# Gather all the sage versions that are installed.
for d in "$MY_SAGE_DIR"/sage-[0-9].* "$MY_SAGE_DIR/sage" \
    "$MY_SAGE_DIR/sage-git"; do
    if [[ -x "$d/sage" ]]; then
        dtmp="${d##*/}"
        MY_SAGE_VERSIONS+=( "${dtmp#*-}" )
        MY_SAGE_INSTALLATIONS["${dtmp#*-}"]="$d"
    fi
done

# Error checks
[[ -z "${MY_SAGE_VERSIONS[@]}" ]] && die "No sage installations found"

# Handle the case when it is not run as notebook
declare last_used_ver=""
if [[ -f "$conf" ]]; then
    last_used_ver="$(< "$conf")"
    [[ -n "$last_used_ver" && -x "${last_used_ver}/sage" ]] || last_used_ver=""
fi

if [[ ${#MY_SAGE_VERSIONS[@]} -eq 1 ||
    ( "$1" && "$1" != "-n" && "$1" != "--notebook" ) ]]; then
    if [[ -z "$last_used_ver"           || \
          "${last_used_ver}" != "${MY_SAGE_INSTALLATIONS[${MY_SAGE_VERSIONS[0]}]}" ]]; then
        MY_SAGE_CMD="${MY_SAGE_INSTALLATIONS[${MY_SAGE_VERSIONS[0]}]}"
    else
        MY_SAGE_CMD="${last_used_ver}"
    fi

else
    sagever=$( get_sage_list )
    determine_dialog_spacing
    sagever="$( $DIALOG --stdout --title "Choose a Sage Installation" \
                --radiolist "Choose a Sage Installation" \
                $rows $cols $(( $rows - 4 )) ${sagever}
          )"
    [[ $? -ne 0 ]] && exit
    MY_SAGE_CMD="${MY_SAGE_INSTALLATIONS[$sagever]}"
fi
[[ "$(< "$conf")" != "$MY_SAGE_CMD" ]] &&
    echo "${MY_SAGE_CMD}" > "$conf"
MY_SAGE_CMD+="/sage"
info "Proceeding with $green$MY_SAGE_CMD$normal\n"

# Check the maximum memory set.
ram=$( free | sed -n -e '/^Mem:/{s/^Mem:[ ]*\([0-9]\{1,\}\) .*$/\1/p}' )
if [[ "$MAX_MEMORY" ]]; then
    MAX_MEMORY=$(get_max_memory $MAX_MEMORY) ||
        die "$MAX_MEMORY: Invalid memory specification."
    if [[ $MAX_MEMORY -gt $ram ]]; then
        Err -w "The maximum memory set is more than the amount of RAM you
    have in your system. This can be harmful, unless you have enough SWAP
    space to make up for the lack of RAM"
    fi
else
    MAX_MEMORY=$(( $ram/2 ))
fi
ulimit -v $MAX_MEMORY

# Remove cruft from the environment
unset DIALOG MY_SAGE_DIR MY_SAGE_INSTALLATIONS MY_SAGE_VERSIONS NULL TERMINAL
unset ${COLORS[@]} COLORS MAX_MEMORY
unset cols conf d dtmp self rows last_used_ver ram user_conf
unset -f Err die info determine_dialog_spacing get_max_memory get_sage_list

# Execute the main command
exec $MY_SAGE_CMD ${@}

# vim: set ai et fdm=marker ff=unix sta sts=4 sw=4 ts=4 tw=75 :
