#!/usr/bin/env bash
#
# check-prerequisites.sh
#
# Checks all prerequisites for the jira-writer skill.
# Returns JSON with status of each dependency.
#
# Usage:
#   ./check-prerequisites.sh
#
# Output (JSON):
#   {
#     "mmdc": { "available": true, "path": "/path/to/mmdc" },
#     "jira_domain": { "available": true, "value": "company.atlassian.net" },
#     "jira_api_key": { "available": true, "length": 123 },
#     "all_ready": true,
#     "diagram_ready": true
#   }
#

set -euo pipefail

# Check mmdc
mmdc_available=false
mmdc_path=""
if command -v mmdc &> /dev/null; then
    mmdc_available=true
    mmdc_path=$(which mmdc)
fi

# Check curl
curl_available=false
if command -v curl &> /dev/null; then
    curl_available=true
fi

# Check jq
jq_available=false
if command -v jq &> /dev/null; then
    jq_available=true
fi

# Check JIRA_DOMAIN
jira_domain_available=false
jira_domain_value=""
if [[ -n "${JIRA_DOMAIN:-}" ]]; then
    jira_domain_available=true
    jira_domain_value="$JIRA_DOMAIN"
fi

# Check JIRA_API_KEY
jira_api_key_available=false
jira_api_key_length=0
if [[ -n "${JIRA_API_KEY:-}" ]]; then
    jira_api_key_available=true
    jira_api_key_length=${#JIRA_API_KEY}
fi

# Determine overall readiness
# all_ready = can do basic Jira operations (via MCP)
# diagram_ready = can upload and embed diagrams (requires REST API)
all_ready=true
diagram_ready=true

if [[ "$jira_domain_available" != "true" ]]; then
    diagram_ready=false
fi

if [[ "$jira_api_key_available" != "true" ]]; then
    diagram_ready=false
fi

if [[ "$mmdc_available" != "true" ]]; then
    diagram_ready=false
fi

if [[ "$curl_available" != "true" ]]; then
    diagram_ready=false
fi

# Output JSON
cat <<EOF
{
  "mmdc": {
    "available": $mmdc_available,
    "path": "$mmdc_path",
    "install_cmd": "npm install -g @mermaid-js/mermaid-cli"
  },
  "curl": {
    "available": $curl_available
  },
  "jq": {
    "available": $jq_available,
    "install_cmd": "brew install jq"
  },
  "jira_domain": {
    "available": $jira_domain_available,
    "value": "$jira_domain_value",
    "env_var": "JIRA_DOMAIN"
  },
  "jira_api_key": {
    "available": $jira_api_key_available,
    "length": $jira_api_key_length,
    "env_var": "JIRA_API_KEY",
    "format": "email@domain.com:api_token (NOT base64 encoded)"
  },
  "all_ready": $all_ready,
  "diagram_ready": $diagram_ready
}
EOF
