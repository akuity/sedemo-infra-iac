# AWS Infrastructure Management

## Setup user access via SSO

This terraform creates 2 roles with specific permissions. 

- `sedemo-operator-role` (var.limited_assumed_role) 
  Grants limited, read-only permissions, Only those with access to assigned IT role (var.iam_sso_role) may access it.
- `sedemo-pipeline-role` (var.limited_priveledged_role) 
  Grants elevated, read-write permissions, intended for use by GHA piplines via OIDC, but may be accessed by team if needed.

To assume these roles, or the IT provided admin role locally, you may setup an AWS config file `~/.aws/config` like such.

```
[default]
# This is the operator read-only role
source_profile=admin
role_arn=arn:aws:iam::218691292270:role/sedemo-iac-operator-role
role_session_name=eddie
region=us-west-2

[profile pipeline]
# Elevated write access
source_profile=admin
role_arn=arn:aws:iam::218691292270:role/sedemo-iac-pipeline-role
role_session_name=eddie
region=us-west-2

[profile admin]
# Full admin
region=us-west-2
output=json
sso_account_id=218691292270
sso_role_name=AdministratorAccess
sso_session=sso

[sso-session sso]
# This instructs AWS how to use our SSO provider
sso_start_url = https://akuity.awsapps.com/start/#
sso_region = us-east-2
sso_registration_scopes = sso:account:access
```

## Login

`aws sso login`

### Assumed Role (Default)

Running AWS commands will use the custom, limited role as default


### Elevated (Break the glass)

If you need to run elevated SSO commands, use the pipeline profile

`aws [COMMAND] --profile pipeline`
OR
`AWS_PROFILE=pipeline tofu [COMMAND]`


## Verify my role

The easiest way to verify that you are in right role is with `aws sts get-caller-identity`, and look at the returned `arn` to either contain `AdminstratorAccess`, `sedemo-iac-pipeline-role`, or `sedemo-iac-operator-role`


```
{
    "UserId": "XXXXX",
    "Account": "XXXXXXX",
    "Arn": "arn:aws:sts::XXXXX:assumed-role/AWSReservedSSO_AdministratorAccess_e2e980dbad09a8b6/eddie.webbinaro@akuity.io"
}
```