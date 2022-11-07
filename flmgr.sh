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
SCROLL_LOOP="false"

# Use scope.sh from ranger
USE_SCOPE="false"
if [[ "$USE_COPE" == "true" ]] && ! [[ -e ~/.config/ranger/scope.sh ]];
then
	USE_SCOPE="false"
fi

# This is where you can specify actions for each filetype, see README for help
FILE_HANDLER() {
	HANDLE="${FILES[$Current]}"
	FILETYPE=$(file "${FILES[$Current]}")
	if [[ -e "$HANDLE" ]];
	then
		case $FILETYPE in
			*directory*) cd "$HANDLE" && clear && LIST_GET ;;
			*script*|*text*|*.md*) $EDITOR "$HANDLE" ;;
			*image*|*bitmap*) $IMAGE_VIEWER "$HANDLE" ;;
			*) ERROR 'Dont know how to handle file:'"$PWD/$HANDLE" && CUSTOM_CURRENT ;;
		esac
	else
		ERROR "File $HANDLE does not exist!"
	fi
	printf '\e[?7l'
	BAR_DRAW
}

#
# Main
#

trap 'RESTORE_TERM' INT TERM

#trap 'echo flmgr exited' EXIT

trap 'REDRAW' WINCH

# Programmatically define terminal colors, saves a few lines

startdir="$1"

for code in {0..7}
do
	declare f$code=$(printf '\e[3'$code'm')
	declare b$code=$(printf '\e[4'$code'm')
	declare h$code=$(printf '\e[9'$code'm') # Brighter forground colors
done

reg=$(printf '\e[0m')

REDRAW() {
	GET_TERM
	LIST_DRAW $Length $Current
	BAR_DRAW
}


GET_TERM(){
	read -r LINES COLUMNS < <(stty size)
	BAR_VAR=""
	for num in $(seq 1 $COLUMNS)
	do
		BAR_VAR=$(printf "$BAR_VAR ")
	done
	wide_space=$(( $(( COLUMNS / 2 )) - 1 ))
	wide_text=$(( COLUMNS / 2 ))
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
	# reset colors
	printf '\e[0m'
	exit
}

LIST_DRAW() {
	TOPX=3
	TOPY=2
	Length=$1
	Current=$2
	printf '\e[?25l'

	if [[ "$SCROLL_LOOP" == "true" ]];
	then
	#Length sanitization
		if [[ $Length -ge ${#FILES[@]} ]];
		then
			Length=${#FILES[@]}
		fi

	#Current sanitization
		if [[ $Current -ge $Length ]];
		then
			Current=0
		fi
		if [[ $Current -lt 0 ]];
		then
			Current=$(( $Length - 1 ))
		fi
	else
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
	fi

	printf '\e['$TOPY';'$TOPX'H\e[2K'
	printf "$f0$b7${FILES[$Current]}%-*s " "$(( $(( $COLUMNS / 2 )) - TOPX - 2 - ${#FILES[$Current]} ))"
	printf '\e[0m'
	printf '\e['$TOPY';'$TOPX'H'

	# This can be replaced with the IFS trick i used for the preview stuff, but i arrays are a pain. would be a good speed improvement over slower connections like an ssh
	Count=0
	for Count in $( seq 1 $(( LINES - 2 )) );
	do
		the_file="${FILES[$(($Count + $Current))]}"
		printf "\e["$(( $TOPY + $Count ))";"$TOPX"H\e[2K"
		LIST_HIGH "$the_file"
	done
	printf '\e[H\e[2K'
}

# This is so i dont have to change every occurence of "ls -AF" and things each time i change something
LS_FUNC() {
if [[ "$SHOWHIDDEN" == "true" ]];
then
	# The sed statemnet removes the * from the end of filenames of executables, i should add the other (/=>@|) ones but i cba
	ls -AF | sed -e 's/*$//g' -e 's/\@$/\//g'
else
	ls -F | sed -e 's/*$//g' -e 's/\@$/\//g'
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
}

INPUT() {
	read -rsn1 mode
	if [[ $mode == $escape_char ]];
	then
		read -rsn2 mode
	fi
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
		'e') LIST_GET ;;						# Refresh current view, for use after search
		'q'|'Q') RESTORE_TERM ;;					# clean exit
	esac
	LIST_DRAW $Length $Current
	BAR_DRAW
	SUB_ACTIONS
}

SUB_ACTIONS() {
	case "${FILES[$Current]}" in
		*/*) DRAW_SUBD ;;
		*.png*|*.jpg|*.jpeg*|*.bmp*|*.gif*) DRAW_IMAGE "${FILES[$Current]}" & ;;
		*.txt*|*.sh*) DRAW_TXT ;;
		*.md*) DRAW_MD ;;
		*) if [[ "$USE_SCOPE" == "true" ]]; then SCOPE_FILE; fi ;;
	esac
}

# Use scope to preview file
SCOPE_FILE() {
	rm /tmp/flmgerr
	PWD=$(pwd)
	text_var=$(~/.config/ranger/scope.sh "$PWD/${FILES[$Current]}" "$(( COLUMNS / 2 ))" "$(( LINES - 3 ))" "/dev/null" False 2> /tmp/flmgerr )
	text_var=$(head -$(( LINES - 3 )) <<< "$text_var")
	if ! [[ -z "$(cat /tmp/flmgerr)" ]];
	then
		ERROR "$(tail -1 /tmp/flmgerr )"
		return
	fi
	printf '\e[2;0H'
	oldifs=$IFS
	while IFS= read -r line; do
		printf '\e['$wide_space'C%s\n' "$line"
	done <<< "$text_var"
	IFS=$oldifs
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
		LIST_DRAW $Length 0
		BAR_DRAW
	done
}

# These are all preview things

DRAW_SUBD() {
	cd "${FILES[$Current]}"
	SUB_FILES=$(LS_FUNC | head -$(( LINES - 2 )) )
	cd ../
	printf "\e[2;0H"
	oldifs=$IFS
	while IFS= read -r line; do
		printf '\e['$wide_space'C'
		LIST_HIGH "$line"
		printf "\n"
	done <<< "$SUB_FILES"
	IFS=$oldifs
}

DRAW_MD() {
	text_var=$(head -$(( LINES - 3 )) "${FILES[$Current]}" )
	text_var=$(sed -e 's/#.*$/'$f3'&'$reg'/g' \
			-e 's/>.*$/'$f6'&'$reg'/g' \
			-e 's/```.*```/'$f1'&'$reg'/g' -e 's/```//g'\
			-e 's/``.*``/'$f1'&'$reg'/g' <<< "$text_var")
	printf "\e[2;0H"
	oldifs=$IFS
	while IFS= read -r line; do
		printf '\e['$wide_space'C%s\n' "${line::$wide_text}"
	done <<< "$text_var"
	IFS=$oldifs
}

DRAW_TXT() {
	# just an observation, but this is ridiculously fast. i ran it in a window on a vertical 4k screen and it did it instantly. i also tried it horizontal on an 8k virtual display and had the same result. wild
	# 5 mins later, just tried it on a vertical 8k screen. INSTANT. the whole script for flmgr rendered out INSTANTLY. im gonna use this for everyting from now
	text_var=$(head -$(( LINES - 2 )) "${FILES[$Current]}" )
	printf "\e[2;0H"
	oldifs=$IFS
	while IFS= read -r line; do
		printf '\e['$wide_space'C\e[32m%s\n' "${line::$wide_text}"
	done <<< "$text_var"
	IFS=$oldifs
}

DRAW_IMAGE() {
	# All stole from https://github.com/gokcehan/lf/wiki/Previews
#	CACHE=$1
	w3m_paths=(/usr/{local/,}{lib,libexec,lib64,libexec64}/w3m/w3mi*)
	read -r w3m _ < <(type -p w3mimgdisplay "${w3m_paths[@]}")
	if [[ -z "$w3m" ]] || ! [[ -x "$(command -v xdotool)" ]];
	then
		return
	fi
	if ! [[ -z "$DISPLAY" ]];
	then
		# For x11 / xwayland
		export $(xdotool getactivewindow getwindowgeometry --shell)
	else
		# For framebuffer (fbterm / tty etc)
		fbmode=$(fbset | grep mode | grep x | sed 's/mode //g' | tr -d '"' | sed 's/x/ /g')
		WIDTH=$(cut -d' ' -f1 <<< "$fbmode")
		HEIGHT=$(cut -d' ' -f2 <<< "$fbmode")
	fi

	CELL_W=$(( WIDTH / COLUMNS ))
	CELL_H=$(( HEIGHT / LINES ))
	HALF_WIDTH=$(( CELL_W * $(( COLUMNS / 2 )) ))
	HALF_HEIGHT=$(( CELL_H * LINES ))
	read -r img_width img_height < <("$w3m" <<< "5;${CACHE:-$1}")
	printf "\e[2;"$(( COLUMNS / 2 ))"H"
	((img_width > HALF_WIDTH)) && {
		((img_height=img_height*HALF_WIDTH/img_width))
		((img_width=HALF_WIDTH))
	}

	((img_height > HALF_HEIGHT)) && {
		((img_width=img_width*HALF_HEIGHT/img_height))
		((img_height=HALF_HEIGHT))
	}

	X_POS=$(( CELL_W * $(( COLUMNS / 2 )) ))
	Y_POS=$CELL_H

	printf '0;1;%s;%s;%s;%s;;;;;%s\n3;\n4\n' \
		${X_POS:-0} \
		${Y_POS:-0} \
		"$img_width" \
		"$img_height" \
		"${CACHE:-$1}" | "$w3m" &>/dev/null
}

LIST_HIGH() {
	case "$1" in
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
	oldcurr=$Current
	LIST_GET
	Current=$oldcurr
}

if ! [[ -z "$startdir" ]];
then
	if ! [[ -d "$startdir" ]];
	then
		if ! [[ -e "$startdir" ]];
		then
			echo "Folder $startdir does not exist!"
		else
			base_name=$(basename "$startdir")
			dir="$(echo $startdir | sed 's/\(.*\)\/\(.*\)\.\(.*\)$/\1/')"
			if [[ -d "$dir" ]];
			then
				cd "$dir"
			fi
			FROM_DIR="${startdir/*\/}"
		fi
	else
		cd "$startdir"
	fi
fi

GET_TERM
SETUP_TERM
running=1
escape_char=$(printf "\u1b")
LIST_GET
Current=0
# If supplied arguent is a file start with it as the current item
if ! [[ -z "$FROM_DIR" ]];
then
	HIGHLIGHT_CURR
fi
LIST_DRAW $Length $Current
BAR_DRAW
SUB_ACTIONS

case "${FILES[$Current]}" in
	*/*) DRAW_SUBD ;;
	*) ;;
esac
while [[ $running -eq 1 ]];
do
	INPUT
done
