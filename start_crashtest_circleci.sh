#!/usr/bin/env bash

#### Setup variables ####

# Stop the script as soon as the first command fails
set -euo pipefail

# Set WEBHOOK to webhook secret (without URL)
WEBHOOK=$1

# Set the API endpoint
API_ENDPOINT="https://api.crashtest.cloud/webhook"

#### Setup the alpine system ####

apk add curl jq
mkdir -p ~/crashtest


#### Start Security Scan ####

# Start Scan and get scan ID
SCAN_ID=`curl --silent -X POST --data "" $API_ENDPOINT/$WEBHOOK | jq .data.scanId`

# Check if a positive integer was returned as SCAN_ID
if ! [ $SCAN_ID -ge 0 ] 2>/dev/null
then
    echo "Could not start Scan for Webhook $WEBHOOK."
    exit 1
fi

echo "Started Scan for Webhook $WEBHOOK. Scan ID is $SCAN_ID."


#### Check Security Scan Status ####

# Set status to Queued (100)
STATUS=100

# Run the scan until the status is not queued (100) or running (101) anymore
while [ $STATUS -le 101 ]
do
   echo "Scan Status currently is $STATUS (101 = Running)"

   # Only poll every minute
   sleep 60

   # Refresh status
   STATUS=`curl --silent $API_ENDPOINT/$WEBHOOK/scans/$SCAN_ID/status | jq .data.status.status_code`

done

echo "Scan finished with status $STATUS."


#### Download Scan Report ####

curl --silent $API_ENDPOINT/$WEBHOOK/scans/$SCAN_ID/report/junit -o ~/crashtest/report.xml
echo "Downloaded Report to crashtest/report.xml"
