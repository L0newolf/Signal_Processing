#!/bin/sh
libtoolize --force
aclocal
autoconf
touch NEWS README AUTHORS ChangeLog
automake --add-missing
echo "run ./configure --prefix=/usr"
echo "run make"
echo "run make install"

