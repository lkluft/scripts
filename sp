#!/bin/bash

#
# This is sp, the command-line Spotify controller. It talks to a running
# instance of the Spotify Linux client over dbus, providing an interface not
# unlike mpc.
#
# Put differently, it allows you to control Spotify without leaving the comfort
# of your command line, and without a custom client or Premium subscription.
#
# As an added bonus, it also works with ssh, at and cron.
#
# Example:
# $ sp weather girls raining men
# $ sp current
# Album   100 Hits Of The '80s
# Artist  The Weather Girls
# Title   It's Raining Men
# $ sp pause
#
# Alarm clock example:
# $ at 7:45 <<< 'sp bangarang'
#
# Remote example:
# $ ssh vader@prod02.nomoon.ta 'sp imperial march'
#
#
# Copyright (C) 2013 Wander Nauta
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software, to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# The software is provided "as is", without warranty of any kind, express or
# implied, including but not limited to the warranties of merchantability,
# fitness for a particular purpose and noninfringement. In no event shall the
# authors or copyright holders be liable for any claim, damages or other
# liability, whether in an action of contract, tort or otherwise, arising from,
# out of or in connection with the software or the use or other dealings in the
# software.
#

# CONSTANTS

SP_VERSION="0.1"
SP_DEST="org.mpris.MediaPlayer2.spotify"
SP_PATH="/org/mpris/MediaPlayer2"
SP_MEMB="org.mpris.MediaPlayer2.Player"

# SHELL OPTIONS

shopt -s expand_aliases

# UTILITY FUNCTIONS

function require {
  hash $1 2>/dev/null || {
    echo >&2 "Error: '$1' is required, but was not found."; exit 1;
  }
}

# COMMON REQUIRED BINARIES

# We need dbus-send to talk to Spotify.
require dbus-send

# Assert standard Unix utilities are available.
require grep
require sed
require cut
require tr

# 'SPECIAL' (NON-DBUS-ALIAS) COMMANDS

function sp-dbus {
  # Sends the given method to Spotify over dbus.
  dbus-send --print-reply --dest=$SP_DEST $SP_PATH $SP_MEMB.$1 ${*:2} > /dev/null
}

function sp-open {
  # Opens the given spotify: URI in Spotify.
  sp-dbus OpenUri string:$1
}

function sp-metadata {
  # Prints the currently playing track in a parseable format.

  dbus-send                                                                   \
  --print-reply                                  `# We need the reply.`       \
  --dest=$SP_DEST                                                             \
  $SP_PATH                                                                    \
  org.freedesktop.DBus.Properties.Get                                         \
  string:"$SP_MEMB" string:'Metadata'                                         \
  | grep -Ev "^method"                           `# Ignore the first line.`   \
  | grep -Eo '("(.*)")|(\b[0-9][a-zA-Z0-9.]*\b)' `# Filter interesting fiels.`\
  | sed -E '2~2 a|'                              `# Mark odd fields.`         \
  | tr -d '\n'                                   `# Remove all newlines.`     \
  | sed -E 's/\|/\n/g'                           `# Restore newlines.`        \
  | sed -E 's/(xesam:)|(mpris:)//'               `# Remove ns prefixes.`      \
  | sed -E 's/^"//'                              `# Strip leading...`         \
  | sed -E 's/"$//'                              `# ...and trailing quotes.`  \
  | sed -E 's/"+/|/'                             `# Regard "" as seperator.`  \
  | sed -E 's/ +/ /g'                            `# Merge consecutive spaces.`
}

function sp-current {
  # Prints the currently playing track in a friendly format.
  require column

  sp-metadata \
  | grep --color=never -E "(title)|(album)|(artist)" \
  | sed 's/^\(.\)/\U\1/' \
  | column -t -s'|'
}

function sp-eval {
  # Prints the currently playing track as shell variables, ready to be eval'ed
  require sort

  sp-metadata \
  | grep --color=never -E "(title)|(album)|(artist)|(trackid)|(trackNumber)" \
  | sort -r \
  | sed 's/^\([^|]*\)\|/\U\1/' \
  | sed -E 's/\|/="/' \
  | sed -E 's/$/"/' \
  | sed -E 's/^/SPOTIFY_/'
}

function sp-art {
  # Prints the artUrl.

  sp-metadata | grep "artUrl" | cut -d'|' -f2
}

function sp-display {
  # Calls display on the artUrl.

  require display
  display $(sp-art)
}

function sp-feh {
  # Calls feh on the artURl.

  require feh
  feh $(sp-art)
}

function sp-url {
  # Prints the HTTP url.

  TRACK=$(sp-metadata | grep "url" | cut -d'|' -f2 | cut -d':' -f3)
  echo "http://open.spotify.com/track/$TRACK"
}

function sp-clip {
  # Copies the HTTP url.

  require xclip
  sp-url | xclip
}

function sp-http {
  # xdg-opens the HTTP url.

  require xdg-open
  xdg-open $(sp-url)
}

function sp-help {
  # Prints usage information.

  echo "Usage: $0 [command]"
  echo "Control a running Spotify instance from the command line."
  echo ""
  echo "  sp play       - Play/pause Spotify"
  echo "  sp pause      - Pause Spotify"
  echo "  sp next       - Go to next track"
  echo "  sp prev       - Go to previous track"
  echo ""
  echo "  sp current    - Format the currently playing track"
  echo "  sp metadata   - Dump the current track's metadata"
  echo "  sp eval       - Return the metadata as a shell script"
  echo ""
  echo "  sp lyrics     - Print lyrics of currently playing track"
  echo ""
  echo "  sp art        - Print the URL to the current track's album artwork"
  echo "  sp display    - Display the current album artwork with \`display\`"
  echo "  sp feh        - Display the current album artwork with \`feh\`"
  echo ""
  echo "  sp url        - Print the HTTP URL for the currently playing track"
  echo "  sp clip       - Copy the HTTP URL to the X clipboard"
  echo "  sp http       - Open the HTTP URL in a web browser"
  echo ""
  echo "  sp open <uri> - Open a spotify: uri"
  echo "  sp search <q> - Start playing the best search result for the given query"
  echo ""
  echo "  sp version    - Show version information"
  echo "  sp help       - Show this information"
  echo ""
  echo "Any other argument will start a search (i.e. 'sp foo' will search for foo)."
}

function sp-search {
  # Searches for tracks, plays the first result.

  require curl

  Q="$@"
  SPTFY_URI=$( \
    curl -s -G  --data-urlencode "q=$Q" ws.spotify.com/search/1/track \
    | grep -E -o "spotify:track:[a-zA-Z0-9]+" -m 1 \
  )

  sp-open $SPTFY_URI

  # show which song was selected
  sleep 1
  sp-current
}

function sp-lyrics {
    # Prints lyrics of currently played song
    require curl
    require less

    # get artist and title from metadata function
    artist=$(sp-metadata | grep artist | cut -d "|" -f 2 | sed -e 's/ /+/g' -e 's/(.*)//')
    title=$(sp-metadata | grep title | cut -d "|" -f 2 | sed -e 's/ /+/g' -e 's/\[.*\]//')

    # write lyrics from makeitpersonal.co to temporary file
    lyrics=$(mktemp -t sp-lyrics.XXXXX)
    curl -s "http://makeitpersonal.co/lyrics?artist=$artist&title=$title" > $lyrics

    if grep -q "Sorry, We don't have lyrics for this song yet." "$lyrics";then
        # if no lyrics are found, try title without strings between paranthesis to get
        # song like "A-Punk (Album)"
        title=$(echo $title | sed 's/(.*)//')
        curl -s "http://makeitpersonal.co/lyrics?artist=$artist&title=$title" > $lyrics
        if grep -q "Sorry, We don't have lyrics for this song yet." "$lyrics";then
            # if no lyrics are fund, try title substring in front of first " - " to get
            # songs like "Rebel Yell - Remastered"
            title=$(echo $title | sed 's/+-+.*//')
            curl -s "http://makeitpersonal.co/lyrics?artist=$artist&title=$title" > $lyrics
            if grep -q "Sorry, We don't have lyrics for this song yet." "$lyrics";then
                echo "Sorry, We don't have lyrics for this song yet."
                exit
            fi
        fi
    fi

    # print artist, title and lyrics
    header=$(echo "#### $artist - $title ####" | sed -r 's/[+]+/ /g')
    sed -i "1i$header" $lyrics
    less -s $lyrics
    rm $lyrics
}

function sp-youtube() {
  # Search current track on youtube
  _yt() {
    local q="$(echo $@ | sed -e 's/+/%2B/g' -e 's/ /+/g')";
    ${BROWSER} "https://www.youtube.com/results?search_query=${q}" &> /dev/null &
  }

  eval "$(sp-eval)"
  _yt ${SPOTIFY_ARTIST} ${SPOTIFY_TITLE}
}

function sp-version {
  # Prints version information.

  echo "sp $SP_VERSION"
  echo "Copyright (C) 2013 Wander Nauta"
  echo "License MIT"
}

# 'SIMPLE' (DBUS-ALIAS) COMMANDS

alias sp-play="  sp-dbus PlayPause"
alias sp-pause=" sp-dbus Pause"
alias sp-next="  sp-dbus Next"
alias sp-prev="  sp-dbus Previous"

# DISPATCHER

# First, we connect to the dbus session spotify is on. This isn't really needed
# when running locally, but is crucial when we don't have an X display handy
# (for instance, when running sp over ssh.)

SPOTIFY_PID="$(pidof -s spotify)"
if [[ -z "$SPOTIFY_PID" ]]; then
  if type spotify &> /dev/null;then
      spotify &> /dev/null &
      exit 0
  else
      $BROWSER "https://play.spotify.com/" &> /dev/null &
      echo "Spotify started as browser session. No command line control possible"
      exit 1
  fi
fi

QUERY_ENVIRON="$(cat /proc/${SPOTIFY_PID}/environ | tr '\0' '\n' | grep "DBUS_SESSION_BUS_ADDRESS" | cut -d "=" -f 2-)"
if [[ "${QUERY_ENVIRON}" != "" ]]; then
  export DBUS_SESSION_BUS_ADDRESS="${QUERY_ENVIRON}"
fi

# Then we dispatch the command.

subcommand="$1"

if [[ -z "$subcommand" ]]; then
  # No arguments given, print help.
  sp-help
else
  # Arguments given, check if it's a command.
  if $(type sp-$subcommand > /dev/null 2> /dev/null); then
    # It is. Run it.
    shift
    eval "sp-$subcommand $@"
  else
    # It's not. Try a search.
    eval "sp-search $@"
  fi
fi
