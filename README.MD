
# Tools and scripts for setting up OIDC connections to cloud providers.
Useful tools for authenticating services such as GitHub actions to Cloud Providers to AWS, GCP etc without using long lasting security keys.

## Examples

### Setting up AWS Authentication from GITHUB Actions
Change to the git-hub-aws.

Run the `create-oidc.bash`, and supply the two mandatory parameters:

 -a AWS account id string 1234567890

 -r The repository hosting the actions in the following format `<GITHUB-ORGANISATION>/<MY_REPOSITORY>:<BRANCH>`.

For example, if I wanted to authenticate from my stclaird account or organisation  and the repository myrepo from any branch.

```
bash create-oidc.bash -a 1234567890 -r "stclaird/myrepo:*" -n github-actions-eks
```

Note, The last part can be an asterisks wildcard to represent all branches.

This will perform the following operations:

- Downloads the certifcate from github actions endpoint `token.actions.githubusercontent.com`
- Extracts thumbprint from the download certifcate in the previous step.
- Creates an IAM open-id-connect provider and supplies the thumb print extracted in the previous step and the string sts.amazonaws.com as the client-id-list / audience value.
- Creates an IAM trust policy in json format.
- Creates an IAM role called `github-oidc` and attaches the created trust policy.

This will output an ARN of the IAM role to assume.  This can be used in a github action such as the official one here https://github.com/marketplace/actions/configure-aws-credentials-for-github-actions
```
- name: configure aws credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        role-to-assume: arn:aws:iam::1234567890:role/github-actions
        role-session-name: samplerolesession
        aws-region: us-west-2
```

### Setting up GCP Authentication from GITHUB Actions
Change to the `github-to-gcp` directory.

Run the `create-oidc.bash` script with the following parameters:

 -g GCP project ID (e.g., `my-project-id`)

 -p Workload Identity Pool name (e.g., `github-pool`)

 -o OIDC provider name (e.g., `github-oidc`)

 -s Service Account name (e.g., `github-actions-sa`)

 -r The repository in the format `<GITHUB-ORGANISATION>/<MY_REPOSITORY>`

For example, if you want to authenticate from the `stclaird/myrepo` repository:

```bash
cd github-to-gcp
bash create-oidc.bash -g my-gcp-project -p github-pool -o github-oidc -s github-actions-sa -r "stclaird/myrepo"
```

This will perform the following operations:

- Creates a Workload Identity Pool in your GCP project
- Creates an OIDC provider configured for GitHub Actions
- Creates a service account for GitHub Actions to use
- Binds the service account with the Workload Identity Pool for your specific repository
- Outputs the values needed for your GitHub Action workflow

The script will output something like:

```
=========================================
Setup Complete! Use these values in your GitHub Action:
=========================================

workload_identity_provider: 'projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-oidc'
service_account: 'github-actions-sa@my-gcp-project.iam.gserviceaccount.com'
```

Use these values in your GitHub Action with the official Google Auth action:

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v1
  with:
    workload_identity_provider: 'projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-oidc'
    service_account: 'github-actions-sa@my-gcp-project.iam.gserviceaccount.com'
```
