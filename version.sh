#!/bin/bash

CONFIG_FILE="version.config"

#Variables that are loaded from config
VERSION_PATTERNS=
VERSION_FORMATS=
VERSION_FILE=

#Help at top, for easy reference

function do_help {
    case "$1" in
	setup)
	    cat <<EOF

Starts an interactive setup for configuring what the scrip needs to know.
Asks for three things:

Version filepath:
  Path to the file which is to be modified by the script.

Version pattern:
  A regular expression (parseable by grep), that identifies the position
  of the version number in the given file. E.g. if the file contains

  <?xml version="1.0" encoding="utf-8"?>
  <manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="fi.jalonne.android.roaddataapp"
      android:versionCode="14"
      android:versionName="1.14.1" >
  ...

  then a pattern to extract versionName would be 

  .*android:versionName="(.*)"

  where the parentheses mark the spot to extract.
  You can also give a list of patterns, separated by semicolon (;), 
  if you want to also bump other parts in the same file. As in example 
  above, the versionCode. E.g.

  android:versionCode="(.*)"; android:versionName="(.*)"

  The script automatically adds ".*" to start and end of the pattern,
  so that user only needs to give just enough to uniquely identify
  the spot.

  The user can also give a list of formats, as described next.

Version format: 
  Consist of two groups, dot (.) separated and hyphen (-) separated. E.g.

    major.minor.hotfix-revision

  would result in having 4 bumpable VERSION_PART variables, major, minor, hotfix and revision.
  Similarly,

    common_major.common_minor-special_major.special_minor-version_name

  would result in 5 variables. It is also possible to directly set the version
  variable, which is more sensible for "version_name" rather than bumping.

  You may give a list of formats, if you gave a list of patterns. Items in the list
  are separated by semicolon (;) and there has to be equal order and number of items
  as in the patterns list. For example (following the android example):'

  vcode; major.minor.hotfix

EOF
	    ;;
	show)
	    cat <<EOF

Display the version number, or part of it.
E.g. version number format setup to major.minor.hotfix-rev:

$>./version.sh show
0.1.0-1
$>./version.sh show minor
1
$>./version.sh show hotfix
0

EOF
	    ;;
	set)
	    cat <<EOF

Set a part of the version number to a value.
E.g. version number format setup to major.minor.hotfix-rev
and version number 0.1.0-1:

$>./version.sh set rev 3
Modified rev, version: 0.1.0-3
$>./version.sh set minor 3
Modified minor, version: 0.2.0-3
$>./version.sh set hotfix 1
Modified hotfix, version: 0.2.1-3

EOF
	    ;;
	bump)
	    cat <<EOF

Bump (+1) a part of the version number. Only makes sense for
numeric values.
E.g. version number format setup to major.minor.hotfix-name
and version number 0.1.0-customer:

$>./version.sh bump major
Bumped major, version: 1.1.0-customer
$>./version.sh bump minor
Bumped minor, version: 1.2.0-customer

This won't work:
$>./version.sh bump name
Error: version part "name" is not a number.

EOF
	    ;;
	*)
	    cat <<EOF 

Usage: ./version.sh COMMAND [options]
 
COMMAND:
help [command]: Prints this text, unless a command name given. If command name
                given, prints detailed help for that command.
setup: Interactive setup to configurate the script. Needs to be run before using
       bump, set or show.
bump VERSION_PART: Bumps version number up by one, for the given VERSION_PART.
set VERSION_PART VALUE: Sets the given VERSION_PART to given VALUE.
show [VERSION_PART]: Shows the version number, or VERSION_PART of it. 

EOF
    esac
}

###
### BEGIN HELPER FUNCTION SECTION
###

#find whether string NEEDLE is
#contained in HAY
function contains {
    HAY="$1"
    NEEDLE="$2"
    case "$HAY" in
	*"$NEEDLE"*)
	    echo 0
	    ;;
    esac
    echo ""
}

#Gets the version number from configured file,
#according to the given PATTERN
function extract_version {
    local PATTERN="$1"
    echo `cat "$VERSION_FILE" | sed -rn "s|.*$PATTERN.*|\1|p"`    
}

#Get the version number part from an item from
#the version format->value map
function part_version {
    local PART="$1"
    local VALUES=(${PART//:/ })
    local VERSION=${VALUES[2]}
    echo $VERSION
}

#Get the version name part from an item from
#the version format->value map
function part_name {
    local PART="$1"
    local VALUES=(${PART//:/ })
    local NAME=${VALUES[1]}
    echo $NAME
}

#Get the index, in which pattern/format
#the given item from the version format->value map
#belongs to.
function part_pattern_ind {
    local PART="$1"
    local VALUES=(${PART//:/ })
    local IND=${VALUES[0]}
    echo $IND
}

#Makes version string for given format,
#from given part map.
function make_version_str {
    local PART_MAP=(${@:2})
    local FORMAT="$1"
    local VER_STR="$FORMAT"
    for PART in "${PART_MAP[@]}"
    do
	local VER_STR=${VER_STR/`part_name $PART`/`part_version $PART`}
    done
    echo $VER_STR
}

###
### END HELPER FUNCTION SECTION
###

### Begin command implementations

function do_setup {
    echo "Setting up version.config interactively..."

    echo "Give the file that contains the version number to handle:"
    read VERSION_FILE

    echo "Give a regular expression to locate the version number inside the file:"
    read V_NO_REGEX

    echo "Give your version number format (e.g. major.minor.hotfix-rev, help for details):"
    read VERSION_FORMAT

    echo "Check your inputs:"
    echo "Version file path: $VERSION_FILE"
    echo "Version number can be extracted using: $V_NO_REGEX"
    echo "Version consist of: $VERSION_FORMAT"    

    read -p "Is the above information correct? (y/n): " CORRECT
    if [ "$CORRECT" = "y" ] || [ "$CORRECT" = "yes" ]
    then
	echo "Writing config file..."
	echo "VERSION_FILE='$VERSION_FILE'" > $CONFIG_FILE
	echo "V_NO_REGEX='$V_NO_REGEX'" >> $CONFIG_FILE
	echo "VERSION_FORMAT='$VERSION_FORMAT'" >> $CONFIG_FILE
	echo "Done!"
    else
	echo "Aborting..."
    fi
}

function do_show {
    case "$1" in
	*)
	    for pattern in "${VERSION_PATTERNS[@]}"
	    do
		cat "$VERSION_FILE" | sed -rn "s|.*$pattern.*|\1|p"
	    done
	    
    esac
}

function do_bump {
    echo "Bump minor/major"
}

if [ -f "$CONFIG_FILE" ]
then
    source $CONFIG_FILE

    VERSION_PATTERNS=(${V_NO_REGEX//\;/ })
    VERSION_FORMATS=(${VERSION_FORMAT//\;/ })
fi

if [ $1 ]
then

    case "$1" in
	help)
	    do_help $2
	    ;;
	setup)
	    do_setup $2 $3
	    ;;	
	show)
	    do_show $2
	    ;;
	set)
	    do_set $2 $3
	    ;;
	bump)
	    do_bump $2
	    ;;
    esac
	     
    exit 0
else
    do_help
    exit 1
fi
