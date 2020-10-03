#!/bin/bash
set -e

IDBASE=$1
if [ -z "${IDBASE}" ] ; then
   echo "$0: No Identity endpoint given."
   echo "Usage: $0 Identity-API-URI [ZONE] [-k]"
   exit 1
fi
shift
case $# in
    0) ZONE="" ; SKIP_SSL="" ;;
    1) case $1 in
	-k) SKIP_SSL="-k" ;;
         *) ZONE=$1 ; SKIP_SSL="";;
       esac ;;
    2) ZONE=$1 ; SKIP_SSL="$2" ;;
    *) echo "Too many arguments.  "
       echo "Usage: $0 Identity-API-URI [ZONE] [-k]" ;;
esac
ROOT=$(cd $(dirname $0) && echo $PWD)
. $ROOT/common.sh
check_jq
TOKEN=$(< $HOME/.hcp jq --raw-output .AccessToken)
check_token "$IDBASE" "$TOKEN" "$SKIP_SSL"

curl -s $SKIP_SSL -H 'Accept: application/json' \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -H "X-Identity-Zone-Id: $ZONE" \
        $IDBASE/Groups/External
