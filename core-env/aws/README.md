# AWS Infrastructure Management


## Initial Akuity Team Access

### AWS Account

If you don't already have access, open an IT ticket requesting access to `akuity-demo` account in AWS, with `PowerUser` role.

### AWS CLI

You will need to install latest AWS CLI.

### Setup user access via SSO

This terraform creates 2 roles with specific permissions with slightly different levels of access.  The first gives full access rights to EKS cluster, but limited AWS rights.  The second is much more powerful AWS access. 

- `sedemo-operator-role` (var.limited_assumed_role) 
  Grants limited, read-only permissions, Only those with access to assigned IT role (var.iam_sso_role) may access it.
- `sedemo-pipeline-role` (var.priviledged_assumed_role) 
  Grants elevated, read-write permissions, intended for use by GHA piplines via OIDC, but may be accessed by team if needed.

To assume these roles, or the IT provided admin role locally, you may setup an AWS config file `~/.aws/config` like such.

```
[default]
source_profile=admin
role_arn=arn:aws:iam::218691292270:role/sedemo-iac-operator-role
role_session_name=eddie
region=us-west-2
sso_session=sso

[profile pipeline]
source_profile=admin
role_arn=arn:aws:iam::218691292270:role/sedemo-iac-pipeline-role
role_session_name=eddie
region=us-west-2
sso_session=sso

[profile admin]
region=us-west-2
output=json
sso_account_id=218691292270
sso_role_name=PowerUser
sso_session=sso

[sso-session sso]
sso_start_url = https://akuity.awsapps.com/start/#
sso_region = us-east-2
sso_registration_scopes = sso:account:access
```

## Login

`aws sso login`

### Assumed Role (Default)

Running AWS commands will use the custom, limited role as default. This is enough for full EKS admin access, but not to manipulate AWS resources.


### Elevated (Break the glass)

If you need to run elevated AWS commands, use the pipeline profile. **Think twice before using this role**. Anything we need should be codifieed as IaC, and whatver you do in this role can be destroyed by terraform's next run.

`aws [COMMAND] --profile pipeline`
OR
`AWS_PROFILE=pipeline tofu [COMMAND]`


### Verify my role

The easiest way to verify that you are in right role is with `aws sts get-caller-identity`, and look at the returned `arn` to either contain `PowerUser`, `sedemo-iac-pipeline-role`, or `sedemo-iac-operator-role`


```
{
    "UserId": "XXXXX",
    "Account": "XXXXXXX",
    "Arn": "arn:aws:sts::XXXXX:assumed-role/AWSReservedSSO_PowerUserAccess_8de5f1934424d9c6/eddie.webbinaro@akuity.io"
}
```