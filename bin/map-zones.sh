#!/usr/bin/env bash
# Map HCF admin-level scopes to ldap groups

set -e

USAGE=$(cat <<-END

Usage: $0 --uri IDENTITY-API-URI --zone ZONE [--admin-group GROUP]+ [-k]?
The IDENTITY-API-URI and ZONE fields are required.

This tool maps all HCF admin scopes to LDAP groups.
Example:
$0 --uri https://identity.hcp.example.com --zone hcf \\
    --admin-group cn=admins,ou=scopes,dc=test,dc=com \\
    --admin-group cn=uaa.admin,ou=scopes,dc=test,dc=com
 
END
)

help() {
  echo "$USAGE"
  exit 1
}

check_arg() {
    ARG_NAME=$1
    ARG_VALUE="${2:-}"
    if [ -z "${ARG_VALUE}" ] ; then
	echo "Missing value for ${ARG_NAME} option"
	exit 1
    fi
}

HCF_ADMIN_SCOPES=(
  clients.write 
  cloud_controller.admin 
  doppler.firehose  
  openid 
  routing.router_groups.read 
  scim.read 
  scim.write)

IDBASE=
ZONE=
ADMIN_GROUPS=()
SKIP_SSL=
admin_index=0
user_index=0
while [ $# -gt 0 ] ; do
   case "$1" in
       -k) SKIP_SSL=-k ; shift ;;
       --zone) check_arg "$1" "$2"; ZONE="$2"; shift; shift ;;
       --uri) check_arg "$1" "$2"; IDBASE="$2"; shift; shift ;;
       --admin-group)
	   check_arg "$1" "$2"
	   ADMIN_GROUPS[$admin_index]="$2"
	   admin_index=$((admin_index+1))
	   shift; shift ;;
       -h) help ;;
       -*) echo "Unrecognized option $1" ; help; exit 1 ;;
       *) echo "Unrecognized argument $1" ; help; exit 1 ;;
   esac
done
if [ -z "${ZONE:-}" ] ; then
  echo "No zone was specified"
  echo "$USAGE"
  exit 1
fi
if [ ${#ADMIN_GROUPS} -eq 0 ] ; then
  echo "No admin LDAP groups were specified with the --admin-group option"
  echo "$USAGE"
  exit 1
fi

ROOT=$(cd $(dirname $0) && echo $PWD)
. $ROOT/common.sh
check_jq
TOKEN=$(< $HOME/.hcp jq --raw-output .AccessToken)
check_token $IDBASE $TOKEN ${SKIP_SSL}

for GROUP in "${ADMIN_GROUPS[@]}" ; do
  for SCOPE in "${HCF_ADMIN_SCOPES[@]}"; do
    hcp map-ldap-group --zone "${ZONE}" "${SCOPE}" "${GROUP}"
  done
done

