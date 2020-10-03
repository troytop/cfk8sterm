#!/bin/bash
set -e

USAGE=$(cat <<-END

Usage: $0 IDENTITY-API-URI ZONENAME FIELD DESIRED-VALUE [-k]

This tool changes LDAP identity provider config values.
Examples:
- Deactivate identity provider:
  $0 https://uaa.192.168.77.77.nip.io hcf active false  -k
- Change LDAP password:
  $0 https://uaa.192.168.77.77.nip.io hcf config.bindPassword '"mypassword"' -k
 
END
)

IDBASE=$1
if [ -z "${IDBASE:-}" ] ; then
    echo "IdentityAPI Endpoint not given. $USAGE"
    exit 1
fi
ZONE=$2
if [ -z "${ZONE:-}" ] ; then
    echo "Zone not given. $USAGE"
    exit 1
fi
FIELDNAME=$3
if [ -z "${FIELDNAME:-}" ] ; then
    echo "Field name not given. $USAGE"
    exit 1
fi
FIELDVALUE="$4"
if [ -z "${FIELDVALUE:-}" ] ; then
    echo "Desired Field value not given. $USAGE"
    exit 1
fi
SKIP_SSL="${5:-}"
ROOT=$(cd $(dirname $0) && echo $PWD)
. $ROOT/common.sh
check_jq
TOKEN=$(< $HOME/.hcp jq --raw-output .AccessToken)
check_token $IDBASE $TOKEN "$SKIP_SSL"

# get the ldap identity-provider config
oldConfig=$(curl -s $SKIP_SSL -H 'Accept: application/json' \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "X-Identity-Zone-Id: $ZONE" \
    $IDBASE/identity-providers?rawConfig=true |
    jq -r '.[] | select(.type == "ldap")')
id=$(echo $oldConfig | jq -r .id)
fixedConfig=$(echo $oldConfig | jq ".$FIELDNAME=$FIELDVALUE")

curl -s -S $SKIP_SSL -X PUT -H 'Accept: application/json' \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "X-Identity-Zone-Id: $ZONE" \
    $IDBASE/identity-providers/$id -d "$fixedConfig"
