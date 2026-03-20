#!/bin/bash
# ScholarClaw - Common Functions
# Shared functions for authentication and configuration

# Configuration file path
SCHOLARCLAW_CONFIG_FILE="${HOME}/.scholarclaw/config.json"

# Get API key from configuration sources
# Priority: 1. Environment variable, 2. Config file
get_api_key() {
    # 1. Check environment variable (highest priority)
    if [[ -n "$SCHOLARCLAW_API_KEY" ]]; then
        echo "$SCHOLARCLAW_API_KEY"
        return
    fi

    # 2. Check config file
    if [[ -f "$SCHOLARCLAW_CONFIG_FILE" ]] && command -v jq &> /dev/null; then
        local key
        key=$(jq -r '.apiKey // empty' "$SCHOLARCLAW_CONFIG_FILE" 2>/dev/null)
        if [[ -n "$key" && "$key" != "null" ]]; then
            echo "$key"
            return
        fi
    fi

    # Return empty if not found
    echo ""
}

# Get server URL from configuration sources
# Priority: 1. Environment variable, 2. Config file, 3. Default
get_server_url() {
    # 1. Check environment variable (highest priority)
    if [[ -n "$SCHOLARCLAW_SERVER_URL" ]]; then
        echo "$SCHOLARCLAW_SERVER_URL"
        return
    fi

    # 2. Check config file
    if [[ -f "$SCHOLARCLAW_CONFIG_FILE" ]] && command -v jq &> /dev/null; then
        local url
        url=$(jq -r '.serverUrl // empty' "$SCHOLARCLAW_CONFIG_FILE" 2>/dev/null)
        if [[ -n "$url" && "$url" != "null" ]]; then
            echo "$url"
            return
        fi
    fi

    # 3. Default value
    echo "https://scholarclaw.youdao.com"
}

# Check if an HTTP error response is authentication-related
# Usage: if is_auth_error "$HTTP_CODE" "$BODY"; then ...
is_auth_error() {
    local http_code="$1"
    local body="$2"

    # 401/403/429 are auth/quota errors
    if [[ "$http_code" -eq 401 || "$http_code" -eq 403 || "$http_code" -eq 429 ]]; then
        return 0
    fi

    # Check response body for auth/quota-related keywords
    local detail
    detail=$(echo "$body" | jq -r '.detail // .' 2>/dev/null | tr '[:upper:]' '[:lower:]')
    if echo "$detail" | grep -qiE 'auth|api.?key|token|credential|permission|forbidden|unauthorized|quota|limit|rate|鉴权|认证|密钥|授权|额度|限额|用量'; then
        return 0
    fi

    return 1
}

# Print authentication error message and guide user to configure key
print_auth_error() {
    echo "Error: 已超出匿名用户使用额度，需要 API Key 才能继续使用。" >&2
    echo "" >&2
    echo "请前往 https://scholarclaw.youdao.com/ 申请 API Key，然后通过以下方式配置：" >&2
    echo "  1. 设置环境变量: export SCHOLARCLAW_API_KEY='your-key'" >&2
    echo "  2. 添加到 OpenClaw config.yaml: apiKey: 'your-key'" >&2
    echo "  3. 创建配置文件: ~/.scholarclaw/config.json" >&2
    echo '     {"apiKey": "your-key"}' >&2
}

# Handle HTTP error response, with special handling for auth errors
# Usage: handle_http_error "$HTTP_CODE" "$BODY" "操作描述" || exit 1
handle_http_error() {
    local http_code="$1"
    local body="$2"
    local operation="${3:-请求}"

    if is_auth_error "$http_code" "$body"; then
        print_auth_error
    else
        echo "Error: ${operation} failed with HTTP $http_code" >&2
        echo "$body" | jq -r '.detail // .' 2>/dev/null || echo "$body"
    fi
    return 1
}

# Get authentication header if API key is configured
# Usage: CURL_ARGS+=($(get_auth_header))
get_auth_header() {
    local api_key
    api_key=$(get_api_key)

    if [[ -n "$api_key" ]]; then
        echo "-H" "X-API-Key: $api_key"
    fi
}

# Get auth header array for curl commands
# Usage: eval "AUTH_HEADERS=($(get_auth_headers))"
get_auth_headers() {
    local api_key
    api_key=$(get_api_key)

    if [[ -n "$api_key" ]]; then
        echo '-H "X-API-Key: '"$api_key"'"'
    fi
}

# Initialize configuration
# Call this at the start of scripts
# Usage: init_config
init_config() {
    # Export the resolved API key for use in scripts (may be empty)
    export SCHOLARCLAW_API_KEY=$(get_api_key)
    export SCHOLARCLAW_SERVER_URL=$(get_server_url)
}
