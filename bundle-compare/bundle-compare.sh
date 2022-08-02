#!/bin/bash

## ######################################
## bundle-compare.sh
##
## Version: 0.1
## Date: 2022-08-02
###
## Exit codes:
##  0: Bundles are the same (excluding "header" zip file)
##  1: Bundles are NOT the same
##  2: Wrong number of script arguments
##  3: Argument is not an existing file 
##  4: Dependencies are not satisfied
## ######################################

SCRIPT_ROOT=$( (cd "$(dirname "$0")" && cd .. && pwd ))
source "$SCRIPT_ROOT/lib/logutils.sh"

## Inspired from Stackoverflow answer: https://stackoverflow.com/a/44198080

# Test if arguments are there
if [ -z $1 ] || [ -z $2 ]; then
	logfatal "Missing arguments"
    loginfo "Usage: $0 bundle1.zip bundle2.zip"
	exit 2
fi

# Test if arguments are existing files
if ! [ -f $1 ] || ! [ -f $2 ]; then
	logfatal "Argument files not found or are not files"
	exit 3
fi

# Quickly checks for dependencies
for dependency in unzip awk sort tail
do
  if ! [ -x "$(command -v $dependency)" ]; then
    >&2 logfatal "Required command is not on your PATH: $dependency."
    >&2 logfatal "Please install it before you continue."
    exit 4
  fi
done

# Prepare awk format
A='{printf("%8sB %s %s\n",$1,$7,$8)}'

# Run the diff
diffRes=$(diff <(unzip -vqql "$1" | awk "$A" | sort -k3 | tail -n +3) <(unzip -vqql "$2" | awk "$A" | sort -k3 | tail -n +3);)

# Conclusions
if [ $? = 0 ]; then
	exit 0
else
	echo $diffRes
	exit 1
fi
