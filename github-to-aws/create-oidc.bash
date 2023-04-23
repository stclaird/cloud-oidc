#!/bin/bash
while getopts a:r: flag
do
    case "${flag}" in
        a) accountid=${OPTARG};;
        r) repo=${OPTARG};;
    esac
done

if [ -z "$accountid" ]
then 
	echo "Please supply valid AWS Account ID (-a 1234567890)"
	exit 1
fi

if [ -z "$repo" ]
then 
	echo "Please supply valid Repo (-r GitHubOrg/GitHubRepo:* )"
	exit 1
fi

export AWS_ACCOUNT_ID=$accountid
export REPO_VALUE=$repo

openssl s_client -servername token.actions.githubusercontent.com -showcerts -connect token.actions.githubusercontent.com:443 < /dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | sed "0,/-END CERTIFICATE-/d" > certificate.crt

THUMBLIST=$(openssl x509 -in certificate.crt -fingerprint -noout | cut -f2 -d'=' | tr -d ':' | tr '[:upper:]' '[:lower:]')

echo "$THUMBLIST"

OPENIDPROVIDERARN=$(aws iam create-open-id-connect-provider \
	--url https://token.actions.githubusercontent.com \
	--client-id-list "sts.amazonaws.com" \
	--thumbprint-list ${THUMBLIST} \
	| jq -r .OpenIDConnectProviderArn)

envsubst < trust-policy.json.tmpl > trust-policy.json

aws iam create-role --role-name github-actions --assume-role-policy-document file://trust-policy.json > /dev/null

ROLE_ARN=$(aws iam get-role --role-name github-actions | jq -r '.Role .Arn')

echo "Use this ARN in your github action's role-to-assume: ${ROLE_ARN}"
