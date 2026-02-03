#!/usr/bin/env bash
#
# test-jira-connection.sh
#
# Tests which Jira API methods are available and recommends the best approach.
#
# Usage:
#   ./test-jira-connection.sh
#
# Output (JSON):
#   {
#     "rest_api": {
#       "available": true,
#       "authenticated": true,
#       "user": { "displayName": "...", "email": "..." }
#     },
#     "mcp": {
#       "available": false,
#       "reason": "Cannot be verified from shell script"
#     },
#     "recommended": "rest_api"
#   }
#
# Exit Codes:
#   0 - At least one API method is available
#   1 - No API methods available
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the REST API functions if available
if [[ -f "$SCRIPT_DIR/jira-rest-api.sh" ]]; then
    source "$SCRIPT_DIR/jira-rest-api.sh"
fi

# Colors for output
if [[ -t 2 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

log_header() { echo -e "\n${BLUE}=== $1 ===${NC}" >&2; }
log_success() { echo -e "${GREEN}[OK]${NC} $1" >&2; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_info() { echo -e "$1" >&2; }

# Results storage
REST_AVAILABLE=false
REST_AUTHENTICATED=false
REST_USER_NAME=""
REST_USER_EMAIL=""
REST_ERROR=""
MCP_NOTE="MCP availability must be verified within Claude Code (cannot test from shell)"
RECOMMENDED="none"

# Test REST API
test_rest_api() {
    log_header "Testing REST API"

    # Check credentials
    if [[ -z "${JIRA_DOMAIN:-}" ]]; then
        log_fail "JIRA_DOMAIN not set"
        REST_ERROR="JIRA_DOMAIN environment variable not set"
        return 1
    fi
    log_success "JIRA_DOMAIN: $JIRA_DOMAIN"

    if [[ -z "${JIRA_API_KEY:-}" ]]; then
        log_fail "JIRA_API_KEY not set"
        REST_ERROR="JIRA_API_KEY environment variable not set"
        return 1
    fi
    log_success "JIRA_API_KEY: configured (${#JIRA_API_KEY} chars)"

    # Check required tools
    if ! command -v curl &> /dev/null; then
        log_fail "curl not found"
        REST_ERROR="curl not installed"
        return 1
    fi
    log_success "curl: available"

    if ! command -v jq &> /dev/null; then
        log_fail "jq not found"
        REST_ERROR="jq not installed"
        return 1
    fi
    log_success "jq: available"

    REST_AVAILABLE=true

    # Test authentication by getting current user
    log_info "Testing authentication..."

    local auth_header
    auth_header=$(echo -n "$JIRA_API_KEY" | base64)

    local response
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Basic $auth_header" \
        -H "Content-Type: application/json" \
        "https://$JIRA_DOMAIN/rest/api/3/myself" 2>&1) || true

    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "200" ]]; then
        REST_AUTHENTICATED=true
        REST_USER_NAME=$(echo "$body" | jq -r '.displayName // "Unknown"')
        REST_USER_EMAIL=$(echo "$body" | jq -r '.emailAddress // "Unknown"')
        log_success "Authentication successful"
        log_info "  User: $REST_USER_NAME"
        log_info "  Email: $REST_USER_EMAIL"
        return 0
    else
        REST_AUTHENTICATED=false
        case "$http_code" in
            401)
                REST_ERROR="Invalid credentials (HTTP 401)"
                log_fail "Authentication failed: Invalid API token or email"
                ;;
            403)
                REST_ERROR="Access forbidden (HTTP 403)"
                log_fail "Authentication failed: Access forbidden"
                ;;
            404)
                REST_ERROR="API endpoint not found (HTTP 404) - check JIRA_DOMAIN"
                log_fail "API endpoint not found: verify JIRA_DOMAIN is correct"
                ;;
            000)
                REST_ERROR="Connection failed - network error or invalid domain"
                log_fail "Connection failed: check network and JIRA_DOMAIN"
                ;;
            *)
                REST_ERROR="HTTP $http_code error"
                log_fail "Unexpected error: HTTP $http_code"
                if [[ -n "$body" ]]; then
                    log_info "  Response: $body"
                fi
                ;;
        esac
        return 1
    fi
}

# Determine recommendation
determine_recommendation() {
    log_header "Recommendation"

    if [[ "$REST_AUTHENTICATED" == "true" ]]; then
        RECOMMENDED="rest_api"
        log_success "REST API is fully configured and authenticated"
        log_info "The plugin will use REST API as the primary method"
    elif [[ "$REST_AVAILABLE" == "true" ]]; then
        RECOMMENDED="mcp"
        log_warn "REST API credentials found but authentication failed"
        log_info "Fix credentials to use REST API, or rely on MCP fallback"
    else
        RECOMMENDED="mcp"
        log_warn "REST API not configured"
        log_info "Configure JIRA_DOMAIN and JIRA_API_KEY for full functionality"
        log_info "MCP can be used as fallback if configured in Claude Code"
    fi
}

# Generate JSON output
generate_output() {
    local rest_auth_json
    if [[ "$REST_AUTHENTICATED" == "true" ]]; then
        rest_auth_json=$(jq -n \
            --arg name "$REST_USER_NAME" \
            --arg email "$REST_USER_EMAIL" \
            '{displayName: $name, email: $email}')
    else
        rest_auth_json="null"
    fi

    local rest_error_json
    if [[ -n "$REST_ERROR" ]]; then
        rest_error_json="\"$REST_ERROR\""
    else
        rest_error_json="null"
    fi

    jq -n \
        --argjson rest_available "$REST_AVAILABLE" \
        --argjson rest_authenticated "$REST_AUTHENTICATED" \
        --argjson rest_user "$rest_auth_json" \
        --argjson rest_error "$rest_error_json" \
        --arg mcp_note "$MCP_NOTE" \
        --arg recommended "$RECOMMENDED" \
        '{
            "rest_api": {
                "available": $rest_available,
                "authenticated": $rest_authenticated,
                "user": $rest_user,
                "error": $rest_error
            },
            "mcp": {
                "available": "unknown",
                "note": $mcp_note
            },
            "recommended": $recommended,
            "setup_instructions": {
                "rest_api": {
                    "JIRA_DOMAIN": "export JIRA_DOMAIN=\"company.atlassian.net\"",
                    "JIRA_API_KEY": "export JIRA_API_KEY=\"email@company.com:your-api-token\"",
                    "get_token": "https://id.atlassian.com/manage-profile/security/api-tokens"
                },
                "mcp": "Configure Atlassian MCP in Claude Code MCP settings"
            }
        }'
}

# Print summary to stderr
print_summary() {
    log_header "Summary"

    echo "" >&2
    echo "REST API Status:" >&2
    echo "  Credentials: $([ "$REST_AVAILABLE" == "true" ] && echo "Configured" || echo "Missing")" >&2
    echo "  Authentication: $([ "$REST_AUTHENTICATED" == "true" ] && echo "Verified" || echo "Failed")" >&2
    if [[ "$REST_AUTHENTICATED" == "true" ]]; then
        echo "  User: $REST_USER_NAME ($REST_USER_EMAIL)" >&2
    elif [[ -n "$REST_ERROR" ]]; then
        echo "  Error: $REST_ERROR" >&2
    fi

    echo "" >&2
    echo "MCP Status: Cannot be verified from shell (check Claude Code)" >&2
    echo "" >&2
    echo "Recommended API: $RECOMMENDED" >&2
    echo "" >&2
}

# Main
main() {
    test_rest_api || true
    determine_recommendation
    print_summary

    # Output JSON to stdout
    generate_output

    # Exit with success if at least REST is authenticated
    if [[ "$REST_AUTHENTICATED" == "true" ]]; then
        exit 0
    else
        exit 1
    fi
}

main
