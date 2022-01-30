[[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]] && exec startx
[[ -f ~/.bashrc ]] && ~/.bashrc
