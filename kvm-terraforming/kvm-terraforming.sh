#!/bin/bash

## ######################################
## kvm-terraform.sh
##
## Version: 0.1
## Date: 2022-06-24
###
## Exit codes:
##  1: Wrong number of script argument (should be 1)
##  2: Argument is not an existing file 
##  3: Dependencies are not satisfied
##  4: Missing mandatory data on the argument JSON file 
##  5: Error while getting Google Cloud credentials 
##  6: Error while creating the kvm
##  7: Error while creating keys
## ######################################

# Small library for better log display
SCRIPT_ROOT=$( (cd "$(dirname "$0")" && cd .. && pwd ))
source "$SCRIPT_ROOT/lib/logutils.sh"
source "$SCRIPT_ROOT/lib/apigee-common.sh"

## FUNCTIONS ##########
upsert_kvm () {

    ## ########
    ## To create the MAP if it does not exist
    ## 
    ## Params
    ##   $1: Organization name
    ##   $2: Environment name 
    ##   $3: Map name name 
    ## ########

    loginfo "Processing KEYMAP $1 // $2 // $3"

    URI="https://apigee.googleapis.com/v1/organizations/$1/environments/$2/keyvaluemaps/$3"
    RETURN_CODE=$(curl -XGET -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $AUTH" $URI/entries)
    if [ $RETURN_CODE -eq "200" ]
    then
      loginfo "The KVM does already exist."
    else
      loginfo "The KVM does NOT exist. Requesting creation."
      URI="https://apigee.googleapis.com/v1/organizations/$1/environments/$2/keyvaluemaps"

      RESPONSE=$(curl -s -w "%{http_code}" -XPOST -H "Content-Type: application/json" -H "Authorization: Bearer $AUTH" -d '{"name":"'$3'","encrypted":true}' $URI)
      RETURN_CODE=$(tail -n1 <<< "$RESPONSE")
      CONTENT=$(sed '$ d' <<< "$RESPONSE")

      if [ $RETURN_CODE -eq "201" ]
      then
        loginfo "Keyvaluemap $3 successfully created."
      else
        logfatal "Something FAILED."
        logfatal "$CONTENT"
        logfatal "Stopping..."
        exit 6
      fi

      #loginfo "Command to delete the KVM: curl -XDELETE -H 'Authorization: Bearer xxxx' https://apigee.googleapis.com/v1/organizations/$1/environments/$2/keyvaluemaps/$3"
    fi
}

upsert_keys () {

    ## ########
    ## To delete/create the keys
    ## 
    ## Params
    ##   $1: Organization name
    ##   $2: Environment name 
    ##   $3: Map name name
    ##   $4: the keys JSON array
    ## ########

    loginfo "Processing KEYS for $1 // $2 // $3"
    
    # Broswing every key
    jq -c -r '.[] | select (.!=null)' <<< "$4" | while read KEY; do

      # Extractin keyname and keyvalue
      KEYNAME=$(jq -c -r '.name' <<< "$KEY")
      KEYVALUE=$(jq -c -r '.value' <<< "$KEY")
      loginfo "Creation key '$KEYNAME' with value '${KEYVALUE:0:5}******' (hidden for confidentiality)"

      # DELETE FIRST
      URI="https://apigee.googleapis.com/v1/organizations/$1/environments/$2/keyvaluemaps/$3/entries/$KEYNAME"
      RESPONSE=$(curl -s -w "%{http_code}" -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $AUTH" $URI)
      RETURN_CODE=$(tail -n1 <<< "$RESPONSE")
      CONTENT=$(sed '$ d' <<< "$RESPONSE")
      
      if [ $RETURN_CODE -eq "200" ]; then
        loginfo "Keys '$KEYNAME': deleted"
      fi

      # CREATE THEN
      URI="https://apigee.googleapis.com/v1/organizations/$1/environments/$2/keyvaluemaps/$3/entries"
      RESPONSE=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $AUTH" -d '{"name":"'$KEYNAME'","value":"'$KEYVALUE'"}' $URI)
      RETURN_CODE=$(tail -n1 <<< "$RESPONSE")
      CONTENT=$(sed '$ d' <<< "$RESPONSE")
      
      if [ $RETURN_CODE -eq "201" ]; then
        loginfo "Keys '$KEYNAME': created"
      else
        # Dmaned, something went wrong.
        logfatal "Error while creating key $KEYNAME"
        logfatal "$CONTENT"
        exit 7
      fi
    done
}





## SCRIPT ##########

# Check number of argument
if [ $# -ne 1 ]
then
    logerror "Wrong number of arguments"
    exit 1
fi

# Check if argument is a file
if [ ! -f $1 ]
then
    logerror "The argument must be an existing file"
    exit 2
fi



# Check dependencies
loginfo "Checking dependencies"
for dependency in jq gcloud
do
  if ! [ -x "$(command -v $dependency)" ]; then
    >&2 logfatal "Required command is not on your PATH: $dependency."
    >&2 logfatal "Please install it before you continue."
    exit 3
  fi
done


# Retrieves data from parameter file
KVMNAME=$(jq -c -r '.name | select (.!=null)' $1)
ORG=$(jq -c -r '.organization | select (.!=null)' $1)
ENV=$(jq -c -r '.environment | select (.!=null)' $1)
KEYS=$(jq -c -r '.keys' $1)

if [ -z ${KVMNAME:+x} ]; then
  logfatal "KVM Name not found"
  stop=1
fi
if [ -z ${ORG:+x} ]; then
  logfatal "ORG not found"
  stop=1
fi
if [ -z ${ENV:+x} ]; then
  logfatal "ENV not found"
  stop=1
fi
if [ ! -z ${stop:+x} ]; then
  logfatal "Missing mandatory information. Stopping here!"
  exit 4
fi


# GCLoud CREDS
loginfo "Getting GCloud credentials"
AUTH=$(gcloud auth print-access-token)

if [ -z ${AUTH:+x} ]; then
  logfatal "Error while getting creds. Stopping."
  exit 5
fi

# Check if ORG is OK
checkOrganization $ORG
# Check if ENV is OK
checkEnvironment $ORG $ENV


# Preliminaries are good. Let's start
# First, the MAP
upsert_kvm $ORG $ENV $KVMNAME 
# Second, the KEYS
upsert_keys $ORG $ENV $KVMNAME $KEYS

loginfo "Success. End of process"