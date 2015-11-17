#!/bin/bash
# author: Lukas Kluft (adapted from ubuntuusers.de)
# version: 17.11..2015
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
    tmux attach -t $TMUX_SESSION
else
    tmux new -s $TMUX_SESSION
fi
