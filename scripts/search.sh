#!/bin/bash
# ScholarClaw - Unified Search Script
# Search across multiple academic search engines

set -e

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Initialize configuration
init_config

# URL encode helper function (must be defined before use)
urlencode() {
    local string="$1"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="$c" ;;
            * ) printf -v o '%%%02X' "'$c" ;;
        esac
        encoded+="$o"
    done
    echo "$encoded"
}

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Unified search across multiple academic search engines.

Options:
    -q, --query TEXT          Search query (required)
    -e, --engine ENGINE       Search engine: arxiv, pubmed, google, kuake, bocha, cache, nips (default: bocha)
    -l, --limit NUMBER        Total results to fetch (default: 100)
    -p, --page NUMBER         Page number, 1-indexed (default: 1)
    -ps, --page-size NUMBER   Results per page (default: 10)
    -f, --freshness TEXT      Time filter: day, week, month
    -m, --mode MODE           Search mode: simple, ai (default: simple)
    -s, --sort-by SORT        Sort by: relevance, date (default: relevance)
    --with-citations          Include citation details (default: true)
    --return-all              Return all results without pagination
    -h, --help                Show this help message

Examples:
    $(basename "$0") -q "transformer attention" -e arxiv -l 20
    $(basename "$0") -q "COVID-19 vaccine" -e pubmed --mode ai
    $(basename "$0") -q "LLM reasoning" -e google --freshness week

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: http://localhost:8090)
    SCHOLARCLAW_API_KEY         API Key for authentication (optional)
EOF
}

# Default values
QUERY=""
ENGINE="bocha"
LIMIT=100
PAGE=1
PAGE_SIZE=10
FRESHNESS=""
MODE="simple"
SORT_BY="relevance"
WITH_CITATIONS="true"
RETURN_ALL="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--query)
            QUERY="$2"
            shift 2
            ;;
        -e|--engine)
            ENGINE="$2"
            shift 2
            ;;
        -l|--limit)
            LIMIT="$2"
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
        -f|--freshness)
            FRESHNESS="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -s|--sort-by)
            SORT_BY="$2"
            shift 2
            ;;
        --with-citations)
            WITH_CITATIONS="true"
            shift
            ;;
        --return-all)
            RETURN_ALL="true"
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
if [[ -z "$QUERY" ]]; then
    echo "Error: Query is required. Use -q or --query to specify."
    show_help
    exit 1
fi

# Get server URL
SERVER_URL=$(get_server_url)

# Build URL with encoded query
ENCODED_QUERY=$(urlencode "$QUERY")
URL="${SERVER_URL}/search?q=${ENCODED_QUERY}&engine=${ENGINE}&limit=${LIMIT}&page=${PAGE}&page_size=${PAGE_SIZE}&mode=${MODE}&sort_by=${SORT_BY}&with_citations=${WITH_CITATIONS}&return_all=${RETURN_ALL}"

if [[ -n "$FRESHNESS" ]]; then
    URL="${URL}&freshness=${FRESHNESS}"
fi

# Execute search
echo "Searching: $QUERY" >&2
echo "Engine: $ENGINE" >&2

# Build curl arguments with auth header
AUTH_HEADER=($(get_auth_header))

RESPONSE=$(curl -s -w "\n%{http_code}" "${AUTH_HEADER[@]}" "$URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Search"
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
