# version_tool_sh
Tool for controlling version number changes, and storing the structure.

The tool stores the setup information to a file "version.config", by default.
You may want to change the name, if it conflicts. It is recommended to include 
the configuration file to your version control, although it probably won't
change much. It will, however, work as a document of how your version number
is structured, and allows anyone working on the repo to easily bump the version
without manually editing the file where version is stored.

The tool currently has following commands:
 - help
 - setup
 - show
 - bump
 - set
Their help texts are listed below

## help

```
Usage: ./version.sh COMMAND [options]
 
COMMAND:
help [command]: Prints this text, unless a command name given. If command name
                given, prints detailed help for that command.
setup: Interactive setup to configurate the script. Needs to be run before using
       bump, set or show.
bump VERSION_PART: Bumps version number up by one, for the given VERSION_PART.
set VERSION_PART VALUE: Sets the given VERSION_PART to given VALUE.
show [VERSION_PART]: Shows the version number, or VERSION_PART of it. 
```

## setup

Starts an interactive setup for configuring what the scrip needs to know.
Asks for three things:

### Version filepath:
  Path to the file which is to be modified by the script.

### Version pattern:
  A regular expression (parseable by grep), that identifies the position
  of the version number in the given file. E.g. if the file contains

```
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="fi.fun.android.roaddataapp"
    android:versionCode="14"
    android:versionName="1.14.1" >
...
```

  then a pattern to extract versionName would be 

```
android:versionName="(.*)"
```

  where the parentheses mark the spot to extract.
```
  WARNING: Only use single parentheses for each pattern!
           Currently there is no check for this, and pattern with
           multiple parentheses might cause havoc. Escape all
           parantheses that do not mark the version string.
```

  You can also give a list of patterns, separated by semicolon (;), 
  if you want to also bump other parts in the same file. As in example 
  above, the versionCode. E.g.

```
android:versionCode="(.*)"; android:versionName="(.*)"
```

  The script automatically adds ".*" to start and end of the pattern,
  so that user only needs to give just enough to uniquely identify
  the spot.

  If a list of patterns is given, the user then also needs give a                                  
  list of formats, as described next. 

### Version format: 
  Consist of two groups, dot (.) separated and hyphen (-) separated. E.g.

```
major.minor.hotfix-revision
```

  would result in having 4 bumpable VERSION_PART variables, major, minor, hotfix and revision.
  Each part name must be unique. Similarly,

```
common_major.common_minor-special_major.special_minor-version_name
```

  would result in 5 variables. It is also possible to directly set the version
  variable, which is more sensible for "version_name" rather than bumping.

  You may give a list of formats, if you gave a list of patterns. Items in the list
  are separated by semicolon (;) and there has to be equal order and number of items
  as in the patterns list. For example (following the android example):'

```
vcode; major.minor.hotfix
```

## show

Display the version number, or part of it.
E.g. version number format setup to major.minor.hotfix-rev:

```
$>./version.sh show
0.1.0-1
$>./version.sh show minor
1
$>./version.sh show hotfix
0
```

## bump

Bump (+1) a part of the version number. Only makes sense for
numeric (natural number) values.
E.g. version number format setup to major.minor.hotfix-name
and version number 0.1.0-customer:

```
$>./version.sh bump major
Bumped major, version: 1.1.0-customer
$>./version.sh bump minor
Bumped minor, version: 1.2.0-customer
```

This won't work:

```
$>./version.sh bump name
Error: Part 'name' is not a number. Use 'version.sh set rev newValue' instead?
```

## set

Set a part of the version number to a value.
E.g. version number format setup to major.minor.hotfix-rev
and version number 0.1.0-1:

```
$>./version.sh set rev 3
Modified rev, version: 0.1.0-3
$>./version.sh set minor 3
Modified minor, version: 0.2.0-3
$>./version.sh set hotfix 1
Modified hotfix, version: 0.2.1-3
```