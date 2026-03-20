#!/bin/bash
# ScholarClaw - SOTA Chat Script
# Send a message to SOTA Chat API

set -e

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Initialize configuration
init_config

# Configuration
SERVER_URL=$(get_server_url)
DEFAULT_TIMEOUT=120

# Build auth header
AUTH_HEADER=($(get_auth_header))

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Send a message to SOTA Chat API for benchmark/SOTA queries.

Options:
    -m, --message TEXT        Message/question to send (required)
    -H, --history JSON        Conversation history as JSON array (optional)
    -s, --stream              Enable streaming mode (SSE)
    -t, --timeout SECONDS     Request timeout (default: ${DEFAULT_TIMEOUT}s)
    -o, --output PATH         Save result to file
    -h, --help                Show this help message

Examples:
    # Simple chat
    $(basename "$0") -m "What is the SOTA for MMLU benchmark?"

    # With conversation history
    $(basename "$0") -m "What about GPQA?" -H '[{"role":"user","content":"Tell me about MMLU"}]'

    # Streaming mode
    $(basename "$0") -m "List recent SOTA results for reasoning benchmarks" -s

    # Save to file
    $(basename "$0") -m "Compare GPT-4 and Claude on various benchmarks" -o result.json

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: http://localhost:8090)
EOF
}

# Default values
MESSAGE=""
HISTORY="[]"
STREAM=false
TIMEOUT=$DEFAULT_TIMEOUT
OUTPUT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--message)
            MESSAGE="$2"
            shift 2
            ;;
        -H|--history)
            HISTORY="$2"
            shift 2
            ;;
        -s|--stream)
            STREAM=true
            shift
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$MESSAGE" ]]; then
    echo "Error: Message is required. Use -m or --message to specify."
    show_help
    exit 1
fi

# Build JSON payload
PAYLOAD=$(cat << EOF
{
    "message": $(echo "$MESSAGE" | jq -Rs .),
    "history": $HISTORY
}
EOF
)

# Execute request
if [[ "$STREAM" == "true" ]]; then
    # Streaming mode
    URL="${SERVER_URL}/api/benchmark/chat/stream"
    echo "Sending streaming request to SOTA Chat..." >&2

    if [[ -n "$OUTPUT" ]]; then
        curl -s -N -X POST \
            -H "Content-Type: application/json" \
            -H "Accept: text/event-stream" \
            "${AUTH_HEADER[@]}" \
            -d "$PAYLOAD" \
            --max-time "$TIMEOUT" \
            "$URL" > "$OUTPUT"
        echo "Saved to: $OUTPUT" >&2
    else
        curl -s -N -X POST \
            -H "Content-Type: application/json" \
            -H "Accept: text/event-stream" \
            "${AUTH_HEADER[@]}" \
            -d "$PAYLOAD" \
            --max-time "$TIMEOUT" \
            "$URL"
    fi
else
    # Non-streaming mode
    URL="${SERVER_URL}/api/benchmark/chat"
    echo "Sending request to SOTA Chat..." >&2

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        "${AUTH_HEADER[@]}" \
        -d "$PAYLOAD" \
        --max-time "$TIMEOUT" \
        "$URL")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [[ "$HTTP_CODE" -ne 200 ]]; then
        handle_http_error "$HTTP_CODE" "$BODY" "SOTA Chat"
        exit 1
    fi

    # Output result
    if [[ -n "$OUTPUT" ]]; then
        echo "$BODY" > "$OUTPUT"
        echo "Saved to: $OUTPUT" >&2
    else
        if command -v jq &> /dev/null; then
            echo "$BODY" | jq .
        else
            echo "$BODY"
        fi
    fi
fi
