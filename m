#!/bin/bash
if [ ! -z $@ ]; then amixer -D pulse set Master "$@"% unmute > /dev/null; fi
if [ -z $@ ]; then amixer -D pulse set Master toggle > /dev/null; fi
