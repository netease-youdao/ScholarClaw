#!/bin/bash
# ScholarClaw - OpenAlex Find and Cited By Script
# Find paper by title and get citations

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

Find paper by title (and optionally author), then get papers citing it.

Options:
    -t, --title TEXT          Paper title (required)
    -a, --author TEXT         Author name for better matching (optional)
    -l, --limit NUMBER        Max citing papers to return (default: 20, max: 100)
    -o, --offset NUMBER       Offset for pagination (default: 0)
    -s, --sort-by SORT        Sort by: citation_count, date (default: citation_count)
    -f, --fetch-works         Fetch citing works list (default: false, only returns count)
    -h, --help                Show this help message

Examples:
    $(basename "$0") -t "Attention Is All You Need"
    $(basename "$0") -t "BERT" -a "Devlin"
    $(basename "$0") -t "GPT-4 Technical Report" --fetch-works -l 50

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: http://localhost:8090)
EOF
}

# Default values
TITLE=""
AUTHOR=""
LIMIT=20
OFFSET=0
SORT_BY="citation_count"
FETCH_WORKS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--title)
            TITLE="$2"
            shift 2
            ;;
        -a|--author)
            AUTHOR="$2"
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
        -f|--fetch-works)
            FETCH_WORKS=true
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
if [[ -z "$TITLE" ]]; then
    echo "Error: Title is required. Use -t or --title to specify."
    show_help
    exit 1
fi

# URL encode parameters
ENCODED_TITLE=$(printf '%s' "$TITLE" | jq -sRr @uri)
ENCODED_AUTHOR=$(printf '%s' "$AUTHOR" | jq -sRr @uri)

# Build URL
URL="${SERVER_URL}/openalex/find_and_cited_by?title=${ENCODED_TITLE}&author_name=${ENCODED_AUTHOR}&limit=${LIMIT}&offset=${OFFSET}&sort_by=${SORT_BY}&fetch_citing_works=${FETCH_WORKS}"

# Execute request
echo "Finding paper: $TITLE" >&2
if [[ -n "$AUTHOR" ]]; then
    echo "Author: $AUTHOR" >&2
fi

# Build auth header if API key is set
AUTH_HEADER=()
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    AUTH_HEADER=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

RESPONSE=$(curl -s -w "\n%{http_code}" "${AUTH_HEADER[@]}" "$URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Find paper"
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
