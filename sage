#!/usr/bin/env bash

        #-----------------------------------------------------------#
        #   This program is used to start sage under ulimit         #
        #                                           -ppurka         #
        #-----------------------------------------------------------#

        #----------------- License: GPL-3 or later -----------------#
        # Copyright (C) 2013  P. Purkayastha                        #
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



##########################    USER CONFIG   ###############################
MY_SAGE_DIR="$HOME/Installations"   # Directory where all the sage versions
                                    # are installed. For instance, sage-5.8
                                    # may be installed as
                                    # $MY_SAGE_DIR/sage-5.8
TERMINAL=""                         # Your favorite terminal
######################    END OF USER CONFIG   ############################



#------------------------- Internal variables ----------------------------#
declare -A MY_SAGE_INSTALLATIONS
declare -a COLORS
declare -a MY_SAGE_VERSIONS
declare -i cols
declare -i rows
NULL="/dev/null"
DIALOG="$(which dialog 2> $NULL)" || DIALOG="$(which whiptail 2> $NULL)"
self="${0##*\/}"
conf="$HOME/.config/$self.conf"
MY_SAGE_CMD=""

#--------------- variables and functions from my_bash_functions --------{{{
green="\x1b[1;32m"
normal="\x1b[0m"
yellow="\x1b[1;33m"
COLORS=( green normal yellow )
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
bash --version | grep -q 'version 4' || die "Need bash version 4 or higher"

# 2. Check if user provided TERMINAL is valid.
if [[ "$TERMINAL" ]]; then
    TERMINAL="$(which $TERMINAL 2> $NULL)" ||
        die "$green$TERMINAL$normal not found in \$PATH."
fi

# 3. Check if dialog is present in the system.
[[ -z "$DIALOG" ]] &&
    die "Neither ${green}dialog$normal nor ${green}whiptail$normal was found in your \$PATH"

#-----------------------------------------------------------------------}}}


# Display help in xterm if user clicked on the file
if [[ "$DISPLAY" ]] && ! tty -s; then
    # first find a terminal
    if [[ -z "$TERMINAL" ]]; then
        for t in terminology urxvt konsole xterm; do
            if which $t >& $NULL; then
                TERMINAL="$t"
                unset t
                break
            fi
        done
    fi
    case $TERMINAL in
        *terminology) exec $TERMINAL -e "$(dirname "$0")/$(basename "$0") $@";;
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


if [[ ! -f "$conf" ]]; then
    mkdir -p "${conf%/*}" && touch "$conf" ||
        die "Could not create file $yellow$conf$normal"
fi

# Gather all the sage versions that are installed.
for d in "$MY_SAGE_DIR"/sage-[0-9].*; do
    if [[ -x "$d/sage" ]]; then
        MY_SAGE_VERSIONS+=( "${d#*-}" )
        MY_SAGE_INSTALLATIONS["${d#*-}"]="$d"
    fi
done

# Error checks
[[ -z "${MY_SAGE_VERSIONS[@]}" ]] && die "No sage installations found"

# Handle the case when it is not run as notebook
if [[  ${#MY_SAGE_VERSIONS[@]} -eq 1 || \
    ( "$1" && "$1" != "-n" && "$1" != "--notebook" ) ]]; then
    last_used_ver="$( cat $conf )"
    [[ "${MY_SAGE_INSTALLATIONS[${last_used_ver#*-}]}" ]] &&
        MY_SAGE_CMD="$last_used_ver/sage" ||
        MY_SAGE_CMD="${MY_SAGE_INSTALLATIONS[${MY_SAGE_VERSIONS[0]}]}/sage"
else
    out=$( get_sage_list )
    determine_dialog_spacing
    out="$( $DIALOG --stdout --title "Choose a Sage Installation" \
                --radiolist "Choose a Sage Installation" \
                $rows $cols $(( $rows - 4 )) ${out}
          )"
    [[ $? -ne 0 ]] && exit
    MY_SAGE_CMD="${MY_SAGE_INSTALLATIONS[$out]}/sage"
    echo "${MY_SAGE_INSTALLATIONS[$out]}" > "$conf"
    echo
    info "Proceeding with $green$MY_SAGE_CMD$normal\n"
fi

# TODO: make the max memory user configurable
ulimit -v 3000000 # 3.0G of max virtual memory

# Remove cruft from the environment
unset DIALOG MY_SAGE_DIR MY_SAGE_INSTALLATIONS MY_SAGE_VERSIONS NULL TERMINAL
unset cols conf self rows last_used_ver ${COLORS[@]} COLORS

# Execute the main command
exec $MY_SAGE_CMD ${@}
