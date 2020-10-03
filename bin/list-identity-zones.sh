#!/bin/bash
set -e

IDBASE=$1
if [ -z "${IDBASE}" ] ; then
   echo "$0: No Identity endpoint given."
   echo "Usage: $0 Identity-API-URI [-k]"
   exit 1
fi
SKIP_SSL="${2:-}"
ROOT=$(cd $(dirname $0) && echo $PWD)
. $ROOT/common.sh
check_jq
TOKEN=$(< $HOME/.hcp jq --raw-output .AccessToken)
check_token "$IDBASE" "$TOKEN" "$SKIP_SSL"

curl -s $SKIP_SSL -H 'Accept: application/json' \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        $IDBASE/identity-zones | jq -r '.[].id'
