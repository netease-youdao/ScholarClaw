#!/bin/bash
# ScholarClaw - OpenAlex Cited By Script
# Query papers citing an OpenAlex work

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

Query papers citing an OpenAlex work by its ID.

Options:
    -w, --work-id ID          OpenAlex work ID or DOI (required)
    -l, --limit NUMBER        Max results (default: 20, max: 100)
    -o, --offset NUMBER       Offset for pagination (default: 0)
    -s, --sort-by SORT        Sort by: citation_count, date (default: citation_count)
    -h, --help                Show this help message

Examples:
    $(basename "$0") -w W2741809807
    $(basename "$0") --work-id "10.48550/arXiv.1706.03762"
    $(basename "$0") -w W2741809807 -l 50 --sort-by date

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: https://scholarclaw.youdao.com)
EOF
}

# Default values
WORK_ID=""
LIMIT=20
OFFSET=0
SORT_BY="citation_count"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--work-id)
            WORK_ID="$2"
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
        -s|--sort-by)
            SORT_BY="$2"
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
if [[ -z "$WORK_ID" ]]; then
    echo "Error: Work ID is required. Use -w or --work-id to specify."
    show_help
    exit 1
fi

# URL encode the work ID
ENCODED_WORK_ID=$(printf '%s' "$WORK_ID" | jq -sRr @uri)

# Build URL
URL="${SERVER_URL}/openalex/cited_by?work_id=${ENCODED_WORK_ID}&limit=${LIMIT}&offset=${OFFSET}&sort_by=${SORT_BY}"

# Execute request
echo "Fetching citations for OpenAlex work: $WORK_ID" >&2

# Build auth header if API key is set
AUTH_HEADER=()
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    AUTH_HEADER=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

RESPONSE=$(curl -s --max-time 30 -w "\n%{http_code}" "${AUTH_HEADER[@]}" "$URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Fetch OpenAlex citations"
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
