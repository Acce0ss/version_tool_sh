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
      package="fi.fun.android.roaddataapp"
      android:versionCode="14"
      android:versionName="1.14.1" >
  ...

  then a pattern to extract versionName would be 

  android:versionName="(.*)"

  where the parentheses mark the spot to extract.
  WARNING: Only use single parentheses for each pattern!
           Currently there is no check for this, and pattern with
           multiple parentheses might cause havoc. Escape all
           parantheses that do not mark the version string.

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
  Each part name must be unique. Similarly,

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
Error: Part 'name' is not a number.

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
function contained_in {
    NEEDLE="$1"
    HAY="${@:2}"
    case "$HAY" in
	*"$NEEDLE"*)
	    echo 0
	    ;;
    esac
}

#test if a string contains a natural number
function is_natural_num {
    local MAY_BE_NUM="$1"
    case $MAY_BE_NUM in
	''|*[!0-9]*)
	;;
	*)
	    echo 0
	    ;;
    esac
}

#Gets the version number from configured file,
#according to the given PATTERN
function extract_version {
    local PATTERN="$1"
    echo `cat "$VERSION_FILE" | sed -rn "s|.*$PATTERN.*|\1|p"`    
}

function replace_version {
    local PATTERN="$1"
    local VERSION_STRING="$2"
    local PATTERN_W_NEW_VSTR="${PATTERN//(.*)/$VERSION_STRING}"
    local VERSION_FILE_CONTENT=`cat "$VERSION_FILE" | sed -r "s|$PATTERN|$PATTERN_W_NEW_VSTR|g"`
    echo "$PATTERN"
    echo "$PATTERN_W_NEW_VSTR"
    echo "$VERSION_FILE_CONTENT" # > $VERSION_FILE
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

#Check whether given part name exists.
function exists_in {
    local PART_NAME="$1"
    local PART_MAP=(${@:2})
    if [ `contained_in ":$PART_NAME:" "${PART_MAP[@]}"` ]
    then
	echo 0
    fi	
}

#Makes version string for given format,
#from given part map.
function make_version_str {
    local FORMAT="$1"
    local PART_MAP=(${@:2})
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
    TO_SHOW="$1"
    if [ $TO_SHOW ]
    then
	for PART in "${VERSION_PART_MAP[@]}"
	do
	    if [ `contained_in $TO_SHOW $PART` ]
	    then
		local VNO=`part_version $PART`
	    fi
	done
	if [ $VNO ]
	then
	    echo "$VNO"
	else
	    echo "Error: Part $TO_SHOW not in configuration."
	    exit 1
	fi
    else
	for VFORMAT in "${VERSION_FORMATS[@]}"
	do
	    make_version_str $VFORMAT ${VERSION_PART_MAP[@]}
	done
    fi
}

function do_bump {
    local PART_NAME="$1"
    if [ `exists_in $PART_NAME ${UPDATED_PART_MAP[@]}` ]
    then
	for i in ${!UPDATED_PART_MAP[@]}
	do
	    if [ `contained_in $PART_NAME ${UPDATED_PART_MAP[$i]}` ]
	    then
		local PART=${UPDATED_PART_MAP[$i]}
		local PART_VERSION=`part_version $PART`
		if [ `is_natural_num $PART_VERSION` ]
		then
		    V_NO=`expr $PART_VERSION + 1`
		    UPDATED_PART_MAP[$i]="`part_pattern_ind $PART`:`part_name $PART`:$V_NO"
		    echo "${UPDATED_PART_MAP[@]}"
		else
		    echo "Error: Part '$PART_NAME' is not a number. " \
			 "Use 'version.sh set $PART_NAME newValue' instead?"
		fi
	    fi	    
	done
    else
	echo "Error: Part '$PART_NAME' not in configuration."
    fi
}

function read_config {

    ### Read the config file and make some essential globals:
    ### VERSION_PATTERNS: Array of patterns
    ### VERSION_FORMATS: Array of formats, same order as patterns
    ### VERSION_PART_MAP: Array of following formatted data:
    ###                   pattern_ind:format_part_name:part_version
    ###                   This will be parsed as an array when used.
    ### UPDATED_PART_MAP: Same as VERSION_PART_MAP, but used to hold
    ###                   the updates to version values and to produce
    ###                   the version strings after changes
    
    if [ -f "$CONFIG_FILE" ]
    then
	source $CONFIG_FILE
	
	VERSION_PATTERNS=(${V_NO_REGEX//\;/ })
	VERSION_FORMATS=(${VERSION_FORMAT//\;/ })
	
	for i in "${!VERSION_PATTERNS[@]}"
	do
	    local PATTERN="${VERSION_PATTERNS[$i]}"
	    local FORMAT="${VERSION_FORMATS[$i]}"

	    local HYPHEN_SEP=${FORMAT//-/ }
	    local FORMAT_PARTS=(${HYPHEN_SEP//./ })
	    
	    local VERSION=$(extract_version $PATTERN)
	    local V_HYPH_SEP=${VERSION//-/ }
	    local V_PARTS=(${V_HYPH_SEP//./ })
	    
	    for j in "${!FORMAT_PARTS[@]}"
	    do
		local VERSION_PART_STRING="$VERSION_PART_STRING $i:${FORMAT_PARTS[$j]}:${V_PARTS[$j]}"
	    done

	    #This is the current map; and will stay constant
	    VERSION_PART_MAP=($VERSION_PART_STRING)

	    #This is the map that might be updated and written to
	    #disk if requested
	    UPDATED_PART_MAP=($VERSION_PART_STRING)
	done	
    fi
}

read_config

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
