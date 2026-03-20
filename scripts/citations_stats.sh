#!/bin/bash
# ScholarClaw - Citation Statistics Script
# Get citation statistics for an ArXiv paper

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

Get citation statistics for an ArXiv paper.

Options:
    -i, --arxiv-id ID         ArXiv paper ID (required)
    -h, --help                Show this help message

Examples:
    $(basename "$0") -i 2303.14535
    $(basename "$0") --arxiv-id 1706.03762

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: http://localhost:8090)
EOF
}

# Default values
ARXIV_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--arxiv-id)
            ARXIV_ID="$2"
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
if [[ -z "$ARXIV_ID" ]]; then
    echo "Error: ArXiv ID is required. Use -i or --arxiv-id to specify."
    show_help
    exit 1
fi

# Build URL
URL="${SERVER_URL}/citations/stats?arxiv_id=${ARXIV_ID}"

# Execute request
echo "Fetching citation statistics for: $ARXIV_ID" >&2

# Build auth header if API key is set
AUTH_HEADER=()
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    AUTH_HEADER=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

RESPONSE=$(curl -s -w "\n%{http_code}" "${AUTH_HEADER[@]}" "$URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Fetch citation statistics"
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
