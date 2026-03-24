#!/bin/bash
# ScholarClaw - Blog Status Script
# Get blog task status

set -e

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Initialize configuration
init_config

# Configuration
SERVER_URL=$(get_server_url)

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Get blog task status or list all tasks.

Options:
    -i, --task-id ID          Task ID to check
    -s, --status STATUS       Filter by status: pending, running, completed, failed
    -l, --limit NUMBER        Max tasks to return (default: 100)
    -o, --offset NUMBER       Offset for pagination (default: 0)
    -h, --help                Show this help message

Examples:
    $(basename "$0")                              # List all tasks
    $(basename "$0") -i blog_abc123def456        # Get specific task status
    $(basename "$0") -s completed -l 20          # List completed tasks

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: https://scholarclaw.youdao.com)
EOF
}

# Default values
TASK_ID=""
STATUS=""
LIMIT=100
OFFSET=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--task-id)
            TASK_ID="$2"
            shift 2
            ;;
        -s|--status)
            STATUS="$2"
            shift 2
            ;;
        -l|--limit)
            LIMIT="$2"
            shift 2
            ;;
        -o|--offset)
            OFFSET="$2"
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

# Execute request
if [[ -n "$TASK_ID" ]]; then
    URL="${SERVER_URL}/api/blog/task/${TASK_ID}"
    echo "Checking task status: $TASK_ID" >&2
else
    URL="${SERVER_URL}/api/blog/tasks?limit=${LIMIT}&offset=${OFFSET}"
    if [[ -n "$STATUS" ]]; then
        URL="${URL}&status=${STATUS}"
    fi
    echo "Listing blog tasks..." >&2
fi

# Build auth header if API key is set
AUTH_HEADER=()
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    AUTH_HEADER=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

RESPONSE=$(curl -s --max-time 30 -w "\n%{http_code}" "${AUTH_HEADER[@]}" "$URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Check blog status"
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
