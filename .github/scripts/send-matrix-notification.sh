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
    
    # Create a clean, well-formatted message with proper spacing
    local clean_message=$(echo "$message" | sed -E "s/^'*//;s/'*$//" | sed 's/^[[:space:]]*//')
    
    # Convert to HTML with proper spacing
    local formatted_message="<div style='font-family: monospace; white-space: pre;'>"
    formatted_message+="<h3>🔔 Test Notification</h3>"
    
    # Split into lines and format each line
    IFS=$'\n' read -r -d '' -a lines <<< "$clean_message" || true
    for line in "${lines[@]:1}"; do  # Skip the first line (title)
        line=$(echo "$line" | sed -E "s/^'*//;s/'*$//")
        if [ -z "$line" ]; then
            formatted_message+="<br>"
        else
            formatted_message+="<div>${line}</div>"
        fi
    done
    
    formatted_message+="</div>"
    
    # Create JSON payload with proper escaping
    local json_payload
    json_payload=$(jq -n \
        --arg msg "$clean_message" \
        --arg fmt_msg "$formatted_message" \
        '{
          "msgtype": "m.text",
          "body": $msg,
          "format": "org.matrix.custom.html",
          "formatted_body": $fmt_msg
        }')
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create JSON payload" >&2
        return 3  # Matches documented exit code
    fi
    
    # Send message to Matrix
    local response
    # Generate a random number between 100000 and 999999 without using shuf
    local rand_num=$(( RANDOM % 900000 + 100000 ))
    local txn_id="$(date +%s)${rand_num}"
    # Use the homeserver from environment variable or default
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
        return 4  # Matches documented exit code
    fi
}

# Function to display help
show_help() {
    cat <<EOF
Matrix Notification Script

Send beautifully formatted notifications to a Matrix room with proper line breaks and formatting.

Usage: $0 [OPTIONS] [ROOM_ID ACCESS_TOKEN MESSAGE]

Options:
  -h, --help          Show this help message and exit
  -s, --server URL     Specify Matrix homeserver URL (default: https://matrix.org)

  -v, --version       Show version information

Arguments:
  ROOM_ID       The Matrix room ID (e.g., !roomId:matrix.org)
  ACCESS_TOKEN  The Matrix access token for authentication
  MESSAGE       The message to send (use \n for newlines)

Environment Variables:
  MATRIX_ROOM_ID       The Matrix room ID
  MATRIX_ACCESS_TOKEN  The Matrix access token
  MATRIX_MESSAGE       The message to send
  MATRIX_HOMESERVER    The Matrix homeserver URL (default: https://matrix.org)

Message Formatting:
  - Use \n for new lines
  - Blank lines are preserved
  - Supports markdown formatting
  - Special characters are automatically escaped

Examples:
  # Basic usage with command line arguments
  $0 "!room:example.com" "token" "Hello, Matrix!"

  # Custom homeserver
  $0 -s "https://matrix.example.org" "!room:example.com" "token" "Hello from custom server"

  # Using environment variables
  export MATRIX_ROOM_ID="!room:example.com"
  export MATRIX_ACCESS_TOKEN="token"
  export MATRIX_MESSAGE=$'🔔 **Test Notification**\n\nThis is a test\nWith multiple lines'
  $0

  # Multi-line message with special characters
  $0 "!room:example.com" "token" $'🔔 **Alert**\n\nLine 1\nLine 2\n\nFinal line!'

Exit Codes:
  0 - Success
  1 - Missing required arguments
  2 - Invalid arguments
  3 - Failed to create JSON payload
  4 - Failed to send notification

For more information, see the workflow documentation in .github/workflows/README.md
EOF
}

# Parse command line arguments
homeserver="${MATRIX_HOMESERVER:-https://matrix.org}"
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--server)
            homeserver="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

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
