# flmgr.sh
## a fast, hackable file manager written in bash
flmgr.sh is a small, fast and most importantly modular file manager / browser, written in (almost) pure bash.  

![alt text](https://raw.githubusercontent.com/armoar334/flmgr.sh/main/screenshot.png)

## Installing
```
git clone https://github.com/armoar334/flmgr.sh.git   
cd flmgr.sh  
mv flmgr.sh ~/.local/bin/ # Or other appropriate location in your PATH
```

## Usage
``flmgr.sh ~/Downloads``  
``nano $(flmgr.sh -p)``

### Keybinds
>Up    / k : Scroll up  
>Down  / j : Scroll down  
>Right / l : Open file / folder  
>Left  / h : Go up a directory  
>PgDn : Scroll up a page  
>PgUp : Scroll down a page  
>Home : Go to first file in folder  
>End : Go to last file in folder  
>/ : Search within directory  
  

## Hacking
See ``HACKING.md``
