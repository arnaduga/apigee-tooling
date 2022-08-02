#!/bin/bash
# Goal: generate a file with status (=name and revision) deployed on every environment of an org (+ hash ?)



## NOTE : this script only output DEBUG log, as the "normal" behavior will be to display directly the result
##        Reason is CICD: if "normal" result can be parsed or redirected into file, that could help for CICD/automation
SCRIPT_ROOT=$( (cd "$(dirname "$0")" && cd .. && pwd ))
source "$SCRIPT_ROOT/lib/logutils.sh"
source "$SCRIPT_ROOT/lib/apigee-common.sh"

usage () {
    echo "Usage: deployments-status.sh -c <configFile.json> [-d] [-h]"
    echo ""
    echo "  -c <configFile.json>    MANDATORY   : the fullpath of config file that list org/env to browse"
    echo "  -d                      OPTIONAL    : Activate the debug log mode"
    echo "  -h                      OPTIONAL    : Display THIS message"
    echo ""
    echo ""
    echo "Script display logs on STDERR, and useful result on STDOUT."
    echo ""
    echo "To get in the console only the useful result, you can use: deployment-status.sh -c config.json 2> /dev/null"
    echo ""
    echo "To display a sorted version (more readability of identical hashes): deployment-status.sh -c config.json 2> /dev/null | sort -k6"
    echo ""
}

getHash () {
    local ORG=$1
    local ENV=$2
    local PROXYNAME=$3
    local PROXYREVISION=$4
    local PROXYDATE=$5

    logdebug "HASH - Inputs: $ORG/$ENV/$PROXYNAME/$PROXYREVISION"
    FILENAME=$(mktemp)
    logdebug "HASH - Target filename: $FILENAME"

    loginfo "HASH - Getting BUNDLE for $ORG // $PROXYNAME // $PROXYREVISION"
    URI="https://apigee.googleapis.com/v1/organizations/$ORG/apis/$PROXYNAME/revisions/$PROXYREVISION?format=bundle"

    RESPONSE=$(curl -s -o $FILENAME -w "%{http_code}" -X GET -H "Authorization: Bearer $AUTH" $URI)
    RETURN_CODE=$(tail -n1 <<< "$RESPONSE")
    CONTENT=$(sed '$ d' <<< "$RESPONSE")

    logdebug "HASH - URI: $URI"
    logdebug "HASH - RETURN_CODE: $RETURN_CODE"
    
    if [ $RETURN_CODE != "200" ]; then
        logfatal "BUNDLE - Downloading the ZIP bundle failed. Exiting."
        exit 8
    fi

    logdebug "$(unzip -vqql "$FILENAME" | awk '{printf("%s %s\n",$7,$8)}' | sort -k2 | tail -n +3)"

    HASH=($(md5sum <<< $(unzip -vqql "$FILENAME" | awk '{printf("%s %s\n",$7,$8)}' | sort -k2 | tail -n +3)))

    if [ $? != 0 ]; then
        logfatal "HASH - Error while calculating the HASH. Exiting."
        exit 9
    fi
    displayProxyRevisionHash $ORG $ENV $PROXYNAME $PROXYREVISION $PROXYDATE $HASH
    rm $FILENAME
}

displayProxyRevisionHash () {
    local ORG=$1
    local ENV=$2
    local PROXYNAME=$3
    local PROXYREVISION=$4
    local PROXYDATE=$5
    local HASH=$6

    FORMATROW="%-20s %-8s %-30s %-4s %-20s %-32s\n"
    printf "$FORMATROW" "$ORG" "$ENV" "$PROXYNAME" "$PROXYREVISION" "$PROXYDATE" "$HASH"
}

getDeployments () {
    logdebug "GETDEPL - organizations/$ORG/environments/$ENV"
    getEnvironmentDeployments $ORG $ENV
    DEPL=$(jq -r '.deployments[] | .apiProxy + "=" +  .revision + "=" + .deployStartTime' <<< $CONTENT)
    
    while IFS= read -r oneDepl
    do
        PROXYNAME=$(echo $oneDepl | cut -f1 -d=)
        PROXYREVISION=$(echo $oneDepl | cut -f2 -d=)
        PROXYDATE=$(echo $oneDepl | cut -f3 -d=)
        PROXYDATE=$(date -d @${PROXYDATE::-3} +'%FT%T')
        getHash $ORG $ENV $PROXYNAME $PROXYREVISION $PROXYDATE
    done <<< "$DEPL"
}

parseFile () {

    logdebug "PARSE - Browsing config file setup"
    INSTANCES=$(jq -c -r '.instances' $FULLPATHFILE)
    local L=$(jq -c -r '. | length' <<< $INSTANCES)

    if [  $L -lt 1 ]; then
        logfatal "PARSE - No instance found in the file."
        exit 7
    else
        logdebug "PARSE - Config file has $L organizations"
    fi 
    
    ORGS=$(jq -c -r '.[].organization' <<< $INSTANCES)

    loginfo "PARSE - Getting authentication gcloud token"
    getAuth




    for ORG in $ORGS
    do
        logdebug "PARSE - Check existence of organizations/$ORG"
        checkOrganization $ORG

        ENVS=$(jq --arg o "$ORG" -c -r '.[]| select(.organization | contains($o)) | .environments[]' <<< $INSTANCES)

        for ENV in $ENVS
        do
            logdebug "PARSE - Check existence of organization/$ORG/environments/$ENV"
            checkEnvironment $ORG $ENV
            getDeployments $ORG $ENV 
        done
    done

}

checkPrereq () {

    # Checking mandatory arguments
    if [ -z "${CONFIG}" ]; then
        logfatal "PREREQ - Missing confif file argument (-c)"
        usage
        exit 5
    else
        logdebug "PREREQ - Config file argument: $CONFIG"
    fi

    # Checking if CONFIG is really a file
    FULLPATHFILE=$(readlink -m $CONFIG)
    logdebug "PREREQ - Full path: $FULLPATHFILE"
    if ! [ -f $FULLPATHFILE ]; then
        logfatal "PREREQ - The argument ($FULLPATHFILE) is not a file, or not found"
        exit 6
    else
        logdebug "PREREQ - The argument ($FULLPATHFILE) seems good."
    fi

    # Checking commands prerequisites
    loginfo "PREREQ - Checking dependencies"
    for dependency in jq gcloud md5sum tail curl sed readlink unzip awk sort tail
        do
        logdebug "PREREQ - Checking for command/tool $dependency"
        if ! [ -x "$(command -v $dependency)" ]; then
            >&2 logfatal "PREREQ - Required command is not on your PATH: $dependency."
            >&2 logfatal "PREREQ - Please install it before you continue."
            exit 3
        fi
    done       
}



getDeployements () {
    getAuth

    URI="https://apigee.googleapis.com/v1/organizations/apim-staging-350613/environments/dev/deployments"
    RESPONSE=$(curl -s -w "%{http_code}" -X GET -H "Authorization: Bearer $AUTH" $URI)
    RETURN_CODE=$(tail -n1 <<< "$RESPONSE")
    CONTENT=$(sed '$ d' <<< "$RESPONSE")

    DEPLOYMENTS=$(jq -r -c '.deployments[]' <<< $CONTENT)

    for DEPLOYMENT in ${DEPLOYMENTS[@]}; do
        PROXYNAME=$(jq -r -c '.apiProxy' <<< $DEPLOYMENT)   
        REVISION=$(jq -r -c '.revision' <<< $DEPLOYMENT)   
       
        URI="https://apigee.googleapis.com/v1/organizations/apim-staging-350613/apis/$PROXYNAME/revisions/$REVISION"

        RESPONSE=$(curl -s -o /tmp/$PROXYNAME-$REVISION.zip -X GET -H "Authorization: Bearer $AUTH" $URI)
        
        HASHRESULT=($(md5sum /tmp/$PROXYNAME-$REVISION.zip))

        logdebug "Delete temp fil /tmp/$PROXYNAME-$REVISION.zip"
        rm /tmp/$PROXYNAME-$REVISION.zip

        DEPLOYMENT=$(jq --arg v $HASHRESULT '. += {"md5hash": $v}' <<< $DEPLOYMENT)
    done
}

while getopts "c:dh" option; do
    case "${option}" in
        h)
            usage
            exit 2
            ;;
        c)
            CONFIG=${OPTARG}
            loginfo "MAIN - Config file input: $CONFIG"
            ;;
        d) 
            # DEBUG mode activated
            debug="T"
            logdebug "DEBUG mode activated. "
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))



checkPrereq
parseFile $CONFIG



