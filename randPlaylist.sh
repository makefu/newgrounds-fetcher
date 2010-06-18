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
    cd /home/makefu/music/external/newgrounds/

    theFile=`curl http://www.newgrounds.com/audio/listen/$CURR 2>/dev/null` 
    echo Fetching $CURR
    VOTING=`echo $theFile | sed -n \
    '/submission_score/s;.*submission_score\">\([0-5].[0-9][0-9]\).*;\1;p'`
    
    IFS=" "
    STYLE=`echo $theFile | sed -n \
    '/\/audio\/list\//s;.*\/audio\/list\/\([0-9]*\).*;\1;p'`
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
            fileGrep=`echo $theFile | grep filename=`
            # wget will not dl if timestamp has not changed
            # and not add .1 to file names
            wget -m -nd `echo $fileGrep | sed \
            's/.*filename=\(http.*mp3\|MP3\)&length.*/\1/'` 2>/dev/null && echo "finished"
            # wait for unlock
            while [ -e $lock ]; do sleep 1; done
            touch $lock
            filename=`echo $fileGrep | sed \
            's/.*filename=http.*\/\([0-9]*.*mp3\|MP3\)&length.*/\1/'`
            echo you hear : $filename
            # locks will be deleted after mplayer finished ( being killed
            # or not
            (mplayer -ao alsa $filename  \
            || (rm $filename && echo "deleted crappy title" ); # remove file if i do not like it
                rm $lock
            )&
         fi
    fi

}

IFS=" "
if [ "$1" == "electro" ]; then
    stylelist="5 11 7 6 9 20 10 " # 12
  else
    stylelist=$1
fi

while true;
do
    randmusic #> /dev/null 2>&1
done
