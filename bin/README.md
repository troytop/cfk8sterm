## HCP

Please refer to [HCP UAA docs](../../docs/uaa.md#uaaldap-integration) on how to integrate LDAP with HCP.

LDAP groups can be mapped to hcp scopes with the [HCP command line tool](../../cmd/hcp/subcmd/map_ldap_group.go).

Example 1. Assign the hcp.admin scope to a LDAP group: 

    hcp map-ldap-group hcp.admin cn=admins,ou=scopes,dc=test,dc=com

Example 2. Assign the hcp.publishers scope to a LDAP group: 

    hcp map-ldap-group hcp.publisher cn=publishers,ou=scopes,dc=test,dc=com

LDAP identity provider can also be enabled after HCP was deployed using the UAA API directly.
Example with `uaac` and `jq`:

```
uaac target https://identity.gamma1018.mitza.stacktest.io:443 --skip-ssl-validation
uaac token owner get  hcp -s ""  admin -p HCP_ADMIN_PASSWORD"
export LDAP_PROVIDER_ID=$(uaac curl -k /identity-providers?rawConfig=true | sed '1,/^RESPONSE BODY:$/d' | jq -r '.[] | select(.originKey == "ldap") | .id')

# Inspect the current LDAP config
uaac curl -k /identity-providers?rawConfig=true

# Make sure to change at least the "baseUrl", "bindUserDn", "bindPassword", "userSearchBase", and "groupSearchBase" keys

uaac curl -k -X PUT \
 -H 'Content-Type: application/json' \
 /identity-providers/$LDAP_PROVIDER_ID \
 -d '{
  "type" : "ldap",
  "config" : {
    "ldapProfileFile" : "ldap/ldap-search-and-bind.xml",
    "baseUrl" : "ldaps://13.81.204.95:636",
    "skipSSLVerification" : true,
    "bindUserDn" : "ldapbind@helionchau.onmicrosoft.com",
    "bindPassword" : "BIND_PASSWORD",
    "userSearchBase" : "DC=helionchau,DC=onmicrosoft,DC=com",
    "userSearchFilter" : "sAMAccountName={0}",
    "mailSubstitute" : "{0}@helionchau.onmicrosoft.com",
    "ldapGroupFile" : "ldap/ldap-groups-map-to-scopes.xml",
    "groupSearchBase" : "DC=helionchau,DC=onmicrosoft,DC=com",
    "groupSearchFilter" : "member={0}"
  },
  "originKey" : "ldap",
  "name" : "LDAP on Azure Active Directory Domain Services",
  "active" : true
}'

# Test LDAP login. In this example ACCOUNT_NAME is using the search filter "sAMAccountName={0}" which is the NT Account name.
uaac token owner get  hcp -s ""  ACCOUNT_NAME -p "ACCOUNT_PASSWORD"

# Check the token permissions/scopes with
uaac context

```

Currently, the bootstrap config does not expose skipSSLVerification for LDAPS (LDAP with TLS). skipSSLVerification can 
be set after the bootstrap is finished with the patch-id-provider.sh script. Example:

    ./patch-id-provider.sh https://identity.mitza.stacktest.io  hcf config.skipSSLVerification true -k


## HCF

Instructions for finishing UAA/LDAP integration for Stackato 4.0 post HCF instance-creation.

    IDBASE: the full url of the HCP identity endpoint (e.g. https://identity.hcp.example.com)
    ZONE: the name of the zone you want to copy the LDAP provider config to (e.g. hcf)". This is the value provided for the `instance-name` prompt in the `hsm create-instance stackato.hpe.hcf` step.

1. Copy the LDAP identity provider from the HCP default UAA zone to the HCF's UAA zone:

    bash copy-id-provider-to-zone.sh $IDBASE $ZONE

2. Run `map-zones.sh` to map LDAP group names to scopes used by the Cloud Foundry API to determine admin permissions.
   By default all LDAP users will have access to Cloud Foundry API as a [basic user](https://github.com/hpcloud/hdp-resource-manager/blob/master/containers/uaa/dev-postgresql.yml#L89).  For example:

        bash map-zones.sh --uri $IDBASE --zone $ZONE  \
            --admin-group cn=admins,ou=scopes,dc=test,dc=com \
            --admin-group cn=uaa.admin,ou=scopes,dc=test,dc=com

Note that this command uses named arguments instead of positional
arguments due to the extra syntax.

This command can be run multiple times to add more
ldap-group/uaa-scope maps. Duplicates are ignored. To remove a group
run `hcp unmap-ldap-group UAA-SCOPE-NAME LDAP-DN` for each UAA scope.
