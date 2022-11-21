# flmgr.sh
## a fast, hackable file manager written in bash
flmgr.sh is a small, fast and most importantly modular file manager / browser, written in (almost) pure bash.  
It can also be used as a file picker with the ``-p`` flag

![alt text](https://raw.githubusercontent.com/armoar334/flmgr.sh/main/screenshot.png)

## Installing
```
git clone https://github.com/armoar334/flmgr.sh.git   
cd flmgr.sh  
mv flmgr.sh ~/.local/bin/ # Or other appropriate location in your PATH
```

## Usage
``flmgr.sh [-p]``

## Optional dependencies
> w3m: for w3m-img previews  
> xdotool: to display image in x11 / xwayland terminals  
> fbset: to display in frambuffer  

### Keybinds
>Up    / k : Scroll up  
>Down  / j : Scroll down  
>Right / l : Open file / folder  
>Left  / h : Go up a directory  
>C/c  : Run a custom command on a file  
>PgDn : Scroll up a page  
>PgUp : Scroll down a page  
>Home : Go to first file in folder  
>End : Go to last file in folder  
>/ : Search within directory  
  

## Hacking
See ``HACKING.md``
