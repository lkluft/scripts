#!/bin/bash
[[ -z $@ ]] && amixer -qD pulse set Master toggle \
            || amixer -qD pulse set Master "$@"% unmute
