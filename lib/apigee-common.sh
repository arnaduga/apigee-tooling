checkOrganization () {

    local ORG=$1

    loginfo "ORG - Checking organization $ORG"

    URI="https://apigee.googleapis.com/v1/organizations/$ORG"
    RESPONSE=$(curl -s -w "%{http_code}" -X GET -H "Authorization: Bearer $AUTH" $URI)
    RETURN_CODE=$(tail -n1 <<< "$RESPONSE")
    CONTENT=$(sed '$ d' <<< "$RESPONSE")

    logdebug "ORG - URI: $URI"
    logdebug "ORG - RETURN_CODE: $RETURN_CODE"
    
    if [ $RETURN_CODE != "200" ]; then
        logdebug "ORG - CONTENT: $CONTENT"
        logfatal "ORG - Check of $ORG organization failed. Exiting."
        exit 5
    fi
}


checkEnvironment () {
    local ORG=$1
    local ENV=$2

    loginfo "ENV - Checking environment $ENV"

    URI="https://apigee.googleapis.com/v1/organizations/$ORG/environments/$ENV"
    RESPONSE=$(curl -s -w "%{http_code}" -X GET -H "Authorization: Bearer $AUTH" $URI)
    RETURN_CODE=$(tail -n1 <<< "$RESPONSE")
    CONTENT=$(sed '$ d' <<< "$RESPONSE")

    logdebug "ENV - URI: $URI"
    logdebug "ENV - RETURN_CODE: $RETURN_CODE"
    
    if [ $RETURN_CODE != "200" ]; then
        logdebug "ENVRG - CONTENT: $CONTENT"
        logfatal "ENV - Check of $ORG/$ENV environment failed. Exiting."
        exit 5
    fi
}

getAuth () {
    if [ -z ${AUTH} ]; then
        loginfo "AUTH - Generating a new token"
        AUTH=$(gcloud auth print-access-token)
    else
        loginfo "AUTH - AUTH variable does exist and will be used to authenticate API calls."
    fi
    logdebug "${AUTH:0:15}*****"
}

getEnvironmentDeployments () { 
    local ORG=$1
    local ENV=$2

    loginfo "ENVDEPL - Get deployments on organization/$ORG/environments/$ENV"

    URI="https://apigee.googleapis.com/v1/organizations/$ORG/environments/$ENV/deployments"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET -H "Authorization: Bearer $AUTH" $URI)
    RETURN_CODE=$(tail -n1 <<< "$RESPONSE")
    CONTENT=$(sed '$ d' <<< "$RESPONSE")

    logdebug "RETURN CODE : $RETURN_CODE"
}