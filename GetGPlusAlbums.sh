#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

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
#	ls "$tmpDir"
        rm -r "$tmpDir"
        trap - EXIT INT TERM QUIT ABRT KILL
        exit 0
}
trap "_clean_program" EXIT INT TERM QUIT ABRT KILL

# A very simple error-method
ownError(){
	echo $@ >&2
	exit 1
}

#Create A  FLNAME Function
FLNAMES(){
	append=""
	while [ ! -z $1 ]
	do
		append="$append%20$1"
		shift
	done

	# Searching On Google For The Specified Names
	GID="$(	\
		curl -A 'Mozilla/4.0' --silent "https://www.google.com/search?q=site%3Aplus.google.com${append}" | \
		grep -P -o '(?<=plus.google.com/)[^/u ]+(?=/)' | \
		sed -n 1p \
	)" || ownError "Get GID Failed"
}
#Create A GPlusID Function
GPLUSID(){
	GID="$1"
}

showHelp(){
cat <<EOF_HELP
$program:	Download a photo-album from Google+
	1st argument:
		name:	Search by name
		id:	Search by Google+-ID
	2nd-... argument:
		id or name of the person
		(no " or \\ needed for spaces in names)
EOF_HELP
	exit 0
}

downloadAlbum(){
	albumNr=$1
	#Get The URL Of Selected Album
	GPlusAlbum=$(sed -n "/$albumNr/p" $tmpDir/albums.html | awk -F ',' '{print $8}' | sed 's/"//g' | sed '/^$/d')
	echo $GPlusAlbum

	#Download Selected Album Contents
	wget -qc $GPlusAlbum -O $tmpDir/photos$albumNr.html

#Get the Album-name
GPlusAlbumName=$(sed '/data:/p' $tmpDir/photos$albumNr.html | grep -P -o "(?<=/)[^/]+(?=#)" | sort -u | grep -v "<" | grep -v "?")
echo GPlus Album Name = $GPlusAlbumName

#Generate FNAME & LNAME
#TODO: Detect fault in this part
NAME="$(							\
	grep "https://plus.google.com" $tmpDir/photos$albumNr.html |	\
	grep "googleusercontent" |				\
	cut -d'"' -f6 | grep -i [a-z] |				\
	sort -u | head -n1 |					\
	sed 's/ /_/g' 						\
	)" #"' # Get colour-recognistion all right

#Make directory using First and Last Name
TargetDir="$NAME/$GPlusAlbumName"
echo Target Directory = $TargetDir
mkdir -p "$TargetDir"

#Make an empthy file
echo -n "" > $tmpDir/MiteshShah.txt
for extension in $allowedExtensions
do
	# Workflow: 
	# - cat file
	# - get lines containing EXTENSION
	# - cut-out right section
	# - check if EXTENSION is still in that part
	# - check if it starts with https, not //ssl
	cat $tmpDir/photos$albumNr.html | grep -i $extension |	\
		cut -d'"' -f4 | grep -i $extension |	\
		grep -i ^https				\
		>> $tmpDir/MiteshShah.txt
done

#Download the URL's
if [ "$(cat $tmpDir/MiteshShah.txt | wc -l)" != "0" ]
then
	#Download Starts
	cd $TargetDir
	wget -ci $tmpDir/MiteshShah.txt #2> /dev/null

	#Remove Extra Unwanted Stuff
	cd - &> /dev/null
else
	echo "No photos where found :("
fi
}

main(){
	if [ -z $2 ]
	then
		# Check if arguments are given
		clear
		showHelp
	else
		# Remember the choise, and remove is from the arguments
		# makes use of $@ easier
		choise=$1
		shift
	fi
	case $choise in
		name) FLNAMES $@;;
		id) GPLUSID $@;;
		*) showHelp;;
	esac

	# Download The Album Page Of $FNAME $LNAME Person
	wget -qc https://plus.google.com/photos/$GID/albums -O $tmpDir/albums.html   ||  ownError "Album not found"

	#Sorting Album Page So We Only Get Album Names
	OPTIONS=$(sed -n '/\[1\,\[\,1\,\[\"https/p' $tmpDir/albums.html | grep -P -o '(?<=/)[^/]+(?=\")' | sed 1d)
	#Making Album Menu
	echo "Use option 0 for downloading all albums"
	select OPT in $OPTIONS;
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
}
main $@
