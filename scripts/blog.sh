#!/bin/bash
# ScholarClaw - Blog Script (Synchronous)
# Submit and wait for blog generation task completion

set -e

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Initialize configuration
init_config

# Configuration
SERVER_URL=$(get_server_url)
DEFAULT_TIMEOUT=600
POLL_INTERVAL=5

# Build auth header
AUTH_HEADER=($(get_auth_header))

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Generate blog articles from ArXiv papers.
By default, waits for task completion and outputs the result.

Options:
    -i, --arxiv-ids IDS       ArXiv IDs or URLs, comma-separated (required if no files)
    -f, --file PATH           Upload PDF file (can be specified multiple times)
    -v, --views TEXT          Optional user views/opinions to include
    -t, --timeout SECONDS     Timeout for waiting (default: ${DEFAULT_TIMEOUT}s)
    --no-wait                 Submit only, don't wait for completion
    -o, --output PATH         Save blog content to file
    --content-only            Output only the blog content (no metadata)
    -h, --help                Show this help message

Examples:
    # Synchronous mode (waits for completion)
    $(basename "$0") -i 2303.14535
    $(basename "$0") -i 2303.14535 -t 900

    # Async mode (submit only)
    $(basename "$0") -i 2303.14535 --no-wait

    # Save to file
    $(basename "$0") -i 2303.14535 -o blog.md

    # Multiple papers
    $(basename "$0") -i "2303.14535,1706.03762"

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: https://scholarclaw.youdao.com)
EOF
}

# Default values
ARXIV_IDS=""
VIEWS=""
FILES=()
TIMEOUT=$DEFAULT_TIMEOUT
NO_WAIT=false
OUTPUT=""
CONTENT_ONLY=false

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
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --no-wait)
            NO_WAIT=true
            shift
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
if [[ -z "$ARXIV_IDS" ]] && [[ ${#FILES[@]} -eq 0 ]]; then
    echo "Error: Either --arxiv-ids or --file must be specified."
    show_help
    exit 1
fi

# Function to submit blog task
submit_blog() {
    local curl_args=(-s --max-time 60 -w "\n%{http_code}" -X POST)

    # Add auth header if set
    if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
        curl_args+=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
    fi

    # Add form data
    if [[ -n "$ARXIV_IDS" ]]; then
        curl_args+=(-F "arxiv_ids=$ARXIV_IDS")
    fi

    for file in "${FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "Error: File not found: $file" >&2
            exit 1
        fi
        curl_args+=(-F "files=@$file")
    done

    if [[ -n "$VIEWS" ]]; then
        curl_args+=(-F "views_content=$VIEWS")
    fi

    curl "${curl_args[@]}" "${SERVER_URL}/api/blog/submit"
}

# Function to check task status
check_status() {
    local task_id="$1"
    curl -s --max-time 30 -w "\n%{http_code}" "${AUTH_HEADER[@]}" "${SERVER_URL}/api/blog/task/${task_id}"
}

# Function to get blog result
get_result() {
    local task_id="$1"
    curl -s --max-time 30 -w "\n%{http_code}" "${AUTH_HEADER[@]}" "${SERVER_URL}/api/blog/result/${task_id}"
}

# Submit task
echo "Submitting blog generation task..." >&2
if [[ -n "$ARXIV_IDS" ]]; then
    echo "ArXiv IDs: $ARXIV_IDS" >&2
fi
if [[ ${#FILES[@]} -gt 0 ]]; then
    echo "Files: ${FILES[*]}" >&2
fi

RESPONSE=$(submit_blog)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
    handle_http_error "$HTTP_CODE" "$BODY" "Submit blog task"
    exit 1
fi

# Extract task ID
TASK_ID=$(echo "$BODY" | jq -r '.task_id // .id // empty')

if [[ -z "$TASK_ID" ]]; then
    echo "Error: Could not extract task ID from response" >&2
    echo "$BODY"
    exit 1
fi

echo "Task ID: $TASK_ID" >&2

# If no-wait mode, output and exit
if [[ "$NO_WAIT" == "true" ]]; then
    echo "$BODY" | jq .
    exit 0
fi

# Wait for completion
echo "Waiting for completion (timeout: ${TIMEOUT}s)..." >&2

START_TIME=$(date +%s)
ELAPSED=0

while [[ $ELAPSED -lt $TIMEOUT ]]; do
    sleep $POLL_INTERVAL

    STATUS_RESPONSE=$(check_status "$TASK_ID")
    STATUS_HTTP=$(echo "$STATUS_RESPONSE" | tail -n1)
    STATUS_BODY=$(echo "$STATUS_RESPONSE" | sed '$d')

    if [[ "$STATUS_HTTP" -ne 200 ]]; then
        handle_http_error "$STATUS_HTTP" "$STATUS_BODY" "Check blog status"
        exit 1
    fi

    STATUS=$(echo "$STATUS_BODY" | jq -r '.status // .state // "unknown"')
    ELAPSED=$(($(date +%s) - START_TIME))

    echo "[$ELAPSED s] Status: $STATUS" >&2

    case "$STATUS" in
        completed|success)
            echo "Task completed!" >&2
            break
            ;;
        failed|error)
            echo "Task failed!" >&2
            echo "$STATUS_BODY" | jq .
            exit 1
            ;;
        pending|running|processing|queued)
            # Continue waiting
            ;;
        *)
            echo "Warning: Unknown status: $STATUS" >&2
            ;;
    esac
done

if [[ $ELAPSED -ge $TIMEOUT ]]; then
    echo "Error: Timeout after ${TIMEOUT}s. Task is still running." >&2
    echo "Task ID: $TASK_ID"
    echo "Check status later with: scholarclaw blog-status -i $TASK_ID"
    exit 1
fi

# Fetch result
RESULT_RESPONSE=$(get_result "$TASK_ID")
RESULT_HTTP=$(echo "$RESULT_RESPONSE" | tail -n1)
RESULT_BODY=$(echo "$RESULT_RESPONSE" | sed '$d')

if [[ "$RESULT_HTTP" -ne 200 ]]; then
    handle_http_error "$RESULT_HTTP" "$RESULT_BODY" "Fetch blog result"
    exit 1
fi

# Output result
if [[ "$CONTENT_ONLY" == "true" ]]; then
    CONTENT=$(echo "$RESULT_BODY" | jq -r '.blog_content // .markdown_content // .')
    if [[ -n "$OUTPUT" ]]; then
        echo "$CONTENT" > "$OUTPUT"
        echo "Saved to: $OUTPUT" >&2
    else
        echo "$CONTENT"
    fi
elif [[ -n "$OUTPUT" ]]; then
    BLOG_CONTENT=$(echo "$RESULT_BODY" | jq -r '.blog_content // .markdown_content // ""')
    echo "$BLOG_CONTENT" > "$OUTPUT"
    echo "Saved to: $OUTPUT" >&2
    echo "$RESULT_BODY" | jq 'del(.blog_content) | del(.markdown_content)'
else
    if command -v jq &> /dev/null; then
        echo "$RESULT_BODY" | jq .
    else
        echo "$RESULT_BODY"
    fi
fi
