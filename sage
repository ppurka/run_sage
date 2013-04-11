#!/bin/bash

        #-----------------------------------------------------------#
        #   This program is used to start sage under ulimit         #
        #                                           -ppurka         #
        #-----------------------------------------------------------#


. `which my_bash_functions 2> /dev/null` || {
    echo -e " \x1b[1;31mError!\x1b[0m The script \x1b[1;32mmy_bash_functions\
\x1b[0m was not found in your \$PATH
        Please ensure that the script is available and executable"
    exit 1
}

self="${0##*\/}"
conf="$HOME/.config/$self.conf"
[[ ! -f "$conf" ]] && touch "$conf"

# Display help in xterm if user clicked on the file
if [[ "$DISPLAY" ]] && ! tty -s; then
    # first find a terminal
    myterm=""
    for terminal in terminology urxvt xterm; do
        if which $terminal >& /dev/null; then
            myterm="$terminal"
            unset terminal
            break
        fi
    done
    case $myterm in
        *terminology) exec $myterm -e "$(dirname "$0")/$(basename "$0") $@";;
        *urxvt) exec $myterm -pe "" -e "$(dirname "$0")/$(basename "$0")" $@;;
        *)      exec $myterm -e "$(dirname "$0")/$(basename "$0")" $@;;
    esac
fi


declare -A SAGE_INSTALLATIONS
declare -a SAGE_VERSIONS
for d in ~/Installations/sage-[0-9].*; do
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
