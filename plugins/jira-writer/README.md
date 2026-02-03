# Jira Writer Plugin

Create and update Jira Cloud tickets with rich content, including automatic Mermaid diagram embedding and interactive checkboxes.

## Prerequisites

| Dependency | Purpose | Required |
|------------|---------|----------|
| `JIRA_DOMAIN` | Your Jira Cloud domain | Yes |
| `JIRA_API_KEY` | REST API auth (`email:token`) | Yes |
| Atlassian MCP | Fallback when REST fails | No (optional) |
| `mmdc` | Mermaid CLI for diagrams | For diagrams only |

## Setup

```bash
# Required
export JIRA_DOMAIN="company.atlassian.net"
export JIRA_API_KEY="your-email@company.com:your-api-token"

# Optional: for Mermaid diagrams
npm install -g @mermaid-js/mermaid-cli
```

Get your API token at: https://id.atlassian.com/manage-profile/security/api-tokens

## Verify Installation

```bash
# Test connection
./skills/jira-writer/scripts/test-jira-connection.sh

# Check all prerequisites
./skills/jira-writer/scripts/check-prerequisites.sh
```

## Features

- Create and update Jira issues
- Rich formatting (headings, bold, italic, links, code blocks, tables)
- Interactive checkboxes (`- [ ]` and `- [x]`)
- Auto-convert Mermaid diagrams to embedded images
- Markdown file import
- REST API primary with MCP fallback

## Usage

The skill activates when you:
- Ask to create or update a Jira ticket
- Provide content with Mermaid diagrams
- Reference a markdown file for ticket content

### Examples

```
"Create a ticket for the authentication feature"
"Update PROJ-123 with this description"
"Add a sequence diagram showing the auth flow to PROJ-456"
```

## Scripts

| Script | Purpose |
|--------|---------|
| `test-jira-connection.sh` | Test API connectivity |
| `check-prerequisites.sh` | Verify dependencies |
| `jira-api-wrapper.sh` | Unified API interface |
| `jira-rest-api.sh` | Core REST API functions |
| `jira-mermaid-upload.sh` | Upload single diagram |
| `jira-mermaid-batch-upload.sh` | Upload multiple diagrams |

## License

MIT
