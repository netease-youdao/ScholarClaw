#!/bin/bash
# ScholarClaw - Scholar Search Script
# Intelligent academic search with query analysis, citation expansion, and reranking

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

Intelligent academic search with query analysis, citation expansion, and reranking.
This uses AI to analyze your query, generate optimized search terms, and rerank results.

Options:
    -q, --query TEXT          Search query (required)
    -c, --context JSON        Conversation context as JSON array
    -m, --max-results NUMBER  Maximum results to return (default: 20)
    -e, --engine ENGINE       Search engine: arxiv, pubmed, etc. (auto-selected if not specified)
    --no-citation-expansion   Disable citation expansion
    --no-rerank               Disable reranking
    --analyze-only            Only analyze query, don't search
    -h, --help                Show this help message

Examples:
    $(basename "$0") -q "What are the latest advances in multimodal learning?"
    $(basename "$0") -q "transformer efficiency" -e arxiv -m 30
    $(basename "$0") -q "What about computational cost?" -c '[{"role":"user","content":"Tell me about vision transformers"}]'
    $(basename "$0") -q "machine learning" --analyze-only

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: https://scholarclaw.youdao.com)
EOF
}

# Default values
QUERY=""
CONTEXT=""
MAX_RESULTS=20
ENGINE=""
CITATION_EXPANSION=true
RERANK=true
ANALYZE_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--query)
            QUERY="$2"
            shift 2
            ;;
        -c|--context)
            CONTEXT="$2"
            shift 2
            ;;
        -m|-l|--max-results|--limit)
            MAX_RESULTS="$2"
            shift 2
            ;;
        -e|--engine)
            ENGINE="$2"
            shift 2
            ;;
        --no-citation-expansion)
            CITATION_EXPANSION=false
            shift
            ;;
        --no-rerank)
            RERANK=false
            shift
            ;;
        --analyze-only)
            ANALYZE_ONLY=true
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

# Build JSON payload
if [[ "$ANALYZE_ONLY" == "true" ]]; then
    ENDPOINT="/scholar/analyze"
    PAYLOAD=$(cat << EOF
{
    "query": $(echo "$QUERY" | jq -Rs .),
    "messages": $(if [[ -n "$CONTEXT" ]]; then echo "$CONTEXT"; else echo "null"; fi)
}
EOF
)
else
    ENDPOINT="/scholar/search"
    PAYLOAD=$(cat << EOF
{
    "query": $(echo "$QUERY" | jq -Rs .),
    "messages": $(if [[ -n "$CONTEXT" ]]; then echo "$CONTEXT"; else echo "null"; fi),
    "max_results": $MAX_RESULTS,
    "search_engine": $(if [[ -n "$ENGINE" ]]; then echo "\"$ENGINE\""; else echo "null"; fi),
    "enable_citation_expansion": $CITATION_EXPANSION,
    "enable_rerank": $RERANK
}
EOF
)
fi

# Execute search
echo "Scholar Search: $QUERY" >&2
if [[ "$ANALYZE_ONLY" == "true" ]]; then
    echo "Mode: Analyze only" >&2
else
    echo "Max results: $MAX_RESULTS" >&2
fi

# Build auth header if API key is set
AUTH_HEADER=()
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    AUTH_HEADER=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

RESPONSE=$(curl -s --max-time 60 -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    "${AUTH_HEADER[@]}" \
    -d "$PAYLOAD" \
    "${SERVER_URL}${ENDPOINT}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Scholar search"
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
