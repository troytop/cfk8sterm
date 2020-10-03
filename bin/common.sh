check_token() {
   IDBASE=$1
   TOKEN=$2
   SKIP_SSL="${3:-}"
   result=$(curl -S -s ${SKIP_SSL} -H 'Accept: application/json' -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" $IDBASE/identity-providers?rawConfig=true)
   if [ "$(echo $result | jq -r type)" == "array" ] ; then
       return
   fi
   if echo $result | jq .error 2>&1 >/dev/null ; then
       echo $result | jq -r '.error'
       echo "Token has expired.  Please rerun hcp login -u admin... and retry"
   else
       echo "Unknown error connecting to $IDBASE"
   fi
   exit 2
}

check_jq() {
  if ! which jq &> /dev/null ; then
      echo "Please install jq command-line JSON processor."
      echo "For Debian or Ubuntu run 'sudo apt-get install jq' and rerun this script"
      exit 1
  fi
}
