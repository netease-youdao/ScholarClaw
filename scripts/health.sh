#!/bin/bash
# ScholarClaw - Health Check Script
# Check the health of the ScholarClaw service

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

Check the health of the ScholarClaw service and backend services.

Options:
    -v, --verbose             Show detailed service status
    -h, --help                Show this help message

Examples:
    $(basename "$0")
    $(basename "$0") -v

Environment Variables:
    SCHOLARCLAW_SERVER_URL      Base URL for the search server (default: http://localhost:8090)
EOF
}

# Default values
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
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

# Basic health check
echo "Checking service health..." >&2

# Build auth header if API key is set (health check typically doesn't need auth, but include for consistency)
AUTH_HEADER=()
if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
    AUTH_HEADER=(-H "X-API-Key: $SCHOLARCLAW_API_KEY")
fi

RESPONSE=$(curl -s -w "\n%{http_code}" "${AUTH_HEADER[@]}" "${SERVER_URL}/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -eq 200 ]]; then
    echo "✓ ScholarClaw Service: OK" >&2
else
    echo "✗ ScholarClaw Service: FAILED (HTTP $HTTP_CODE)" >&2
    handle_http_error "$HTTP_CODE" "$BODY" "Health check"
    exit 1
fi

# Verbose check - show backend services
if [[ "$VERBOSE" == "true" ]]; then
    echo "" >&2
    echo "Backend Services:" >&2

    DETAIL_RESPONSE=$(curl -s "${AUTH_HEADER[@]}" "${SERVER_URL}/search/health")

    if command -v jq &> /dev/null; then
        echo "$DETAIL_RESPONSE" | jq -r '.services | to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "  Unable to parse service details"
    else
        echo "$DETAIL_RESPONSE"
    fi
fi

# Output basic health result
if command -v jq &> /dev/null; then
    echo "$BODY" | jq .
else
    echo "$BODY"
fi
