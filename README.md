# LUADNSUPD

Luadnsups is a small dyndns-like utility to update a luadns A record regularly so it points to the public ip address of the host running this container.

To work, the container needs to have 4 env variables set
- LUADNS_ZONE_ID: the id of the zone which contains the record
- LUADNS_RECORD_NAME: the name of the record to update
- LUADNS_USER: the account username
- LUADNS_TOKEN: the account api token

The refresh happens every 2 minutes.