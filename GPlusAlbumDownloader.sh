#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Copyright (C) 2012 by Mitesh Shah Mr.Miteshah@gmail.com

echo "For Latest Updates Follow Me on"
echo "Google Plus: Http://gplus.to/iamroot"
echo "===================================="

echo "Enter Google Plus Album URL: "
read GPlusAlbum
echo $GPlusAlbum
wget -c $GPlusAlbum
rm /tmp/MiteshShah.txt &> /dev/null
cat $(basename $GPlusAlbum) | grep jpg | cut -d'"' -f4 | grep jpg >> /tmp/MiteshShah.txt
cat $(basename $GPlusAlbum) | grep png | cut -d'"' -f4 | grep png >> /tmp/MiteshShah.txt
wget -ci /tmp/MiteshShah.txt
rm /tmp/MiteshShah.txt $(basename $GPlusAlbum)