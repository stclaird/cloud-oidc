#!/bin/bash
while getopts :a:r:n: flag
do
    case "${flag}" in
        a) accountid=${OPTARG};;
        r) repo=${OPTARG};;
		n) name=${OPTARG};;
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

if [ -z "$name" ]
then 
	echo "Please supply role name (-n github-oidc )"
	exit 1
fi
export AWS_ACCOUNT_ID=$accountid
export REPO_VALUE=$repo

export ROLE_NAME=$name

echo $name

OPENIDPROVIDERARN=$(aws iam list-open-id-connect-providers | jq -r '.OpenIDConnectProviderList[].Arn' | grep '/token.actions.githubusercontent.com$')

if [ -n "$OPENIDPROVIDERARN" ]
then
	echo "OIDC provider already exists, reusing: ${OPENIDPROVIDERARN}"
else
	openssl s_client -servername token.actions.githubusercontent.com -showcerts -connect token.actions.githubusercontent.com:443 < /dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | sed "0,/-END CERTIFICATE-/d" > certificate.crt
	THUMBLIST=$(openssl x509 -in certificate.crt -fingerprint -noout | cut -f2 -d'=' | tr -d ':' | tr '[:upper:]' '[:lower:]')

	OPENIDPROVIDERARN=$(aws iam create-open-id-connect-provider \
		--url https://token.actions.githubusercontent.com \
		--client-id-list "sts.amazonaws.com" \
		--thumbprint-list ${THUMBLIST} \
		| jq -r .OpenIDConnectProviderArn)
fi

cat > trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
              "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
            },
            "StringLike": {
              "token.actions.githubusercontent.com:sub": "repo:${REPO_VALUE}"
            }
        }
      }
    ]
}
EOF
if aws iam get-role --role-name ${ROLE_NAME} > /dev/null 2>&1
then
	echo "Role ${ROLE_NAME} already exists, updating its trust policy"
	aws iam update-assume-role-policy --role-name ${ROLE_NAME} --policy-document file://trust-policy.json
else
	aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file://trust-policy.json > /dev/null
fi
ROLE_ARN=$(aws iam get-role --role-name  ${ROLE_NAME} | jq -r '.Role .Arn')
echo "This is the role-to-assume: ${ROLE_ARN}"
