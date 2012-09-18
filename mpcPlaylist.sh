#!/bin/bash
# Author: Felix (makefu)
# Sun May 31 03:11:14 CEST 2009
# added experimental selection from specified music style ( will surely be
# slower than normal, user needs to know which "number" the style is
# some magic numbers
# 5 - Ambient
# 11 - Trance
# 7  - Drum N Bass
# 18 - Jazz
# 6 - Dance
# 9 - House
# 20 - new Wave
# 10 - techno
# 12 - video game
# User can give an arbitary number of styles
# one hour later... it finally works as expected

# added predefined music-styles ( like $0 electro or $0 misc )
# moved output completely into the function randmusic (makes stuff easier)

# !ATTENTION!
#find the mplayer called by our shell-script and kill it
# alias next="kill $(pidof -o $(pidof -x randPlaylist.sh) mplayer)"
# please regard this border is fix, may change this in further releases
# actually i have no good idea to fix this...
MAX=288383
lock=~/.mplayerLock
if [ -e $lock ]; then
    rm $lock # removing previous locks
fi
#obligatory min
MIN=1

# is the music good enough
BORDER="4.0"

function rnd 
{
     hex=`dd if=/dev/urandom bs=512 count=2 2>/dev/null | md5sum | awk '{print $1}' | \
     tr [:lower:] [:upper:] | cut -b 1-8`
     rand=`echo "ibase=16; $hex"| bc`
     echo $(($1+($rand)%$2));
} 
function randmusic
{
    hasStyle=""
    CURR=`rnd $MIN $MAX`

    #lets get into working directory
    #cd /home/makefu/music/external/newgrounds/

    theFile=`curl http://www.newgrounds.com/audio/listen/$CURR 2>/dev/null` 
    echo Fetching $CURR
    VOTING=`echo $theFile | sed -n \
    '/score_number/s;.*score_number[^>]*>\([0-5].[0-9][0-9]\).*;\1;p'`
    echo "SCORE IS $VOTING" 
    IFS=" "
    STYLE=`echo $theFile | sed -n \
    's;.*/audio/browse/genre/\([A-Za-z0-9-]*\).*;\1;p'`
    echo "Style is $STYLE"
    # only if styles are given
    if [ "$stylelist" ];then
        for s in $stylelist;do
            if [ "$s" == "$STYLE" ];then
                hasStyle="1"
            fi
        done
    else
        #if no style is given we assume it fits the reqs
        hasStyle="1"
    fi


    if [ "$VOTING"  ] && [ "$hasStyle" ];then
        if [ "`echo "$VOTING > $BORDER" | bc`" -eq "1" ];
        then
            echo "VOTING :" $VOTING
            echo "STYLE  :" $STYLE
            echo -n "downloading audio ... "
            #fileGrep=`echo $theFile | grep filename=`

            mpc add http://www.newgrounds.com/audio/download/$CURR 
            mpc play
            sleep 30
            #`echo $fileGrep | sed \
            #  's/.*filename=\(http.*mp3\|MP3\)&length.*/\1/'` 2>/dev/null && echo "finished" 
         fi
    fi

}

IFS=" "
if [ "$1" == "electro" ]; then
    stylelist="ambient dance drum-n-base dubstep house industrial new-wave techno trance video-game" # 12
  else
    stylelist=$1
fi

while true;
do
    randmusic #> /dev/null 2>&1
done
