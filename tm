#!/bin/bash
# author: Lukas Kluft (adapted from ubuntuusers.de)
# version: 27.03.2015
#
# purpose: attaches a running tmux session. if not running
# tmux server is started.

# check if session name is given. otherweise set name to "main"
if [[ -z $1 ]];then
    TMUX_SESSION=main
else
    TMUX_SESSION=$1
fi

# if the session is already running, just attach to it.
if tmux has-session -t $TMUX_SESSION; then
    TERM=xterm-256color tmux attach -t $TMUX_SESSION
else
    TERM=xterm-256color tmux new -s $TMUX_SESSION
fi
