#!/bin/bash -x
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Copyright (C) 2012 by Mitesh Shah (Mr.Miteshah@gmail.com)
# Special thanks to Daniel Sandman (revoltism@gmail.com)

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
	ls "$tmpDir"
        rm -r "$tmpDir"
        exit 0
}
trap "_clean_program" EXIT INT TERM QUIT ABRT KILL

#Create A  FLNAME Function
FLNAMES(){
	append=""
	while [ ! -z $1 ]
	do
		append="$append%20$1"
		shift
	done

	# Searching On Google For The Specified Names
	GID="`curl -A 'Mozilla/4.0' --silent "https://www.google.com/search?q=site%3Aplus.google.com${append}" | grep -P -o '(?<=plus.google.com/)[^/u ]+(?=/)' | sed -n 1p`" || ownError "Get GID Failed"

}


#Create A GPlusID Function
GPLUSID(){
	GID="$1"
	#Enter Google Plus ID
	#read -p "Enter 21 Digit Google Plus Profile ID: " GID
	#echo $GID
}

# A very simple error-method
ownError(){
	echo $@ >&2
	exit 1
}

showHelp(){
	#TODO: Fill in
	cat <<-EOF_HELP
	Please give some arguments
	EOF_HELP
	exit 0
}

main(){
if [ -z $2 ]
then
        clear
        showHelp
else
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
select OPT in $OPTIONS;
do
	case $OPT in
	*)
		echo "You Selected $OPT ($REPLY)"
		break
		;;
	esac
done

#Get The URL Of Selected Album
GPlusAlbum=$(sed -n "/$OPT/p" $tmpDir/albums.html | awk -F ',' '{print $8}' | sed 's/"//g' | sed '/^$/d')
echo $GPlusAlbum

#Download Selected Album Contents
wget -qc $GPlusAlbum -O $tmpDir/photos.html

#Get the Album-name
GPlusAlbumName=$(sed '/data:/p' $tmpDir/photos.html | grep -P -o "(?<=/)[^/]+(?=#)" | sort -u | grep -v "<" | grep -v "?")
echo GPlus Album Name = $GPlusAlbumName

#Generate FNAME & LNAME
#TODO: Detect fault in this part
NAME="$(sed '/data:/p' $tmpDir/photos.html | grep -P -o "(?<=,,)[^/150,]+(?=,)" | grep -i [a-z] | sort -u | head -n1 | cut -d"\"" -f2)"
FNAME=$(echo "$NAME" | cut -d" " -f1)
LNAME=$(echo "$NAME" | cut -d" " -f2)

#Make directory using First and Last Name
TargetDir="$FNAME$LNAME/$GPlusAlbumName"
echo Target Directory = $TargetDir
mkdir -p "$TargetDir"


#Make an empthy file
echo -n "" > $tmpDir/MiteshShah.txt

for extension in jpg png gif jpeg
do
# Workflow: 
# - cat file
# - get lines containing EXTENSION
# - cut-out right section
# - check if EXTENSION is still in that part
	cat $tmpDir/photos.html | grep -i $extension | cut -d'"' -f4 | grep -i $extension >> $tmpDir/MiteshShah.txt
done

#Download the URL's
if [ $(cat $tmpDir/MiteshShah.txt | wc) != 0 ]
then
	#Download Starts
	cd $TargetDir
	wget -ci $tmpDir/MiteshShah.txt #2> /dev/null

	#Remove Extra Unwanted Stuff
	cd - &> /dev/null
fi
}

main $@
