---
type: tool_order
before: { tool: Bash, input_match: '/health' }
after: { tool: Bash, input_match: '^(?![\s\S]*/health)[\s\S]*/notes/[^\s"'']*/archive' }
---
