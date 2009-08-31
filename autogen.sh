#!/bin/sh

# Greet user.
echo "MAngband Autogen/Helper"

# Use getopt to fetch flags.
flags=`getopt hndrcfva $*`
usage=0; norma=0; devel=0; distr=0; clean=0;
force=0; verbo=0; autoc=0;
set -- $flags
for flag; do
    case "$flag" in
	-h ) usage=1; shift ;;
	-n ) norma=1; shift ;;
	-d ) devel=1; shift ;;
	-r ) distr=1; shift ;;
	-c ) clean=1; shift ;;	
	-f ) force=1; shift ;;
	-v ) verbo=1; shift ;;
	-a ) autoc=1; shift ;;		
	-- ) shift; break ;;
    esac
done
# Test flags for errors
TMODE=$((${norma} + ${devel} + ${distr} + ${clean} + ${usage}));
#echo "NDR: $TMODE N: $norma D: $devel R: $distr C: $clean V: $verbo F: $force A: $autoc V: $verbo ?: $usage"

if [ ${TMODE} -eq 0 ]; then
echo " * No mode specified. Try -h flag to find out more!"
norma=1;
fi
if [ ${TMODE} -ge 2 ]; then
echo " -- FAILED"
echo " The -n, -d, -r, -c and -h flags are in conflict. See -h for details:"
usage=1;
fi


# Display help and exit
if [ "$usage" = "1" ]; then
echo "Usage: ./autogen.sh [MODE] [OPTION]"
echo " MODE flag selects the task:"
echo " -n  NORMAL mode. Will run autotools to create a './configure' script."
echo "     (default) "
echo " -d  DEBUG/DEVELOPER mode. Similar to NORMAL, but, several hacks are added"
echo "     to the config file, allowing MAngband to run from 'current' directory."
echo "     NOTE: Using it makes your working copy unsuitable for release !"
echo " -r  RELEASE mode. Prepares the package for distribution."
echo " -c  CLEANING mode. Pretty useless. Deletes excessive autotool files."
echo " -h  HELP mode. Displays this message and exits."
echo " OPTION flags control mode behavior:"
echo " -f  Force download of latest GNU config.* files."
echo " -v  Verbose logging - display additional information."
echo " -a  Automaticly invoke ./configure when it's ready."
exit 0
fi

# Select logger
if [ "$verbo" = "1" ]; then
echo " * Verbose logging enabled"
VLOG="/dev/stdout"
else
VLOG="/dev/null"
fi
# Auto-configure when Releasing
[ "$distr" = "1" ] && autoc=1
# Auto-force when Cleaning
[ "$clean" = "1" ] && force=1


# Show some info
[ "$norma" = "1" ] && echo " * Using NORMAL mode"
[ "$devel" = "1" ] && echo " * Using DEVELOPER mode"
[ "$distr" = "1" ] && echo " * Using RELEASE mode"
[ "$clean" = "1" ] && echo " * Using CLEANING mode"
#echo " * Using $1 mode."


# Delete downloadable files
if [ "$force" = "1" ]; then
    echo " * Removing 'config.sub' and 'config.guess'"
    rm ./config.sub
    rm ./config.guess
fi

# Delete generated files
if [ "$clean" = "1" ]; then
echo " * Removing makefiles"
find . -name "Makefile.in" -exec rm {} \;
find . -name "Makefile" -exec rm {} \;
echo " * Removing various generated files"
rm aclocal.m4
rm src/config.h
rm config.h
rm stamp-h1
rm config.log
rm config.status
rm install-sh
rm missing
rm depcomp
exit 0
fi
# Update GNU config.* files
[ -f ./config.sub ] || { 
    echo " * Downloading 'config.sub' from GNU.org";
    wget -O config.sub "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD" >${VLOG} 2>${VLOG} ||
    echo " -- FAILED"; }
[ -f ./config.guess ] || { 
    echo " * Downloading 'config.guess' from GNU.org";
    wget -O config.guess "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD" >${VLOG} 2>${VLOG} ||
    echo " -- FAILED"; }

# The real purpose of autogen:
echo " * Running 'autoreconf -i'"
autoreconf -i >${VLOG} 2>${VLOG} || { echo " -- FAILED"; exit 1; }

# Prepare for debug
if [ "$devel" = "1" ]; then
echo " * Preparing debug environment"
CFG="./mangband.cfg"
TMP="./$(basename $0).$$.tmp"
sed "/*\{0,3\}\(EDIT\|DATA\|SAVE\)_DIR = /d" ${CFG} > ${TMP}
echo "EDIT_DIR = \"./lib/edit\"" >> ${TMP}
echo "DATA_DIR = \"./lib/data\"" >> ${TMP}
echo "SAVE_DIR = \"./lib/save\"" >> ${TMP}
mv ${TMP} ${CFG}
echo "LibDir ./lib/" > ./.mangrc
fi

# Auto-run configure
if [ "$autoc" = "1" ]; then
    echo " * Running './configure'"
    ./configure >${VLOG} 2>${VLOG} || { echo " -- FAILED"; exit 1; }
fi

# Prepare release
if [ "$distr" = "1" ]; then
echo " * Running 'make dist'"
make dist >${VLOG} 2>${VLOG} || { echo " -- FAILED"; exit 1; }
echo -n " * Ready! "
ls *.tar.gz
exit 0
fi

# DONE
if [ "$autoc" = "1" ]; then
    echo " * Ready!"
else
    echo " * Ready! You can use './configure' now!"
fi
