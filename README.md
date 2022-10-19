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
This section will cover  
- Custom file opening by filetype
- Custom coloring for certain file / folder names


### Custom file opening by filetype
Open ``flmgr.sh`` in your favourite text editor  
At the top of the file you will see a function called ``FILE_HANDLER``. This is where the file matching occurs.  
Lets run through adding a filetype to ''FILE_HANDLER``. For this example i will add a match for PNG images  
1. run ``file`` on a file of the desired filetype
```
example@exampler $ file screenshot.png
screenshot.png: PNG image data, 1920 x 1080, 8-bit/color RGB, non-interlaced
```
