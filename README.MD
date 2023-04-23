
# Tools and scripts for setting up OIDC connections to cloud providers.
Useful tools for authenticating services such as GitHub actions to Cloud Providers to AWS, GCP etc without using long lasting security keys.

## Examples
Run the following command, the parameter -a is the AWS account id. -r Is a string representing the repository <GITHUB-ORGANISATION>/<MY_REPOSITORY>:<BRANCH>.  Branch can be a wildcard for all branches.


```
bash create-oidc.bash -a 1234567890 -r stclaird/myrepo:*
```
