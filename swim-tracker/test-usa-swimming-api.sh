#!/bin/bash

# Test USA Swimming Person API endpoint
# This fetches filtered swim times for a person

# URL with parameters
PERSON_ID="DsNG2.9yq6s%3D"
ORGANIZATION_ID="1"
EVENT_ID="0"
SESSION_ID="0"
REPORT_PERIOD_ID="0"

URL="https://personapi.usaswimming.org/swims/Person/swimTime/filtered?id=${PERSON_ID}&organizationId=${ORGANIZATION_ID}&eventId=${EVENT_ID}&sessionId=${SESSION_ID}&reportPeriodId=${REPORT_PERIOD_ID}"

echo "Testing USA Swimming API..."
echo "═══════════════════════════════════════════════════════════"
echo "URL: $URL"
echo ""
echo "Parameters:"
echo "  - Person ID: ${PERSON_ID}"
echo "  - Organization ID: ${ORGANIZATION_ID}"
echo "  - Event ID: ${EVENT_ID}"
echo "  - Session ID: ${SESSION_ID}"
echo "  - Report Period ID: ${REPORT_PERIOD_ID}"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Basic curl call (GET is default, so -X GET is optional)
echo "Making request..."
curl "$URL" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "User-Agent: SwimTrack-Pro/1.0" \
  --compressed \
  --location \
  --max-time 30 \
  -w "\n\nHTTP Status: %{http_code}\nTime: %{time_total}s\n" \
  -v 2>&1 | tee /tmp/usa-swimming-response.txt

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Response saved to: /tmp/usa-swimming-response.txt"
echo "Test complete"
