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



. `which my_bash_functions 2> /dev/null` || {
    echo -e " \x1b[1;31mError!\x1b[0m The script \x1b[1;32mmy_bash_functions\
\x1b[0m was not found in your \$PATH
        Please ensure that the script is available and executable"
    exit 1
}


##########################    USER CONFIG   ###############################
SAGE_DIR="$HOME/Installations" # Directory where all the sage versions are
                               # installed. For instance, sage-5.8 would be
                               # installed as $SAGE_DIR/sage-5.8
TERMINAL=""                    # Your favorite terminal
######################    END OF USER CONFIG   ############################



#------------------------- Internal variables ----------------------------#
declare -A SAGE_INSTALLATIONS
declare -a SAGE_VERSIONS
NULL="/dev/null"
DIALOG="$(which dialog 2> $NULL)" || DIALOG="$(which whiptail 2> $NULL)"
self="${0##*\/}"
conf="$HOME/.config/$self.conf"
SAGE_CMD=""

# Sanity checks
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


if [[ ! -f "$conf" ]]; then
    mkdir -p "${conf%/*}" && touch "$conf" ||
        die "Could not create file $yellow$conf$normal"
fi
for d in "$SAGE_DIR"/sage-[0-9].*; do
    if [[ -x "$d/sage" ]]; then
        SAGE_VERSIONS+=( "${d#*-}" )
        SAGE_INSTALLATIONS["${d#*-}"]="$d"
    fi
done


# Usage: get_sage_list
# Output: sage-ver sage-ver on/off sage-ver2 sage-ver2 on/off ....
get_sage_list()
{
    local last_used_ver="$( cat $conf )"
    for s in ${SAGE_VERSIONS[@]}; do
        if [[ "$last_used_ver" = "${SAGE_INSTALLATIONS[$s]}" ]]; then
            echo -n "$s $s on "
        else
            echo -n "$s $s off "
        fi
    done
}


# Error checks
[[ -z "${SAGE_VERSIONS[@]}" ]] && die "No sage installations found"

# Handle the case when it is not run as notebook
if [[  ${#SAGE_VERSIONS[@]} -eq 1 || \
    ( "$1" && "$1" != "-n" && "$1" != "--notebook" ) ]]; then
    last_used_ver="$( cat $conf )"
    [[ "${SAGE_INSTALLATIONS[${last_used_ver#*-}]}" ]] &&
        SAGE_CMD="$last_used_ver/sage" ||
        SAGE_CMD="${SAGE_INSTALLATIONS[${SAGE_VERSIONS[0]}]}/sage"
else
    out=$( get_sage_list )
    #TODO: replace displaymessage with $DIALOG?
    out="$( DISPLAY=""
        displaymessage --radiolist "Choose a Sage Installation" $out
        )"
    [[ $? -ne 0 ]] && exit
    SAGE_CMD="${SAGE_INSTALLATIONS[$out]}/sage"
    echo "${SAGE_INSTALLATIONS[$out]}" > "$conf"
fi

echo
info "Proceeding with $green$SAGE_CMD$normal\n"
ulimit -v 3000000 # 3.0G of max virtual memory
exec $SAGE_CMD ${@}
