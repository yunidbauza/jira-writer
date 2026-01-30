# Jira Writer

Claude Code plugin for creating and updating Jira Cloud tickets with rich content, including automatic Mermaid diagram embedding and interactive checkboxes.

## Installation

### From GitHub

First, add the repository as a marketplace:
```bash
/plugin marketplace add yunidbauza/jira-writer
```

Then install the plugin:
```bash
/plugin install jira-writer
```

### Manual Installation

```bash
git clone https://github.com/yunidbauza/jira-writer.git ~/.claude/plugins/jira-writer
chmod +x ~/.claude/plugins/jira-writer/scripts/*.sh
```

## Prerequisites

| Dependency | Purpose | Required |
|------------|---------|----------|
| **Atlassian MCP** | Jira API access | Yes |
| `JIRA_DOMAIN` | Your Jira Cloud domain | For diagrams/checkboxes |
| `JIRA_API_KEY` | REST API auth (`email:token`) | For diagrams/checkboxes |
| `mmdc` | Mermaid CLI | For diagrams only |

## Environment Setup

```bash
export JIRA_DOMAIN="company.atlassian.net"
export JIRA_API_KEY="your-email@company.com:your-api-token"
npm install -g @mermaid-js/mermaid-cli  # optional, for diagrams
```

Verify setup:
```bash
~/.claude/plugins/jira-writer/scripts/check-prerequisites.sh
```

## Features

- **Ticket Management** - Create and update Jira issues
- **Rich Formatting** - Headings, bold, italic, links, code blocks, tables
- **Interactive Checkboxes** - `- [ ]` and `- [x]` as clickable task lists
- **Mermaid Diagrams** - Auto-convert and embed as images
- **Markdown Import** - Use .md files as ticket content

### Supported Diagram Types (11)

| Type | Syntax | Type | Syntax |
|------|--------|------|--------|
| Flowchart | `graph TD` | Sequence | `sequenceDiagram` |
| Class | `classDiagram` | State | `stateDiagram-v2` |
| ER | `erDiagram` | Gantt | `gantt` |
| Pie | `pie` | Mindmap | `mindmap` |
| User Journey | `journey` | Timeline | `timeline` |
| Quadrant | `quadrantChart` | | |

## Usage

The skill activates contextually when you:

- Ask to create or update a Jira ticket
- Provide content with Mermaid diagrams
- Reference a markdown file for ticket content

### Examples

```
"Create a ticket for the authentication feature"
"Update PROJ-123 with this description"
"Add a sequence diagram showing the auth flow to PROJ-456"
"Create a ticket with acceptance criteria:
 - [ ] User can login
 - [x] Remember me works"
```

## How It Works

The skill automatically selects the best API based on content:

| Content | API | Reason |
|---------|-----|--------|
| Text, lists, code | MCP | Simple conversion |
| Checkboxes (`- [ ]`) | REST | MCP can't create interactive taskLists |
| Mermaid diagrams | REST | Requires attachment upload |

## Scripts

| Script | Purpose |
|--------|---------|
| `check-prerequisites.sh` | Verify all dependencies |
| `jira-mermaid-upload.sh` | Upload single diagram |
| `jira-mermaid-batch-upload.sh` | Upload multiple diagrams |

## Resources

- [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/)
- [Jira REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
- [Mermaid Documentation](https://mermaid.js.org/)

## License

MIT
