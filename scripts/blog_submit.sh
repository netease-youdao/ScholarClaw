#!/bin/bash
# ScholarClaw - Blog Submit Script
# Submit a blog generation task

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

Submit a blog generation task for ArXiv papers.

Options:
    -i, --arxiv-ids IDS       ArXiv IDs or URLs, comma-separated (required if no files)
    -f, --file PATH           Upload PDF file (can be specified multiple times)
    -v, --views TEXT          Optional user views/opinions to include
    -h, --help                Show this help message

Examples:
    $(basename "$0") -i 2303.14535
    $(basename "$0") -i "https://arxiv.org/abs/2303.14535,https://arxiv.org/abs/1706.03762"
    $(basename "$0") -f paper.pdf -v "Focus on the methodology section"
    $(basename "$0") -i 2303.14535 -f supplementary.pdf

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: https://scholarclaw.youdao.com)
EOF
}

# Default values
ARXIV_IDS=""
VIEWS=""
FILES=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--arxiv-ids)
            ARXIV_IDS="$2"
            shift 2
            ;;
        -f|--file)
            FILES+=("$2")
            shift 2
            ;;
        -v|--views)
            VIEWS="$2"
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
if [[ -z "$ARXIV_IDS" ]] && [[ ${#FILES[@]} -eq 0 ]]; then
    echo "Error: Either --arxiv-ids or --file must be specified."
    show_help
    exit 1
fi

# Build curl command
CURL_ARGS=(-s --max-time 60 -w "\n%{http_code}" -X POST)

# Add auth header if API key is set
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    CURL_ARGS+=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

# Add form data
if [[ -n "$ARXIV_IDS" ]]; then
    CURL_ARGS+=(-F "arxiv_ids=$ARXIV_IDS")
fi

for file in "${FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        exit 1
    fi
    CURL_ARGS+=(-F "files=@$file")
done

if [[ -n "$VIEWS" ]]; then
    CURL_ARGS+=(-F "views_content=$VIEWS")
fi

# Execute request
echo "Submitting blog generation task..." >&2
if [[ -n "$ARXIV_IDS" ]]; then
    echo "ArXiv IDs: $ARXIV_IDS" >&2
fi
if [[ ${#FILES[@]} -gt 0 ]]; then
    echo "Files: ${FILES[*]}" >&2
fi

RESPONSE=$(curl "${CURL_ARGS[@]}" "${SERVER_URL}/api/blog/submit")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Submit blog task"
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
