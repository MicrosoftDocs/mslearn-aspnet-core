#!/bin/bash

# Public IP address of your ingress controller
IP=$1

# Name to associate with public IP address
DNSNAME=$2

# Get the resource-id of the public ip
while [ "$PUBLICIPID" == "" ]
do
    PUBLICIPID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" --output tsv)

    if [ "$PUBLICIPID" == "" ]
    then
        echo "Waiting for the IP Address resource ID - Ctrl+C to cancel..."
        sleep 5
    else
        echo "Found ID:$PUBLICIPID"
    fi
done

# Update public ip address with DNS name
az network public-ip update --ids $PUBLICIPID --dns-name $DNSNAME -o none

# Display the FQDN
az network public-ip show --ids $PUBLICIPID --query "{FQDN:dnsSettings.fqdn, IPAddress:ipAddress}" --output table
