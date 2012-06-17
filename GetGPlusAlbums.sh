#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Copyright (C) 2012 by Mitesh Shah (Mr.Miteshah@gmail.com)
# Speacial thanks to Daniel Sandman (revoltism@gmail.com) & JVApen


#What If Someone Press CTRL+C While Script Is Running
#The Scripts Quits Without Clenning Some Unwanted Stuffs

#In Linux There Is One Nice Utility Called Trap
#The Trap Comamnd Helps The Scripts To Captures All The Specified Interrupt Signals
#Except The SIGKILL (Signal 9) And Then Call The Specified Commands Or Functions.

#NOTE: SIGKILL (Signal 9) Cann't Be Caught Or Ignored, Whether Via Trap Or Anything Else.
#The Only Thing That Will Prevent SIGKILL From Killing The Process Is Holding Kernel Locks.﻿

#Trap Examples:
#!/bin/bash
#trap "echo; echo CTRL+C Pressed; exit 0" INT
#read -t 300 -p "I'm Sleeping For 300 Sec Hit CTRL+C To Exit"

#In This Example Read Commands 
#1. Take Some Input & Quits
#2. Wait For 300 Sec For The  Input & Quits
#3. Don't Want To Enter Some Input & If You Pressed CTRL+C To Make Program Quit Then

#IF You Pressed CTRL+C Then Program Does Not Quits But Execute The Following Commands
#1. echo
#2. echo CTRL+C Pressed
#3. exit 0

#The Third Command Is Exit 0 So Program Is Quit If Remove Exit 0
#Then Press CTRL+C Infinate Time Program Never Quits Or
#Wait 300 Sec To Finish Program As Specified In Read Command

CleanStuff()
{
	if [ -e /tmp/MiteshShah.txt ]
	then
		rm /tmp/MiteshShah.txt
		echo
		#echo File Removed Inside The CleanStuff Function
	fi

	#Unset Trap So We Don't Get Infinate Loop
	trap - EXIT INT TERM QUIT ABRT KILL

	#Flush File System Buffers
	#More Details: info coreutils 'sync invocation'
	sync

	#Exit The Script
	exit 0
}
trap "CleanStuff" EXIT INT TERM QUIT ABRT KILL

#Handle Errors In Much Better Way
#Generate Custome Errors Messages
OwnError()
{
	#Redirect All STDIN 2 STDOUT
	echo $@ >&2
	exit 1
}

#Create A  FLNAME Function
FLNAMES()
{
	#Enter First & Last Names
	read -p "Enter First Name: " FNAME
	read -p "Enter Last Name:  " LNAME

	# Searching On Google For The Specified Names
	GID="`curl -A 'Mozilla/4.0' --silent \
	"https://www.google.com/search?q=site%3Aplus.google.com%20$FNAME%20$LNAME" | \
	grep -P -o '(?<=plus.google.com/)[^/u ]+(?=/)' | sed -n 1p`" || OwnError "Get GID Failed :("
	#echo $GID
}


#Create A GPlusID Function
GPLUSID()
{
	#Enter Google Plus ID
	read -p "Enter 21 Digit Google Plus Profile ID: " GID
	#echo $GID
}


clear
echo "For Latest Updates Follow Me On"
echo "Google Plus: Http://gplus.to/iamroot"
echo "====================================="
echo
echo "Search Google Plus Profile via.."
echo "1. First & Last Names"
echo "2. Google Plus Profile ID"
read -p "Enter Your Choice(1 or 2): " CHOICE

#Extra Spaces
echo
echo


#Checks Users Choice
#And Call The Right Function
if [ $CHOICE -eq 1 ]
then
	FLNAMES
else
	GPLUSID
fi


#Extra Spaces
echo
echo


# Download The Album Page Of $FNAME $LNAME Person & Save It To ALBUMS Variable
ALBUMS=$(wget -qcO- https://plus.google.com/photos/$GID/albums) || OwnError "ALBUMS Not Found :("
#echo $ALBUMS


#Set Internal Field Separator IFS For New Line
#It Is Useful To Make Album Menu
IFS=$'\n'

#Sorting Albums Veriable So We Only Get Albums Names & List The No Of Photos Inside The Albums
OPTIONS=$(echo "$ALBUMS" | sed -n '/\/albums\//p' | awk -F "," '{print $2" [" $4"]"}' | sed 's/"//g')
#echo $OPTIONS

#Making Album Menu
select OPT in $OPTIONS;
do
	case $OPT in
	*)
		echo "You Selected $REPLY) $OPT" 
		break
		;;
	esac
done


#Extra Spaces
echo
echo


#Now Get The Album Name From Just Removing Numbers From The $OPT
GPlusAlbumName=$(echo $OPT | sed 's/[^* ]*$//' | sed 's/[ \t]*$//')
echo GPlus Album Name = $GPlusAlbumName

#Get The URL Of Selected Album
GPlusAlbumURL=$(echo "$ALBUMS" | grep "\"$GPlusAlbumName\"" | awk -F ',' '{print $8}' | sed 's/"//g' | sed '/^$/d')
#echo GPlus Album URL = $GPlusAlbumURL


#Generate FNAME & LNAME
#If Users Choice Is 2
if [ $CHOICE -eq 2 ]
then
	FNAME=$(echo "$ALBUMS" | grep -P -o "(?<=,,)[^/150_,]+(?=,)" | \
	grep -i [a-z] | sort -u | head -n1 | cut -d"\"" -f2 | cut -d" " -f1)
	
	LNAME=$(echo "$ALBUMS" | grep -P -o "(?<=,,)[^/150_,]+(?=,)" | \
	grep -i [a-z] | sort -u | head -n1 | cut -d"\"" -f2 | cut -d" " -f2)
fi

#Modify $GPlusAlbumName
#Suppose $GPlusAlbumName="Why Linux/Ubuntu"
#The Forward Slash Cause A Problem In Creating A Directory
echo $GPlusAlbumName | grep /
if [ $? -eq 0 ]
then
	#Now Replace Forward Slash With Single Space
	#So Thats Looks Like "Why Linux Ubuntu" For Directory Creation
	GPlusAlbumName=$(echo "$GPlusAlbumName" | sed 's|/| |')
fi


TargetDir=$(echo $FNAME$LNAME/$GPlusAlbumName)
echo Target Directory = $TargetDir

#Make TargetDir If Not Exist
if [ ! "$(ls $TargetDir 2> /dev/null)" ]
then
        mkdir -p "$TargetDir"
fi


#Extra Spaces
echo
echo

#Download Selected Album Contents
GPlusAlbumData=$(wget -qcO- $GPlusAlbumURL) || OwnError "Unble To Fetch GPlusAlbumData :("

#Sorting Albums So We Only Get JPG PNG GIF & JPEG Images
for IMAGES in [Jj][Pp][Gg] [Pp][Nn][Gg] [Gg][Ii][Ff] [Jj][Pp][Ee][Gg]
do
	echo "$GPlusAlbumData" | sed -n '/.*picasa.*.'$IMG'/p' | awk -F '"' '{print $4}' | grep "s0-d"
done > /tmp/MiteshShah.txt

#Download Starts
cd $TargetDir
echo "[+] Downlaoding Please Wait..."
wget -qci /tmp/MiteshShah.txt || OwnError "Can't Downlaod Images Check Your Network Connections :("


#Finish Message
echo "[+] Done!!!!!!!!!!!!!!!!!!!!!!!!!!!"

#Extra Spaces
echo
echo
