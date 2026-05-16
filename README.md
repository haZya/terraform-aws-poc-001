# PoC-001 Terraform

This repo uses separate Terraform root modules per environment and a shared `modules/app` module.

```text
bootstrap/
  state/                 # local-state setup for the shared Terraform state bucket
  accounts/staging/      # local-state setup for the staging GitHub Actions role
  accounts/prod/         # local-state setup for the production GitHub Actions role
  modules/               # bootstrap-only reusable modules
envs/dev/                # local CLI testing against a personal dev AWS account
envs/staging/            # GitHub-deployed staging environment
envs/prod/               # GitHub-deployed production environment
modules/app/             # reusable app infrastructure
```

## Bootstrap Order

All bootstrap roots use local state. Use a fixed state account ID up front so the future state bucket name is known before the bucket exists.

With the default convention, the bucket name is:

```text
{app_name}-terraform-state-<state-account-id>
```

For example:

```text
poc-001-terraform-state-000000000000
```

Create the GitHub OIDC deployment roles first. IAM policies can reference the future state bucket ARN before the bucket exists.

PowerShell:

```powershell
Copy-Item bootstrap/accounts/staging/terraform.tfvars.example bootstrap/accounts/staging/terraform.tfvars
terraform -chdir=bootstrap/accounts/staging init
terraform -chdir=bootstrap/accounts/staging apply
terraform -chdir=bootstrap/accounts/staging output github_actions_role_arn
```

sh/bash/zsh:

```sh
cp bootstrap/accounts/staging/terraform.tfvars.example bootstrap/accounts/staging/terraform.tfvars
terraform -chdir=bootstrap/accounts/staging init
terraform -chdir=bootstrap/accounts/staging apply
terraform -chdir=bootstrap/accounts/staging output github_actions_role_arn
```

PowerShell:

```powershell
Copy-Item bootstrap/accounts/prod/terraform.tfvars.example bootstrap/accounts/prod/terraform.tfvars
terraform -chdir=bootstrap/accounts/prod init
terraform -chdir=bootstrap/accounts/prod apply
terraform -chdir=bootstrap/accounts/prod output github_actions_role_arn
```

sh/bash/zsh:

```sh
cp bootstrap/accounts/prod/terraform.tfvars.example bootstrap/accounts/prod/terraform.tfvars
terraform -chdir=bootstrap/accounts/prod init
terraform -chdir=bootstrap/accounts/prod apply
terraform -chdir=bootstrap/accounts/prod output github_actions_role_arn
```

Then create the shared state bucket and bucket policy. Add the role ARNs from the account bootstrap outputs to `trusted_state_principal_arns` before the first apply.

PowerShell:

```powershell
Copy-Item bootstrap/state/terraform.tfvars.example bootstrap/state/terraform.tfvars
terraform -chdir=bootstrap/state init
terraform -chdir=bootstrap/state apply
terraform -chdir=bootstrap/state output state_bucket_name
```

sh/bash/zsh:

```sh
cp bootstrap/state/terraform.tfvars.example bootstrap/state/terraform.tfvars
terraform -chdir=bootstrap/state init
terraform -chdir=bootstrap/state apply
terraform -chdir=bootstrap/state output state_bucket_name
```

Finally, replace `000000000000` with the real state account ID in:

```text
envs/dev/backend.hcl
envs/staging/backend.tf
envs/prod/backend.tf
```

## Local Profiles

Local roots support a local-only `profile` variable in ignored `terraform.tfvars` files, so you do not need to export `AWS_PROFILE`.

Example dev config:

```hcl
region         = "ap-southeast-2"
profile        = "dev"
aws_account_id = "111111111111"
```

For the S3 backend, also set the profile in local `envs/dev/backend.hcl`:

```hcl
bucket       = "poc-001-terraform-state-000000000000"
key          = "poc-001/dev/111111111111/terraform.tfstate"
region       = "ap-southeast-2"
profile      = "dev"
encrypt      = true
use_lockfile = true
```

## Local Dev

PowerShell:

```powershell
Copy-Item envs/dev/terraform.tfvars.example envs/dev/terraform.tfvars
Copy-Item envs/dev/backend.hcl.example envs/dev/backend.hcl
terraform -chdir=envs/dev init -backend-config=backend.hcl
terraform -chdir=envs/dev apply
```

sh/bash/zsh:

```sh
cp envs/dev/terraform.tfvars.example envs/dev/terraform.tfvars
cp envs/dev/backend.hcl.example envs/dev/backend.hcl
terraform -chdir=envs/dev init -backend-config=backend.hcl
terraform -chdir=envs/dev apply
```

For local dev, use the dev account ID in the state key:

```hcl
key = "poc-001/dev/111111111111/terraform.tfstate"
```

The account ID keeps each developer's dev state separate while still using the same central state bucket.

## GitHub Environments

Create GitHub environments named `staging` and `production`.

Set this environment variable on each one:

```text
AWS_ROLE_ARN
```

Use the role ARN output from the matching bootstrap account root.

Staging and production Terraform values are committed in:

```text
envs/staging/terraform.tfvars
envs/prod/terraform.tfvars
```

The state bucket can be the same bucket for all environments. If that bucket is in a separate AWS account, the bucket policy must trust the GitHub deployment roles that need to read/write Terraform state.
