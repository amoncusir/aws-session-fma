#!/usr/bin/env bash

## Constants ###########################################################################################################

TRUE=0
FALSE=1

CR=`echo $'\n'.`
CR=${CR%.}

AWS_SESSION="arn:aws:iam::XXXXXXXXXXXX:mfa/<username>"

## Functions ###########################################################################################################

getUserData ()
{
    ##
    # $1 -> message - Message that print to user
    # $2 -> args - any arguments for read
    ##

    ## Arguments
    local message=$1

    ## Steps
    # Read from input and save in doIt local variable
    read ${@:2} -p "$message $CR > " doIt

    echo ${doIt}
}

checkProgram ()
{
    ##
    # $1 -> program - Message that print to user
    # $2 -> nullResult - Message that print to user
    ##

    ## Arguments
    local program=$1
    local nullResult=$2

    ## Steps
    echo `command -v ${program} || echo ${nullResult}`
}

## Steps ###############################################################################################################

if [[ "${BASH_SOURCE[0]}" = "${0}" ]] ; then
    echo "This script needs to run using source command!"
    exit 1
fi

if [[ $(checkProgram jq "none") = "none" ]];
then
    echo "Need use 'jq', but it's not installed. Aborting."
else

    MFA_CODE=$( getUserData "Set MFA Code" )

    # Prepare variables and delete them
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN

    CREDENTIALS=$(aws sts get-session-token --serial-number ${AWS_SESSION} --token-code ${MFA_CODE})

    if ${CREDENTIALS} 2>/dev/null; then
        echo "Invalid credentials"
    else

        # Export access env variables for AWS
        export AWS_ACCESS_KEY_ID="$(echo ${CREDENTIALS} | jq -r ".Credentials.AccessKeyId")"
        export AWS_SECRET_ACCESS_KEY="$(echo ${CREDENTIALS} | jq -r ".Credentials.SecretAccessKey")"
        export AWS_SESSION_TOKEN="$(echo ${CREDENTIALS} | jq -r ".Credentials.SessionToken")"

        echo "Success login with access: $AWS_ACCESS_KEY_ID"

    fi
fi
