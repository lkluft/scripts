#!/bin/bash
# author: Lukas Kluft (adapted from ubuntuusers.de)
# version: 03.11.2014
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
command tmux has-session -t $TMUX_SESSION
if [ $? -eq 0 ]; then
    echo "Session $TMUX_SESSION already exists. Attaching."
    sleep 1
    command tmux attach -t $TMUX_SESSION
    exit 0;
else
    command tmux new -s $TMUX_SESSION
fi
