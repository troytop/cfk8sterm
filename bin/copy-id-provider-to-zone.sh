#!/bin/bash
set -e

USAGE=$(cat <<-END

Usage: $0 IDENTITY-API-URI ZONENAME [-k]

This tool copies the LDAP identity provider from the default UAA zone to the specified zone.
Examples:
- Copy LDAP provider to 'myhcf' zone
  $0 https://uaa.192.168.77.77.nip.io myhcf -k

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
SKIP_SSL="${3:-}"
ROOT=$(cd $(dirname $0) && echo $PWD)
. $ROOT/common.sh
check_jq
TOKEN=$(< $HOME/.hcp jq --raw-output .AccessToken)
check_token "$IDBASE" "$TOKEN" "$SKIP_SSL"

ZONEFILE=$(mktemp /tmp/zfXXXXX.json)
trap "rm -f $ZONEFILE" 0 1 2 3 9 15

curl -s $SKIP_SSL -H 'Accept: application/json' \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        $IDBASE/identity-zones | jq -r '.[].id' > $ZONEFILE
if `! grep -q '^'$ZONE'$' $ZONEFILE` ; then
    echo "zone $ZONE doesn't exist.  Here are the zones hcp knows about:"
    cat $ZONEFILE
    exit 2
fi


# get the ldap identity-provider config
oldConfig=$(curl -s $SKIP_SSL -H 'Accept: application/json' -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" $IDBASE/identity-providers?rawConfig=true |
    jq -r '.[] | select(.type == "ldap")')

fixedConfig=$(echo $oldConfig | jq 'del(.id) | del(.identityZoneId) | del(.last_modified) | del(.created)')

curl -s $SKIP_SSL -X POST -H 'Accept: application/json' \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "X-Identity-Zone-Id: $ZONE" \
    $IDBASE/identity-providers -d "$fixedConfig"
