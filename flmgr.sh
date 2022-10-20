#!/usr/bin/env bash

# flmgr
# file browser
# file browser in pure bash, built for hackability


#
# Editable values
#

# Should ideally be in env, but isnt in a lot of distros
EDITOR=nano
IMAGE_VIEWER=feh

# This is where you can specify actions for each filetype, see README for help
FILE_HANDLER() {
	HANDLE="${FILES[$Current]}"
	FILETYPE=$(file "${FILES[$Current]}")
	case $FILETYPE in
		*directory*) cd $HANDLE && clear && LIST_GET ;;
		*script*|*text*) $EDITOR "$HANDLE" ;;
		*image*) $IMAGE_VIEWER "$HANDLE" ;;
		*) ERROR 'Dont know how to handle file:'"$PWD/$HANDLE" && CUSTOM_CURRENT ;;
	esac
	BAR_DRAW
}

#
# Main
#

trap 'RESTORE_TERM' INT TERM

trap 'echo flmgr exited' EXIT

trap 'GET_TERM' WINCH



# Programmatically allocate foreground colors
# This is show-offy and less customisable, but it takes the line count by like 5 so its all good
for code in {0..7}
do
	declare f$code=$(tput setaf $code)
done

# Programmatically allocate background colors
for code in {0..7}
do
	declare b$code=$(tput setab $code)
done

# restore terminal
reg=$(tput sgr0)

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
		Current=$(($Length - 1))
	fi
	if [[ $Current -le 0 ]];
	then
		Current=0
	fi

	tput sgr0
	printf '\e['$TOPY';'$TOPX'H'
	Count=1
	while [[ $Count -lt $(( LINES - 2 )) ]];
	do
		printf '\e['$((TOPY + $Count))';'$TOPX'H\e[2K'
		case "${FILES[$(($Count + $Current))]}" in
			'Desktop'|'Downloads'|'Pictures'|'Videos') printf "$f4${FILES[$((Count + Current))]}$reg" ;;
			*) printf "${FILES[$((Count + Current))]}" ;;
		esac
		printf '\e[B'
		Count=$((Count + 1))
	done
	printf '\e['$TOPY';'$TOPX'H\e[2K'
	echo -n "$f0$b7${FILES[$Current]}$reg"
	printf '\e[H\e[2K'
	printf '\e['$(($TOPY + $Length))';0H'
}

LIST_GET() {
	FILES=()
	FILES+=(*)
	Length=${#FILES[@]}
	Current=0
}

BAR_DRAW() {
	printf '\e['$LINES';0H'
	Count=0
	tput setaf 0 setab 7
	printf "$BAR_VAR"
	currdir=$(pwd | sed 's#.*/##')
	printf '\e['$LINES';0H'"$PWD/${FILES["$Current"]}"
	tput setaf 7 setab 0
}

UP_DIR() {
	cd ../
	clear
	LIST_GET
}



INPUT() {
	escape_char=$(printf "\u1b")
	read -rsn1 mode
	if [[ $mode == $escape_char ]];
	then
		read -rsn2 mode
	fi
#	clear
	case $mode in
		'[A'|'k'|'')	Current=$(($Current - 1)) && BAR_DRAW ;;			# up 1 item
		'[B'|'j'|'')	Current=$(($Current + 1)) && BAR_DRAW ;;			# down 1 item
		'[C'|'l'|'')	FILE_HANDLER ;;							# Handle file options, such as opening, cd etc
		'c'|'C')	CUSTOM_CURRENT ;;						# Run custom command on file, same as unknown filetype
		'[D'|'h')	FROM_DIR=${PWD/*\//} && UP_DIR && HIGHLIGHT_CURR && BAR_DRAW ;;	# cd ../ and start at dir just exited
		'[6'|'J')	BAR_DRAW && Current=$(($Current + $(( LINES - 3 )) )) ;;	# PgDn
		'[5'|'K')	BAR_DRAW && Current=$(($Current - $(( LINES - 3 )) )) ;;	# PgUp
		'[4')		Current=$Length ;;						# End
		'[H')		Current=0 ;;							# Home
		'q'|'Q') RESTORE_TERM ;;							# clean exit
	esac
	LIST_DRAW 3 2 $Length $Current
}


ERROR() {
	ERRORMSG=$1
	printf '\e['$LINES';'$(($COLUMNS - ${#ERRORMSG} + 1))'H'
	echo -n "$f7$b1$ERRORMSG$reg"
}

HIGHLIGHT_CURR() {
	Count=0
	until [[ "$FROM_DIR" == "${FILES["$Count"]}" ]]
	do
		echo -n "${FILES["$Count"]}"
		echo "$FROM_DIR"
		Count=$(( Count + 1 ))
	done
	echo $Count
	Current=$Count
}

CUSTOM_CURRENT() {
	printf '\e[H'
	printf 'Run custom command on '"${FILES["$Current"]}"': '
	read COMMAND
	$COMMAND "${FILES["$Current"]}"
}




GET_TERM
SETUP_TERM
LIST_GET
LIST_DRAW 3 2 $Length 0
BAR_DRAW
while true;
do
	INPUT
done
