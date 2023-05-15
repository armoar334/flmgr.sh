#!/usr/bin/env bash

get_term() {
	IFS='[;' read -sp $'\e7\e[9999;9999H\e[6n\e8' -d R -rs _ lines columns
	half_col=$(( columns / 2 ))
}

setup_term() {
	printf '\e[?1049h'
	printf '\e[?25l'
	stty -echo
}

restore_term() {
	printf '\e[?1049l'
	printf '\e[?25h'
	stty echo
}

get_dir() {
	shopt -s dotglob
	temp=(*)
	files=()
	# Add / to folders
	for item in "${temp[@]}"
	do
		if [[ -d "$item" ]];
		then
			files+=("$item/")
		else
			files+=("$item")
		fi
	done
	
	# Sort folders first
	temp=("${files[@]}")
	folders=()
	files=()
	for item in "${temp[@]}"
	do
		case "$item" in
			*'/') folders+=("$item") ;;
			*) files+=("$item") ;;
		esac
	done
	files=("${folders[@]}" "${files[@]}")
}

draw_list() {
	printf '\e[2H\r'
	for i in $(seq 1 $(( lines - 2 )) )
	do
		printf '\e[K\n'
	done

	printf '\e[2H\r'
	for line in "${files[@]:$top_item:$(( lines - 2 ))}"
	do
		case "$line" in
			*'/') printf '\e[34m\e[2C%s\e[0m\e[K\n' "$line" ;;
			*) printf '\e[2C%s\e[K\n' "$line" ;;
		esac
	done
	printf '\e[2K'

	printf '\e[2H\r'
	printf '\e[2C\e[7m%*s\e[0m' "$half_col"
	printf '\r\e[2C\e[7m%s\e[0m\n' "${files[$top_item]}"
}

draw_bar() {
	printf '\e[%sH\r' "$lines"
	printf '\e[7m%*s\e[0m' "$columns"
	printf '\r\e[7m%s%s\e[0m' "($((top_item+1))/${#files[@]})" "$(pwd)"
}

into() {
	case "${files[$top_item]}" in
		*'/')
			cd "${files[$top_item]}"
			clear
			get_dir
			top_item=0
			;;
		*) 
			if $picker_mode
			then
				running=false
				return_file="${files[$top_item]}"
			fi ;;
	esac
}

above() {
	cd ../
	clear
	get_dir
	top_item=0
}

search() {
	search_term=''
	old_files=("${files[@]}")
	searching=true
	while $searching;
	do
		printf '\e[H\e[K%s' "Search: $search_term"
		read -rsn1 char
		case "$char" in
			[[:print:]]) search_term+="$char" ;;
			$'\c?'|$'\ch') [[ "${#search_term}" -gt 0  ]] && search_term="${search_term:0:-1}" ;;
			$'\e'|'') searching=false ;;
		esac
		readarray -t files < <(printf '%s\n' "${old_files[@]}" | grep -i "$search_term" )
		draw_list
		draw_bar
	done
}

input() {
	read -rsn1 char
	case "$char" in
		$'\e') 
			read -rsn2 -t 0.01 char
			case "$char" in 
				'[A') ((top_item-=1)) ;;
				'[B') ((top_item+=1)) ;;
				'[C') into ;;
				'[D') above ;;
				'[5') read -rsn1 _ && ((top_item-=(lines-3)));; # PgUp
				'[6') read -rsn1 _ && ((top_item+=(lines-3)));; # PgDn
				'[H') top_item=0 ;;
				'[F') top_item="$(( ${#files[@]} - 1 ))" ;;
			esac ;;
		'k') ((top_item-=1)) ;;
		'j') ((top_item+=1)) ;;
		'l') into ;;
		'h') above ;;
		'q'|'Q') running=false ;;
		'/') search ;;
		'') into ;;
	esac
	[[ top_item -le 0 ]] && top_item=0
	[[ top_item -ge "$(( ${#files[@]} - 1 ))" ]] && top_item="$(( ${#files[@]} - 1 ))"
}

prev_func() {
	# Clear preview area
	
	case "${files[$top_item]}" in
		*'/') prev_subd ;;
		*.md|*.txt|*.sh) prev_text ;;
		*.png) prev_imag ;;
	esac
}

prev_text() {
	local text_prev=$(head -$(( lines - 2 )) "${files[$top_item]}" | col -x )
	printf '\e[2H'
	while IFS= read -r line
	do
		printf '\e[%sC\e[K' "$(( half_col + 3 ))" 
		echo "${line::$(( half_col - 4 ))}"
	done <<<"$text_prev"
}

prev_subd() {
	cd "${files[$top_item]}"
	local text_prev=(*)
	printf '\e[2H'
	for line in "${text_prev[@]:0:$(( lines - 3 ))}"
	do
		printf '\e[%sC\e[K' "$(( half_col + 3 ))" 
		echo "${line::$(( half_col - 4 ))}"
	done
}

prev_imag() {
	true
}


for opt in "$@"
do
	case "$opt" in
		'-p') picker_mode=true ;;
		*) [[ -d "$opt" ]] && cd "$opt" ;;
	esac
done

main=$(cat <<'EOF'
setup_term
top_item=0
get_dir
get_term

running=true
while $running;
do
	echo -n "$(draw_list && draw_bar && prev_func )"
	input
done

restore_term

EOF
)

if $picker_mode
then
	eval "$main" 1>&2
	echo "$return_file"
else
	eval "$main"
fi
