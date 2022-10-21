#!/usr/bin/env bash

# flmgr
# file browser
# file browser in pure bash, built for hackability


#
# Editable values
#

# Should ideally be in env, but isnt in a lot of distros
if [[ -z "$EDITOR" ]];
then
	EDITOR=nano
fi

# Other / Custom
IMAGE_VIEWER=feh
SHOWHIDDEN="true"

# This is where you can specify actions for each filetype, see README for help
FILE_HANDLER() {
	HANDLE="${FILES[$Current]}"
	FILETYPE=$(file "${FILES[$Current]}")
	if [[ -e "$HANDLE" ]];
	then
		case $FILETYPE in
			*directory*) cd $HANDLE && clear && LIST_GET ;;
			*script*|*text*|*.md*) $EDITOR "$HANDLE" ;;
			*image*) $IMAGE_VIEWER "$HANDLE" ;;
			*) ERROR 'Dont know how to handle file:'"$PWD/$HANDLE" && CUSTOM_CURRENT ;;
		esac
	else
		ERROR "File $HANDLE does not exist!"
	fi
	BAR_DRAW
}

#
# Main
#

trap 'RESTORE_TERM' INT TERM

trap 'echo flmgr exited' EXIT

trap 'GET_TERM && BAR_DRAW' WINCH

# Programmatically define terminal colors, saves a few lines

for code in {0..7}
do
	declare f$code=$(printf '\e[3'$code'm')
	declare b$code=$(printf '\e[4'$code'm')
done

reg=$(printf '\e[0m')

GET_TERM(){
	read -r LINES COLUMNS < <(stty size)
	BAR_VAR=""
	for num in $(seq 1 $COLUMNS)
	do
		BAR_VAR=$(printf "$BAR_VAR ")
	done
}

SETUP_TERM() {
	# Switch to alternate buffer
	printf '\e[?1049h'
	# Clear and move to 0,0
	printf '\e[2J\e[H'
	# Hide cursor
	printf '\e[?25l'
	#Get length
}

RESTORE_TERM() {
	# Show cursor
	printf '\e[?25h'
	# clear in case original buffer was changed i.e due to opening another program in flmgr
	clear
	# Return to original buffer
	printf '\e[?1049l'
	exit
}

LIST_DRAW() {
	TOPX=$1
	TOPY=$2
	Length=$3
	Current=$4
	printf '\e[?25l'
#Length sanitization
	if [[ $Length -ge ${#FILES[@]} ]];
	then
		Length=${#FILES[@]}
	fi

#Current sanitization
	if [[ $Current -ge $Length ]];
	then
		Current=$(( $Length - 1 ))
	fi
	if [[ $Current -le 0 ]];
	then
		Current=0
	fi

	printf '\e[0m'
	printf '\e['$TOPY';'$TOPX'H'
	Count=0
	while [[ $Count -lt $(( LINES - 2 )) ]];
	do
		printf '\e['$((TOPY + $Count))';'$TOPX'H\e[2K'
		case "${FILES[$(($Count + $Current))]}" in
			.*) printf "$f3${FILES[$(($Count + Current))]}$reg" ;;
			'Desktop'|'Downloads'|'Pictures'|'Videos') printf "$f4${FILES[$((Count + Current))]}$reg" ;;
			*) printf "${FILES[$((Count + Current))]}" ;;
		esac
		Count=$((Count + 1))
	done
	printf '\e[H\e[2K'
	printf '\e['$TOPY';'$TOPX'H\e[2K'
	printf "$f0$b7${FILES[$Current]}"
}

LIST_GET() {
	FILES=()
	# This needs to be more customisable, as atm it wont ever show hidden files and stuff
	if [[ "$SHOWHIDDEN" == "true" ]];
	then
		shopt -s dotglob
		FILES+=(*)
		shopt -u dotglob
	else
		FILES+=(*)
	fi
	Length=${#FILES[@]}
	Current=0
}

BAR_DRAW() {
	printf '\e['$LINES';0H'
	Count=0
	printf "$f0$b7"
	printf "$BAR_VAR"
	currdir=${PWD/*\//}
	printf '\e['$LINES';0H'"($(( Current + 1 ))/$Length) $PWD/${FILES["$Current"]}"
	# The $(( $Current + 1 )) is because arrays are 0 indexed
	printf "$reg"
}

UP_DIR() {
	FROM_DIR=${PWD/*\//}
	cd ../
	clear
	LIST_GET
	HIGHLIGHT_CURR
}



INPUT() {
	read -rsn1 mode
	if [[ $mode == $escape_char ]];
	then
		read -rsn2 mode
	fi
#	clear
	case $mode in
		'[A'|'k'|'')	Current=$(($Current - 1)) ;;			# up 1 item
		'[B'|'j'|'')	Current=$(($Current + 1)) ;;			# down 1 item
		'[C'|'l'|'')	FILE_HANDLER ;;					# Handle file options, such as opening, cd etc
		'c'|'C')	CUSTOM_CURRENT ;;				# Run custom command on file, same as unknown filetype
		'[D'|'h')	UP_DIR && BAR_DRAW ;;				# cd ../ and start at dir just exited
		'[6'|'J')	Current=$(($Current + $(( LINES - 3 )) )) ;;	# PgDn
		'[5'|'K')	Current=$(($Current - $(( LINES - 3 )) )) ;;	# PgUp
		'[4'|'[F')	Current=$Length ;;				# End
		'[H')		Current=0 ;;					# Home
		# These last 4 seem to vary with the keymap, so they may be unreliable. easy to fix locally, but hard to make "just work"
		'q'|'Q') RESTORE_TERM ;;					# clean exit
	esac
	LIST_DRAW 3 2 $Length $Current
	BAR_DRAW
}

# Send an error
ERROR() {
	ERRORMSG=$1
	printf '\e['$LINES';'$(($COLUMNS - ${#ERRORMSG} + 1))'H'
	printf "$f0$b1$ERRORMSG$reg"
}

# Highlight the current folder before moving up a directory
HIGHLIGHT_CURR() {
	Count=0
	while [[ $Count -le ${#FILES[@]} ]];
	do
		if [[ "$FROM_DIR" == "${FILES["$Count"]}" ]];
		then
			Current=$Count
		fi
		echo "${FILES["$Count"]} $Count"
		Count=$(( Count + 1 ))
	done
}

CUSTOM_CURRENT() {
	printf '\e[H'
	printf 'Run custom command on '"${FILES["$Current"]}"': '
	read COMMAND
	$COMMAND "${FILES["$Current"]}"
}

GET_TERM
SETUP_TERM
running=1
escape_char=$(printf "\u1b")
LIST_GET
LIST_DRAW 3 2 $Length 0
BAR_DRAW
while [[ $running -eq 1 ]];
do
	INPUT
done
