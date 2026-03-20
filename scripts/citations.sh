#!/bin/bash
# ScholarClaw - Citations Script
# List papers citing an ArXiv paper

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

List papers citing an ArXiv paper.

Options:
    -i, --arxiv-id ID         ArXiv paper ID (required)
    -p, --page NUMBER         Page number, 1-indexed (default: 1)
    -ps, --page-size NUMBER   Results per page (default: 20)
    -s, --sort-by SORT        Sort by: citation_count, date (default: citation_count)
    -h, --help                Show this help message

Examples:
    $(basename "$0") -i 2303.14535
    $(basename "$0") -i 2303.14535 --page 2 --page-size 50
    $(basename "$0") -i 2303.14535 --sort-by date

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: http://localhost:8090)
EOF
}

# Default values
ARXIV_ID=""
PAGE=1
PAGE_SIZE=20
SORT_BY="citation_count"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--arxiv-id)
            ARXIV_ID="$2"
            shift 2
            ;;
        -p|--page)
            PAGE="$2"
            shift 2
            ;;
        -ps|--page-size)
            PAGE_SIZE="$2"
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
if [[ -z "$ARXIV_ID" ]]; then
    echo "Error: ArXiv ID is required. Use -i or --arxiv-id to specify."
    show_help
    exit 1
fi

# Build URL
URL="${SERVER_URL}/citations?arxiv_id=${ARXIV_ID}&page=${PAGE}&page_size=${PAGE_SIZE}&sort_by=${SORT_BY}"

# Execute request
echo "Fetching citations for: $ARXIV_ID" >&2

# Build auth header if API key is set
AUTH_HEADER=()
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    AUTH_HEADER=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

RESPONSE=$(curl -s -w "\n%{http_code}" "${AUTH_HEADER[@]}" "$URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Fetch citations"
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
