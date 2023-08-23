#!/bin/bash
while true; do
    utcTime=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    # if set to Event -- need to add data.baseData.name: "YourCustomEventName",
    # and set baseType to EventData
    otelTypeTrace="Microsoft.ApplicationInsights.Message"
    otelTypeEvent="Microsoft.ApplicationInsights.Event"
    sender=$(whoami)
    machine=$(hostname)
    roleInstance="curl-from-${sender}@${machine}"
    traceId="$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)"
    traceId2="$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)"

jsonPayloadTrace=$(cat <<EOF
{
"iKey": "${AI_INSTRUMENTATION_KEY}",
"name": "${otelTypeTrace}",
"time": "${utcTime}",
"sampleRate": 100.0,
"tags": {
    "ai.cloud.roleInstance": "${roleInstance}",
    "ai.operation.id": "${traceId}"
},
"data": {
    "baseType": "MessageData",
    "baseData": {
    "ver": 2,
    "message": "just sending a message for ${traceId} from ${sender}",
    "severityLevel": "Information",
    "properties": {
        "customProperty1": "simple",
        "customProperty2": "message"
    }
    }
}
}
EOF
)

jsonPayloadEvent=$(cat <<EOF
{
"iKey": "${AI_INSTRUMENTATION_KEY}",
"name": "${otelTypeEvent}",
"time": "${utcTime}",
"sampleRate": 100.0,
"tags": {
    "ai.cloud.roleInstance": "${roleInstance}",
    "ai.operation.id": "${traceId2}",
    "ai.operation.parentId": "${traceId}"
},
"data": {
    "baseType": "EventData",
    "baseData": {
    "ver": 2,
    "name": "A custom event from ${sender} with traceId ${traceId2}",
    "severityLevel": "Information",
    "properties": {
        "customProperty1": "simple",
        "customProperty2": "message"
    }
    }
}
}
EOF
)

    # InstrumentationKey=${AI_INSTRUMENTATION_KEY};IngestionEndpoint=https://westus3-1.in.applicationinsights.azure.com/

    echo "-----------------"
    echo "Sending to ${AI_ENDPOINT}"
    echo "-----------------"
    echo $jsonPayloadTrace
    echo "-----------------"
    echo $jsonPayloadEvent
    echo "-----------------"
    curl -i -X POST "${AI_ENDPOINT}" -H "Content-Type: application/json" -d "${jsonPayloadTrace}"
    curl -i -X POST "${AI_ENDPOINT}" -H "Content-Type: application/json" -d "${jsonPayloadEvent}"

    sleep 10
done
