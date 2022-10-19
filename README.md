# flmgr.sh
## a fast, hackable file manager written in bash
flmgr.sh is a small, fast and most importantly modular file manage / browser, written with a dependency on only bash and coreutils  

## Installing
```
git clone https://github.com/armoar334/flmgr.sh.git   
cd flmgr.sh  
mv flmgr.sh ~/.local/bin/ # Or other appropriate location in your PATH
```

## Usage
run ``flmgr.sh`` in a directory  

## Hacking
Now time for the fun part! flmgr.sh is designed to be easily modified to fit your needs / wants.  

### Custom file opening by filetype
Open ``flmgr.sh`` in your favourite text editor  
At the top of the file you will see a function called ``FILE_HANDLER``. This is where the file matching occurs.  
Lets run through adding a filetype to ''FILE_HANDLER``. For this example i will add a match for PNG images  
Run ``file`` on a file of the desired filetype
```
example@exampler $ file screenshot.png
screenshot.png: PNG image data, 1920 x 1080, 8-bit/color RGB, non-interlaced
```
``file`` reports the data type of this file as ``PNG image data``, so lets add a new case statement to ``FILE_HANDLER`` to open files that match this with the image viewer ``feh``  
Then, below the ``EDITOR`` variable, add another variable called ``IMAGE_VIEWER``, and set it to equal ``feh``

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
