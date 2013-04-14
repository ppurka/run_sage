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
MY_SAGE_DIR="$HOME/Installations"  # Directory where all the sage versions#
                        # are installed. For instance, sage-5.8 may be    #
                        # installed as $MY_SAGE_DIR/sage-5.8              #
MAX_MEMORY=""           # The max amount of virtual memory in kilobytes   #
                        # allowed to Sage. Typically it should be at least#
                        # 1GB. For a limit of 1.5GB, set this to 1500000. #
                        # If not set, a default of 1/2 * RAM will be set. #
TERMINAL=""             # Your favorite terminal                          #
######################    END OF USER CONFIG   ############################


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
NULL="/dev/null"
self="${0##*\/}"
conf="$HOME/.config/$self.conf"
DIALOG="$(which dialog 2> $NULL)" || DIALOG="$(which whiptail 2> $NULL)"
MY_SAGE_CMD=""
#-----------------------------------------------------------------------}}}

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

# 4. Make sure we can create the config file.
if [[ ! -f "$conf" ]]; then
    mkdir -p "${conf%/*}" && touch "$conf" ||
        die "Could not create file $yellow$conf$normal"
fi
#-----------------------------------------------------------------------}}}


# Run script in $TERMINAL if user clicked on the file, or if run via
# a desktop file.
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

# Check the maximum memory set.
ram=$( free | sed -n -e '/^Mem:/{s/^Mem:[ ]*\([0-9]\{1,\}\) .*$/\1/p}' )
if [[ "$MAX_MEMORY" ]]; then
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
unset cols conf self rows last_used_ver ram ${COLORS[@]} COLORS MAX_MEMORY

# Execute the main command
exec $MY_SAGE_CMD ${@}

# vim: set ai et fdm=marker ff=unix sta sts=4 sw=4 ts=4 tw=75 :
