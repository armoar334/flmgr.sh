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
			*image*|*bitmap*) $IMAGE_VIEWER "$HANDLE" ;;
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

startdir="$1"

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
	# Disable line wrapping
	printf '\e[?7l'
}

RESTORE_TERM() {
	# Show cursor
	printf '\e[?25h'
	# clear in case original buffer was changed i.e due to opening another program in flmgr
	clear
	# Enable line wrapping
	printf '\e[?7l'
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
		the_file="${FILES[$(($Count + $Current))]}"
		printf '\e['$((TOPY + $Count))';'$TOPX'H\e[2K'
		LIST_HIGH "$the_file"
		Count=$((Count + 1))
	done
	printf '\e[H\e[2K'
	printf '\e['$TOPY';'$TOPX'H\e[2K'
	printf "$f0$b7${FILES[$Current]}%-*s " "$(( $(( $COLUMNS / 2 )) - TOPX - 2 - ${#FILES[$Current]} ))"
}

# This is so i dont have to change every occurence of "ls -AF" and things each time i change something
LS_FUNC() {
if [[ "$SHOWHIDDEN" == "true" ]];
then
	# The sed statemnet removes the * from the end of filenames of executables, i should add the other (/=>@|) ones but i cba
	ls -AF | sed 's/*$//g'
else
	ls -F | sed 's/*$//g'
fi
}


LIST_GET() {
	FILES=()
	# This is difficult to customise bc of HIGHLIGHT_CURR
	readarray -t FILES < <(LS_FUNC)
	Longest=0
	for num in ${FILES[@]}
	do
		if [ ${#num} -gt $Longest ]
		then
			Longest=${#num}
		fi
	done
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
	FROM_DIR="${PWD/*\/}/"
	cd ../
	clear
	LIST_GET
	HIGHLIGHT_CURR
	DRAW_PAR
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
		# These next 4 seem to vary by keymap, so they may be unreliable. easy to fix locally, but hard to make "just work"
		'[6'|'J')	Current=$(($Current + $(( LINES - 3 )) )) ;;	# PgDn
		'[5'|'K')	Current=$(($Current - $(( LINES - 3 )) )) ;;	# PgUp
		'[4'|'[F')	Current=$Length ;;				# End
		'[H')		Current=0 ;;					# Home
		'/') SEARCH_FILES ;;						# Search for files within directory
		'q'|'Q') RESTORE_TERM ;;					# clean exit
	esac
	LIST_DRAW 3 2 $Length $Current
	BAR_DRAW
	case "${FILES[$Current]}" in
		*/*) DRAW_SUBD ;;
		*.sh*|*.txt*|*.md*) DRAW_TEXT ;;
		*) ;;
	esac
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

SEARCH_FILES(){
	searching=1
	search_term=''
	while [[ searching -eq 1 ]];
	do
		printf "\e[H$reg\e[2KSearch for: $search_term"
		read -rsn1 one_char
		if [[ $one_char == $escape_char ]];
		then
			read -rsn2 one_char
		fi
		case $one_char in
			''|'[A'|'[B') searching=0 ;;
			''|'[P') if [[ ${#search_term} -ge 1 ]]; then search_term=${search_term::-1}; fi ;;
			[*) ;;
			*) search_term="$search_term$one_char" ;;
		esac
		readarray -t FILES < <(LS_FUNC | grep -i "$search_term")
		Length=${#FILES[@]}
		LIST_DRAW 3 2 $Length 0
		BAR_DRAW
	done
}

DRAW_SUBD() {
	cd "${FILES[$Current]}"
	readarray -t SUB_FILES < <(LS_FUNC)
	cd ../
	printf "\e[2;"$(( $COLUMNS / 2 ))"H"
	Count=0
	while [[ $Count -le $(( $LINES - 3 )) ]];
	do
		sub_temp="${SUB_FILES["$Count"]}"
		LIST_HIGH "$sub_temp"
		printf "\e[${#SUB_FILES["$Count"]}D\e[B"
		Count=$(( $Count + 1 ))
	done
}

DRAW_TEXT() {
	text_var=$(head -$(( LINES - 3 )) "${FILES[$Current]}" )
	wide_space=$(( $(( $COLUMNS / 2 )) - 2 ))
	wide_text=$(( $COLUMNS / 2 ))
	printf "\e[2;0H"
	oldifs=$IFS
	while IFS= read -r line; do
		# This will regard escape sequences in printed text. idk how to fix this, and realistically
		# it is rare you will find raw escape sequences in a file, so im not really bothered about fixing it
		# this will print without escapes: 
		# printf '\e['$wide_space'C%s\n' "${line::$wide_text}"
		# but i kind of like sseeing colors in my files so ill keep it slighlty broken for now
		# ALSO this fucks up if there is no support for disabling line wrapping, like in termux
		printf "\e["$wide_space"C ${line::$wide_text}\n"
	done <<< "$text_var"
	IFS=$oldifs
}


LIST_HIGH() {
	case "$1" in
#		*document*|*text*) printf "$f1$b0$1$reg" ;;
#		*.png*|*.jp*g*) printf "$f2$b0$1$reg" ;;
		.*) printf "$f3$1$reg" ;;
		*/*) printf "$f4$1$reg" ;;
		*) printf "$1" ;;
	esac
}

CUSTOM_CURRENT() {
	printf '\e[H'
	printf 'Run custom command on '"${FILES["$Current"]}"': '
	read COMMAND
	$COMMAND "${FILES["$Current"]}"
}

if [[ -z "$startdir" ]];
then
	startdir="."
fi

if ! [[ -d "$startdir" ]];
then
	if ! [[ -e "$startdir" ]];
	then
		echo "Folder $startdir does not exist!"
		exit
	else
		echo "$startdir is not a folder!"
		exit
	fi
fi

cd "$startdir"

GET_TERM
SETUP_TERM
running=1
escape_char=$(printf "\u1b")
LIST_GET
LIST_DRAW 3 2 $Length 0
BAR_DRAW
case "${FILES[$Current]}" in
	*/*) DRAW_SUBD ;;
	*) ;;
esac
while [[ $running -eq 1 ]];
do
	INPUT
done
