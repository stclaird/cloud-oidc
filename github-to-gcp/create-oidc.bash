#!/bin/bash
# bash -x create-oidc.bash -g my-gcp-project-id -r "my-user-or-my-org/my-repo" -p "my-pool" -o "my-oicd" -s "my-sa"


while getopts :g:p:o:s:r: flag
do
    case "${flag}" in
        g) PROJECT_ID=${OPTARG};;
        p) WIP_POOL_NAME=${OPTARG};;
        o) WIP_OIDC_PROVIDER=${OPTARG};;
        s) SA_NAME=${OPTARG};;
        r) REPO=${OPTARG};;
    esac
done

if [ -z "$PROJECT_ID" ]
then
  echo "Please enter your GCP project ID (e.g my-project-id)"
  read -r PROJECT_ID
  echo ${PROJECT_ID}
fi

if [ -z "$WIP_POOL_NAME" ]
then
  echo "Please enter a name for your Workload Identity Federation Pool Name (e.g my-wip-pool)"
  read -r WIP_POOL_NAME
fi

if [ -z "$WIP_OIDC_PROVIDER" ]
then
  echo "Please enter a name for your OIDC provider (e.g my-oidc-provider)"
  read -r WIP_OIDC_PROVIDER
fi

if [ -z "$SA_NAME" ]
then
  echo "Please enter a name for your service account (e.g my-github-sa)"
  read -r SA_NAME
fi

if [ -z "$REPO" ]
then
  echo "Please supply a valid Repo (-r in format GitHubOrg/GitHubRepo )"
  read -r REPO
fi


PROJECT_NUM=$(gcloud projects list --filter="ewnonprod" --format="value(PROJECT_NUMBER)")

gcloud iam workload-identity-pools create ${WIP_POOL_NAME} \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="${WIP_POOL_NAME} Pool"

gcloud iam workload-identity-pools providers create-oidc ${WIP_OIDC_PROVIDER} \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${WIP_POOL_NAME}" \
  --display-name="${WIP_OIDC_PROVIDER} OIDC" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

gcloud iam service-accounts create ${SA_NAME} \
--display-name="${SA_NAME} Service Account" \
--project ${PROJECT_ID}

gcloud iam service-accounts add-iam-policy-binding $SA_NAME@$PROJECT_ID.iam.gserviceaccount.com \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUM}/locations/global/workloadIdentityPools/$WIP_POOL_NAME/attribute.repository/$REPO"
