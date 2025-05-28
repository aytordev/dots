#!/bin/bash

# Function to send a message to Matrix
send_matrix_message() {
    local room_id="$1"
    local access_token="$2"
    local message="$3"
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed." >&2
        return 1
    fi
    
    # Create JSON payload with proper escaping
    local json_payload
    json_payload=$(jq -n \
        --arg msg "$message" \
        --arg fmt_msg "${message//$'\n'/<br>}" \
        '{
          "msgtype": "m.text",
          "body": $msg,
          "format": "org.matrix.custom.html",
          "formatted_body": $fmt_msg
        }')
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create JSON payload" >&2
        return 1
    fi
    
    # Send message to Matrix
    local response
    # Generate a random number between 100000 and 999999 without using shuf
    local rand_num=$(( RANDOM % 900000 + 100000 ))
    local txn_id="$(date +%s)${rand_num}"
    local homeserver="https://matrix.org"
    local api_url="${homeserver}/_matrix/client/v3/rooms/${room_id}/send/m.room.message/${txn_id}"
    
    response=$(curl -s -w "\n%{http_code}" -X PUT \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$api_url" 2>&1)
    
    local status_code=${response##*$'\n'}
    local response_body=${response%$status_code}
    
    if [ $status_code -ge 200 ] && [ $status_code -lt 300 ]; then
        echo "Notification sent successfully"
        return 0
    else
        echo "Error: Failed to send notification" >&2
        echo "Status code: $status_code" >&2
        echo "Response: $response_body" >&2
        return 1
    fi
}

# Main execution
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
fi

# Try to get values from environment variables if not provided as arguments
if [ $# -eq 0 ]; then
    # Use environment variables if no arguments provided
    if [ -z "${MATRIX_ROOM_ID:-}" ] || [ -z "${MATRIX_ACCESS_TOKEN:-}" ] || [ -z "${MATRIX_MESSAGE:-}" ]; then
        echo "Error: Missing required arguments or environment variables" >&2
        show_help
        exit 2
    fi
    ROOM_ID="$MATRIX_ROOM_ID"
    ACCESS_TOKEN="$MATRIX_ACCESS_TOKEN"
    MESSAGE="$MATRIX_MESSAGE"
else
    # Use command line arguments
    if [ $# -lt 3 ]; then
        echo "Error: Missing required arguments" >&2
        show_help
        exit 2
    fi
    ROOM_ID="$1"
    ACCESS_TOKEN="$2"
    shift 2
    MESSAGE="$*"
fi

send_matrix_message "$ROOM_ID" "$ACCESS_TOKEN" "$MESSAGE"
