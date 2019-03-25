#!/bin/sh 

#
# WARNING: Some systems use ../lib32 or ../lib64  instead of .../lib       
#

if [ -n "$1" ] ; then
    PREFIX="$1"
else
    PREFIX="/opt/sway"
fi

#
# 
#
#if [ -f /etc/debian_version ] ; then
#    # For Debian like systems, meson installs some packages files in
#    # in the subdirectory .../lib/x86_64-linux-gnu/    
#    archname=`dpkg-architecture -qDEB_HOST_MULTIARCH`
#    if [ -n "$archname" ] ; then
#        echo "LD_LIBRARY_PATH=\"$PREFIX/lib/$archname:\$LD_LIBRARY_PATH\""
#        echo "PKG_CONFIG_PATH=\"$PREFIX/lib/$archname/pkgconfig:\$PKG_CONFIG_PATH\""
#    fi  
#fi

#
# Warning: On some systems may use lib64 or lib32 instead
#          of lib. 
#

echo "LD_LIBRARY_PATH=\"$PREFIX/lib:\$LD_LIBRARY_PATH\""
echo "PKG_CONFIG_PATH=\"$PREFIX/lib/pkgconfig:\$PKG_CONFIG_PATH\""

echo "PATH=\"$PREFIX/bin:\$PATH\""
echo "MANPATH=\"$PREFIX/share/man:\$MANPATH\""
echo
echo "export PATH"
echo "export MANPATH"
echo "export PKG_CONFIG_PATH"
echo "export LD_LIBRARY_PATH"

unset PREFIX
