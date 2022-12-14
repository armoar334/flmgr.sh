# Hacking
Now time for the fun part! flmgr.sh is designed to be easily modified to fit your needs / wants.  

### Custom file opening by filetype
Open ``flmgr.sh`` in your favourite text editor  
At the top of the file you will see a function called ``FILE_HANDLER``. This is where the file matching occurs.  
Lets run through adding a filetype to `FILE_HANDLER``. For this example i will add a match for PNG images  
Run ``file`` on a file of the desired filetype
```
example@exampler $ file screenshot.png
screenshot.png: PNG image data, 1920 x 1080, 8-bit/color RGB, non-interlaced
```
``file`` reports the data type of this file as ``PNG image data``, so lets add a new case statement to ``FILE_HANDLER`` to open files that match this with the image viewer ``feh``  
First, below the ``EDITOR`` variable, add another variable called ``IMAGE_VIEWER``, and set it to equal ``feh``

Now, in ``FILE_HANDLER`` you should see a section of code that looks like this:  
```
FILE_HANDLER() {
        HANDLE="${FILES[$Current]}"
        FILETYPE=$(file "${FILES[$Current]}")
        case $FILETYPE in
                *directory*) cd $HANDLE && clear && LIST_GET ;;
                *script*|*text*) $EDITOR "$HANDLE" ;;
                *) ERROR 'Dont know how to handle file:'"$PWD/$HANDLE" && CUSTOM_CURRENT ;;
        esac
}
```
We will be adding our new file match between the lines beginning ``*script*|*text*)`` and ``*)``  
Add a new line that starts  
``*image*)``  
After this, we will use our ``IMAGE_VIEWER`` variable to open matching files, like this:  
``*image*) $IMAGE_VIEWER``  
After this, we must add the ``HANDLE`` variable. It must be surrounded by double quotes "" to ensure that the file is opened:  
``*image*) $IMAGE_VIEWER "$HANDLE"``  
Finally, add ``;;`` to the end of the line, to close the case statement:  
``*image*) $IMAGE_VIEWER "$HANDLE" ;;``  
The case statement should now look like this:
```
case $FILETYPE in
	*directory*) cd $HANDLE && clear && LIST_GET ;;
	*script*|*text*) $EDITOR "$HANDLE" ;;
	*image*) $IMAGE_VIEWER "$HANDLE" ;;
	*) ERROR 'Dont know how to handle file:'"$PWD/$HANDLE" && CUSTOM_CURRENT ;;
esac
```

### Custom previewer
Create a function named after the filetype you intend to preview, i.e for .md files ``DRAW_MD``  
Add a match to the case statement in ``SUB_ACTIONS``  
```
*.md*) DRAW_MD ;;
```
copy the following into the main body of your function:  
```
DRAW_MD() {
	text_var=$()
        wide_space=$(( $(( COLUMNS / 2 )) - 1 ))
        wide_text=$(( COLUMNS / 2 ))
        printf "\e[2;0H"
        oldifs=$IFS
        while IFS= read -r line; do
                printf '\e['$wide_space'C%s\n' "${line::$wide_text}"
        done <<< "$text_var"
        IFS=$oldifs
}
```
Now in the ``$text_var`` subshell, add a ``head -$(( LINES - 2 )) "${FILES[$Current]}"`` and pipe it to yourformatting program:  
```
text_var=$(head -$(( LINES - 2 )) "${FILES[$Current]}" | glow )
```
Now when you hover over a .md file, it will be fed into glow and printed as formatted output next to the main file browser  


### Custom input
See the ``INPUT`` function  
It reads one character, and if that character is an escape character, read one more. This allows for not only regular character input, but also reading characters such as arrow keys.  
To see what the character for a certain key is, press Ctrl-V and then the character. You will get one of three results:  

### ``[C`` Style  
These are comprised of two parts:  
(the  character may not render in your browser, for reference it is a single character that looks like a caret and a open square bracket: ^[)  
- A ````, which is a single character. This is the escape code, it is handled by the case statement. It is also the raw data from the ``Esc`` key, making it the only key that cannot be cased.  
- The two characters ``[C``, a square bracket and then a letter or number, this is cased by the main statement, and can be seen handling the arrow key input.
  
  
### ``D`` Style  
These characters are a single character, they represent keys that you would find on a keyboard, such as letters, numbers and symbols. They can be cased directly as can be seen with hjkl and C in the main statement.  
  
  
### ```` Style
(Again, these may not render in your browser. They look like a caret and a letter: ``^E``)  
- The main difficulty with these characters is that they cannot be copy-pasted in most, if not all, terminals. This is because despite being one character they are displayed across two cells. The only way I have found to put them into the script is to use ``echo``, like this (using Ctrl-V to type the character):  
``echo ^E >> flmgr.sh``  
And then using Ctrl-K in nano to move the character to the case statement. Luckily these seem to be mostly used for Xinput commands, such as scroll wheel input, which in many terminal emulators will be intercepted by the terminal emulator itself.  
  
  
You can use these cases to handle almost all possible keyboard input, and using pipes to match multiple cases (again, can be seen in the arrow key cases) add new keybinds to existing commands.
  
Much of the other information can be found in the comments throughout the code. If you need to make a major modification then you probably know more then I do!  
Pull requests welcome, but im not a particularly active user or Github or Git at all, so you might be left waiting a little while.  
Happy Hacking!  
