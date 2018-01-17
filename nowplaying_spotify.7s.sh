#!/bin/bash

# <bitbar.title>Now playing for Spotify</bitbar.title>
# <bitbar.version>v1.1</bitbar.version>
# <bitbar.author>Florian Loch (based on work of Adam Kenyon)</bitbar.author>
# <bitbar.author.github>FlorianLoch</bitbar.author.github>
# <bitbar.desc>Shows and controls the music that is now playing. Optimized for Spotify.</bitbar.desc>
# <bitbar.image>https://pbs.twimg.com/media/CbKmTS7VAAA84VS.png:small</bitbar.image>
# <bitbar.dependencies></bitbar.dependencies>
# <bitbar.abouturl></bitbar.abouturl>

# first, determine if there's an app that's playing or paused
playing=""
paused=""

# is the app running?
app_state=$(osascript -e "application \"Spotify\" is running")

# shellcheck disable=SC2181
if [ "$?" != "0" ]; then
  # just exit if there was an error determining the app's state
  # (the app might be in the middle of quitting)
  exit
fi

if [ "$app_state" = "true" ] && [ "$track" = "" ]; then
  # yes, it's running
  # is it playing music currently?
  app_playing=$(osascript -e "tell application \"Spotify\" to player state as string")
  if [ "$app_playing" = "paused" ] || [ "$app_playing" = "0" ]; then
    # nope, it's paused
    paused="true"
  elif [ "$app_playing" = "playing" ] || [ "$app_playing" = "1" ]; then
    # yes, it's playing
    playing="true"
  fi
fi


# play/pause
if [ "$1" = "play" ] || [ "$1" = "pause" ]; then
  osascript -e "tell application \"Spotify\" to $1"
  exit
fi
# next/previous
if [ "$1" = "next" ] || [ "$1" = "previous" ]; then
  osascript -e "tell application \"$2\" to $1 track"
  # tell spotify to hit "Previous" twice so it actually plays the previous track
  # instead of just starting from the beginning of the current one
  if [ "$playing" = "true" ] && [ "$1" = "previous" ]; then
    osascript -e "tell application \"$2\" to $1 track"
  fi
  exit
fi


# start outputting information to bitbar
if [ "$playing" = "" ] && [ "$paused" = "" ]; then
  # nothing is even paused
  echo "🙉 No music playing | color=gray"
else
  # something is playing or is paused
  track=""
  artist=""
  album=""

  if [ "$playing" = "" ]; then
    echo "Spotify is paused | color=#888888"
    echo "---"
  fi

  track_query="name of current track"
  artist_query="artist of current track"
  album_query="album of current track"

  # output the track and artist
  track=$(osascript -e "tell application \"Spotify\" to $track_query")
  artist=$(osascript -e "tell application \"Spotify\" to $artist_query")
  album=$(osascript -e "tell application \"Spotify\" to $album_query")

  echo "♪ $(echo $track | awk -F '\ -' '{print $1}') - $artist | length=50 color=#25d34e"
  echo "---"
  echo "$track"
  echo "On: $album"
  echo "By: $artist"
  echo "---"

  if [ "$playing" != "" ]; then
    echo "⏸ Pause | bash='$0' param1=pause refresh=true terminal=false"
  else
    echo "▶️ Play | bash='$0' param1=play refresh=true terminal=false"
  fi

  echo "⏭ Next | bash='$0' param1=next refresh=true terminal=false"
  echo "⏮ Previous | bash='$0' param1=previous refresh=true terminal=false"
fi
