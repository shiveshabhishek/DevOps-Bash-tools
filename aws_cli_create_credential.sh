#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-20 17:26:21 +0000 (Sat, 20 Feb 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates an AWS service account for AWS CLI to avoid having to re-login every day via SSO with 'aws sso login'

Grants this service account Administator privileges in the current AWS account

Creates an IAM access key (deleting an older unused key if necessary), writes a CSV just as the UI download would, and outputs both shell export commands and configuration in the format for copying to your AWS profile in ~/.aws/credentials

The following optional arguments can be given:

- user name         (default: \$USER-cli)
- keyfile           (default: ~/.aws/keys/\${user}_\${aws_account_id}_accessKeys.csv) - be careful if specifying this, a non-existent keyfile will create a new key, deleting the older of 2 existing keys if necessary to be able to create this

This can also be used as a backup credential - this way if something accidentally happens to your AWS SSO you can still get into your account

Idempotent - safe to re-run, will skip creating a user that already exists or CSV export that already exists


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<username> <keyfile>]"

help_usage "$@"

#min_args 1 "$@"

user="${1:-$USER-cli}"

aws_account_id="$(aws sts get-caller-identity --query Account --output text)"

access_keys_csv="${2:-$HOME/.aws/keys/${user}_${aws_account_id}_accessKeys.csv}"

export AWS_DEFAULT_OUTPUT=json

aws_create_user_if_not_exists "$user"

exports="$(aws_create_access_key_if_not_exists "$user" "$access_keys_csv")"

timestamp "Granting Administrator permissions on account '$aws_account_id' to user '$user'"
aws iam attach-user-policy --user-name "$user" --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'

echo
echo "Set the following export commands in your environment to begin using this access key in your CLI immediately:"
echo
echo "$exports"
echo
echo "or add the following to your ~/.aws/credentials file:"
echo
aws_access_keys_exports_to_credentials <<< "$exports"
echo
echo