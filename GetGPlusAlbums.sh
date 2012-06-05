#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Copyright (C) 2012 by JVApen (home.euphonynet.be/jvapen/)
# Copyright (C) 2012 by Mitesh Shah (Mr.Miteshah@gmail.com)
# Special thanks to Daniel Sandman (revoltism@gmail.com)

allowedExtensions="jpg png gif jpeg"
#       Name of the script, a bit better then $0, since you don't always know
#       how the script is being executed (absolute, relative, from /bin, ...)
#       Doesn't really work well with linked names, but you get the point
#       example: prog.sh > prog # prog > prog # ../prog.sh > prog #
#                prog.other > prog.other
program="`basename $0 .sh`"

#       /tmp, the place for tmp-files, but $tmpDir is even better.
#       no need to remember to clean it up,
#       no need for $$ in every filename,
#       just use $tmpDir/file instead of /tmp/file.$$
tmpDir="/tmp/$program.d.$$"

#       Make a tmp-dir to use,
#       simple to store files in, without having to think about $$
#       clean-up when done.
#       @see: $tmpDir for info about this directory
mkdir "$tmpDir"
_clean_program()
{
        rm -r "$tmpDir"
        trap - EXIT INT TERM QUIT ABRT KILL
        sync	# Flush file system buffers to disc
        exit 0
}
trap "_clean_program" EXIT INT TERM QUIT ABRT KILL

showHelp(){
cat <<EOF_HELP
$program:	Download a photo-album from Google+
	1st argument:
		name:	Search by name
		id:	Search by Google+-ID
	2nd argument:
		id or name of the person
		(use " or \\ for spaces, /, ... in name)
	3th argument:
		all:	Download all albums
		select:	Select album wanted
		[0-9]*:	Album you want to download
EOF_HELP
	exit 0
}

# A very simple error-method
#TODO Make it more usefull
ownError(){
	echo $@ >&2
	exit 1
}

urlencode(){
#Source from http://www.shelldorado.com/scripts/cmds/urlencode
##########################################################################
# Title      :  urlencode - encode URL data
# Author     :  Heiner Steven (heiner.steven@odn.de)
# Date       :  2000-03-15
# Requires   :  awk
# Categories :  File Conversion, WWW, CGI
# SCCS-Id.   :  @(#) urlencode  1.4 06/10/29
##########################################################################
awk '
   BEGIN {
        # We assume an awk implementation that is just plain dumb.
        # We will convert an character to its ASCII value with the
        # table ord[], and produce two-digit hexadecimal output
        # without the printf("%02X") feature.
 
        EOL = "%0A"             # "end of line" string (encoded)
        split ("1 2 3 4 5 6 7 8 9 A B C D E F", hextab, " ")
        hextab [0] = 0
        for ( i=1; i<=255; ++i ) ord [ sprintf ("%c", i) "" ] = i + 0
        if ("'"$EncodeEOL"'" == "yes") EncodeEOL = 1; else EncodeEOL = 0
   }
   {
        encoded = ""
        for ( i=1; i<=length ($0); ++i ) {
            c = substr ($0, i, 1)
            if ( c ~ /[a-zA-Z0-9.-]/ ) {
                encoded = encoded c             # safe character
            } else if ( c == " " ) {
                encoded = encoded "+"   # special handling
            } else {
                # unsafe character, encode it as a two-digit hex-number
                lo = ord [c] % 16
                hi = int (ord [c] / 16);
                encoded = encoded "%" hextab [hi] hextab [lo]
            }
        }
        if ( EncodeEOL ) {
            printf ("%s", encoded EOL)
        } else {
            print encoded
        }
   }
   END {
        #if ( EncodeEOL ) print ""
   }
' "$@"
}


NAMES(){
	# Encode the arguments to fit in URL
	append="$(echo "\"$@\"" | urlencode)"
	
	# Search on plus.google.com for a person or page
	# Split source by tag
	# Find tag with name in it
	# Find a anchortag with reference in it
	# Cut-out right piece
	# Take first one (to be sure)
	GID=$(
		curl -A 'Mozilla/4.0' --silent "https://plus.google.com/s/${append}/people" | 
		sed 's/></>\n</g' | grep -i "$@" | grep "<a href=\"./" |
		cut -d'"' -f2 | cut -d'/' -f2 | head -n1
	) || ownError "Get GID Failed"
}

#Create A GPlusID Function
GPLUSID(){
	#TODO? Errorcheck?
	# Just use ID that is given
	GID="$1"
}

downloadAlbum(){
	# Use argument with usefull name
	albumName="$1"
	
	#Get The URL Of Selected Album
	GPlusAlbum=$(sed -n "/$albumName/p" $tmpDir/albums.html | awk -F ',' '{print $8}' | sed 's/"//g' | sed '/^$/d')
	#echo $GPlusAlbum

	#Download Selected Album Contents
	wget -c $GPlusAlbum -O $tmpDir/photos$albumName.html

	#Get the Album-name
	GPlusAlbumName=$(sed '/data:/p' $tmpDir/photos$albumName.html | grep -P -o "(?<=/)[^/]+(?=#)" | sort -u | grep -v "<" | grep -v "?")
	echo GPlus Album Name = $GPlusAlbumName

	#Get a usefull name for the ID 
	NAME="$(							\
		grep "https://plus.google.com" $tmpDir/photos$albumName.html |	\
		grep "googleusercontent" |				\
		cut -d'"' -f6 | grep -i [a-z] |				\
		sort -u | head -n1 |					\
		sed 's/ /_/g' 						\
	)" #"' # Get colour-recognistion all right in gedit

	# Make directory using User&Album Name
	TargetDir="$NAME/$GPlusAlbumName"
	# -p: makes parents and doesn't error if already excist
	mkdir -p "$TargetDir"	
	#echo Target Directory = $TargetDir

	# Make an empthy file (just be sure if >> doesn't want to create it)
	echo -n "" > "$tmpDir/$albumName.lst"
	for extension in $allowedExtensions
	do
		# Workflow: 
		# - cat file
		# - get lines containing EXTENSION
		# - cut-out right section
		# - check if EXTENSION is still in that part
		# - check if it starts with https, not //ssl
		cat "$tmpDir/photos$albumName.html" | grep -i $extension |	\
			cut -d'"' -f4 | grep -i $extension |	\
			grep -i ^https				\
			>> "$tmpDir/$albumName.lst"
	done

	#Download the URL's
	if [ "$(cat "$tmpDir/$albumName.lst" | wc -l)" != "0" ]
	then
		#Download Starts
		cd "$TargetDir"
		wget -ci "$tmpDir/$albumName.lst" | /dev/null #2> /dev/null

		#Remove Extra Unwanted Stuff
		cd - &> /dev/null
	else
		echo "No photos where found :("
	fi
}

main(){
	# Get GID by what is chosen
	case $choise in
		name) NAMES "$@";;
		id) GPLUSID "$@";;
		*) showHelp;;
	esac

	# Download The Album Page Of the person
	wget -c https://plus.google.com/photos/$GID/albums -O $tmpDir/albums.html   ||  ownError "Album not found for GID=$GID"

	#Sorting Album Page So We Only Get Album Names
	OPTIONS=$(sed -n '/\[1\,\[\,1\,\[\"https/p' $tmpDir/albums.html | grep -P -o '(?<=/)[^/]+(?=\")' | sed 1d)

	if [ $download == "select" ]
	then
		echo "Use option 0 for downloading all albums"
		#Making Album Menu
		select OPT in $OPTIONS
		do
			case $REPLY in
			0)
				echo "You selected every album"
				for i in $OPTIONS
				do
					downloadAlbum $i &
				done
				wait
				break
				;;
			*)
				echo "You Selected $OPT ($REPLY)"
				downloadAlbum $OPT
				break
				;;
			esac
		done
	else
		# Do the same, without user-input
		#TODO Remove 'select' from STDOUT
		echo $download | select OPT in $OPTIONS
		do
			case $REPLY in
			0)
				for i in $OPTIONS
				do
					downloadAlbum $i &
				done
				wait
				break
				;;
			*)
				downloadAlbum $OPT
				break
				;;
			esac
		done
	fi
}

if [ -z "$3" ]
then
	# Check if arguments are given
	clear
	showHelp
else
	# Remember the choise, and remove is from the arguments
	# makes use of $@ easier
	choise="$1"
	download="$2"
	[ "$download" == "all" ] && download="0"
	shift 2
fi

# Start the program
main "$@"
