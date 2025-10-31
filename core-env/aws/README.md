# AWS Infrastructure Management

## Setup user access via SSO

This terraform module uses a custom role (var.assumed_role) with specific permissions. Only those with access to assigned IT role (var.iam_sso_role) may access it.

To assume this role locally, you may setup an AWS config file `~/.aws/config` like such.

```
[default]
source_profile=admin
role_arn=arn:aws:iam::218691292270:role/iac-pipeline-role
role_session_name=eddie. # use your name here..
region=us-west-2

[profile admin]
region=us-west-2
output=json
sso_account_id=218691292270
sso_role_name=AdministratorAccess
sso_session=sso

[sso-session sso]
sso_start_url = https://akuity.awsapps.com/start/#
sso_region = us-east-2
sso_registration_scopes = sso:account:access
```

## Login

`aws sso login`

### Assumed Role (Default)

Running AWS commands will use the custom, limited role as default


### Adminstrator (Break the glass)

If you need to run elevated SSO commands, use the admin profile

`aws [COMMAND] --profile admin`
OR
`AWS_PROFILE=admin tofu [COMMAND]`