#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Copyright (C) 2012 by Mitesh Shah (Mr.Miteshah@gmail.com)
# Speacial thanks to Daniel Sandman (revoltism@gmail.com)

clear
echo "For Latest Updates Follow Me On"
echo "Google Plus: Http://gplus.to/iamroot"
echo "====================================="

#Enter First & Last Names
read -p "Enter First Name: " FNAME
read -p "Enter Last Name:  " LNAME

#Extra Spaces
echo
echo

# Searching On Google For The Specified Names
GID="`curl -A 'Mozilla/4.0' --silent "https://www.google.com/search?q=site%3Aplus.google.com%20$FNAME%20$LNAME" | grep -P -o '(?<=plus.google.com/)[^/u ]+(?=/)' | sed -n 1p`"
#echo $GID

#We Don't Want To Appends Data
rm albums &> /dev/null

# Download The Album Page Of $FNAME $LNAME Person
wget -qc https://plus.google.com/photos/$GID/albums

#Sorting Album Page So We Only Get Album Names
OPTIONS=$(sed -n '/\[1\,\[\,1\,\[\"https/p' albums | grep -P -o '(?<=/)[^/]+(?=\")' | sed 1d)

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
GPlusAlbum=$(sed -n "/$OPT/p" albums | awk -F ',' '{print $8}' | sed 's/"//g' | sed '/^$/d')
#echo $GPlusAlbum

#Download Selected Album Contents
wget -qc $GPlusAlbum

#Extra Spaces
echo
echo

#GPlusID=$(echo $GPlusAlbum | cut -d'/' -f5)
#echo $GPlusID
GPlusAlbumName=$(sed '/data:/p' $(basename $GPlusAlbum) | grep -P -o "(?<=/)[^/]+(?=#)" | sort -u | grep -v "<" | grep -v "?")
echo GPlus Album Name = $GPlusAlbumName

#TargetDir=$(echo $GPlusID/$GPlusAlbumName)
TargetDir=$(echo $FNAME$LNAME/$GPlusAlbumName)
echo Target Directory = $TargetDir

#Extra Spaces
echo
echo

#Make TargetDir If Not Exist
if [ ! "$(ls $TargetDir 2> /dev/null)" ]
then
        mkdir -p $TargetDir
fi

#We Don't Want To Appends Data
rm /tmp/MiteshShah.txt &> /dev/null

#Sorting Albums So We Only Get JPG PNG GIF & JPEG Images
cat $(basename $GPlusAlbum) | grep jpg | cut -d'"' -f4 | grep -i jpg >> /tmp/MiteshShah.txt
cat $(basename $GPlusAlbum) | grep png | cut -d'"' -f4 | grep -i png >> /tmp/MiteshShah.txt
cat $(basename $GPlusAlbum) | grep png | cut -d'"' -f4 | grep -i gif >> /tmp/MiteshShah.txt
cat $(basename $GPlusAlbum) | grep png | cut -d'"' -f4 | grep -i jpeg >> /tmp/MiteshShah.txt

#Download Starts
cd $TargetDir
wget -ci /tmp/MiteshShah.txt #2> /dev/null

#Remove Extra Unwanted Stuff
cd - &> /dev/null
rm /tmp/MiteshShah.txt albums $(basename $GPlusAlbum)
