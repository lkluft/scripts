#!/bin/bash
# author: Lukas Kluft (adapted from ubuntuusers.de)
# version: 25.05.2014
#
# purpose: attaches a running tmux session. if not running
# tmux server is started.
TMUX_SESSION=main

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
