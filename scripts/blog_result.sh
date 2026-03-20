#!/bin/bash
# ScholarClaw - Blog Result Script
# Get blog generation result

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

Get blog generation result.

Options:
    -i, --task-id ID          Task ID (required)
    -o, --output PATH         Save blog content to file
    --content-only            Output only the blog content (no metadata)
    -h, --help                Show this help message

Examples:
    $(basename "$0") -i blog_abc123def456
    $(basename "$0") -i blog_abc123def456 -o blog.md
    $(basename "$0") -i blog_abc123def456 --content-only

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: http://localhost:8090)
EOF
}

# Default values
TASK_ID=""
OUTPUT=""
CONTENT_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--task-id)
            TASK_ID="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        --content-only)
            CONTENT_ONLY=true
            shift
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
if [[ -z "$TASK_ID" ]]; then
    echo "Error: Task ID is required. Use -i or --task-id to specify."
    show_help
    exit 1
fi

# Build URL
URL="${SERVER_URL}/api/blog/result/${TASK_ID}"

# Execute request
echo "Fetching blog result: $TASK_ID" >&2

# Build auth header if API key is set
AUTH_HEADER=()
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    AUTH_HEADER=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

RESPONSE=$(curl -s -w "\n%{http_code}" "${AUTH_HEADER[@]}" "$URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Get blog result"
    exit 1
fi

# Output result
if [[ "$CONTENT_ONLY" == "true" ]]; then
    CONTENT=$(echo "$BODY" | jq -r '.blog_content // .markdown_content // .')
    if [[ -n "$OUTPUT" ]]; then
        echo "$CONTENT" > "$OUTPUT"
        echo "Saved to: $OUTPUT" >&2
    else
        echo "$CONTENT"
    fi
elif [[ -n "$OUTPUT" ]]; then
    BLOG_CONTENT=$(echo "$BODY" | jq -r '.blog_content // .markdown_content // ""')
    echo "$BLOG_CONTENT" > "$OUTPUT"
    echo "Saved to: $OUTPUT" >&2
    echo "$BODY" | jq 'del(.blog_content) | del(.markdown_content)'
else
    if command -v jq &> /dev/null; then
        echo "$BODY" | jq .
    else
        echo "$BODY"
    fi
fi
