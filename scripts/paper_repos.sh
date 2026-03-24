#!/bin/bash
# ScholarClaw - Paper Repos Script
# Get GitHub repositories for a paper

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

Get GitHub repositories associated with an ArXiv paper.

Options:
    -i, --arxiv-id ID         ArXiv paper ID (required)
    --min-stars NUMBER        Minimum stars filter (default: 5)
    -h, --help                Show this help message

Examples:
    $(basename "$0") -i 2303.14535
    $(basename "$0") -i 2303.14535 --min-stars 100

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: https://scholarclaw.youdao.com)
EOF
}

# Default values
ARXIV_ID=""
MIN_STARS=5

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--arxiv-id)
            ARXIV_ID="$2"
            shift 2
            ;;
        --min-stars)
            MIN_STARS="$2"
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
URL="${SERVER_URL}/api/recommend/paper/${ARXIV_ID}/detail?min_stars=${MIN_STARS}"

# Execute request
echo "Fetching GitHub repos for: $ARXIV_ID" >&2

# Build auth header if API key is set
AUTH_HEADER=()
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    AUTH_HEADER=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

RESPONSE=$(curl -s --max-time 30 -w "\n%{http_code}" "${AUTH_HEADER[@]}" "$URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Fetch repos"
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
