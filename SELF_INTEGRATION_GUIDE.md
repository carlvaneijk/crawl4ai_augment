# Crawl4AI MCP Server - Self-Integration Guide

## Overview
This guide enables Augment to automatically integrate the Crawl4AI MCP server into any existing project. The integration is designed to be non-disruptive and reversible.

## Prerequisites Check
Before integration, verify these requirements:
- Python 3.10+ available
- UV package manager installed (or pip as fallback)
- Augment Code with MCP support
- Write access to project directory

## Integration Strategy
The integration follows a **sidecar pattern** - the MCP server runs alongside your existing project without modifying core project files.

## Step 1: Automated Setup Script Execution

Execute the setup script that handles all integration automatically:

```bash
# From your project root directory
curl -sSL https://raw.githubusercontent.com/your-repo/crawl4aistack/main/scripts/integrate.sh | bash
```

Or manually run the integration script:

```bash
# Clone the integration package
git clone https://github.com/your-repo/crawl4aistack.git .crawl4ai-mcp
cd .crawl4ai-mcp
./scripts/integrate.sh
```

## Step 2: What the Integration Script Does

The script automatically:

1. **Creates isolated environment**: Sets up `.crawl4ai-mcp/` directory in your project
2. **Installs dependencies**: Uses UV or pip to install required packages
3. **Copies server files**: Deploys the MCP server implementation
4. **Detects existing MCP config**: Finds your current Augment settings
5. **Updates configuration**: Adds crawl4ai server to existing MCP servers list
6. **Tests connection**: Verifies the server starts correctly

## Step 3: Configuration Detection and Update

The script intelligently handles configuration:

### Existing MCP Servers
- Detects existing `settings.json` or Settings Panel configuration
- Appends crawl4ai server without disrupting existing servers
- Preserves all existing MCP server configurations

### New MCP Setup
- Creates initial MCP configuration if none exists
- Sets up crawl4ai as the first MCP server

### Configuration Template Applied
```json
{
  "name": "crawl4ai-knowledge",
  "command": "uv",
  "args": ["run", "python", "server.py"],
  "cwd": "{{PROJECT_ROOT}}/.crawl4ai-mcp",
  "env": {
    "PYTHONPATH": "{{PROJECT_ROOT}}/.crawl4ai-mcp"
  }
}
```

## Step 4: Verification and Testing

After integration, the script:

1. **Starts the MCP server** in test mode
2. **Verifies tool availability** (crawl_documentation, extend_knowledge_graph)
3. **Tests basic functionality** with a simple crawl
4. **Reports integration status**

## Step 5: Usage Instructions

Once integrated, use natural language with Augment:

```
"I need to understand the FastAPI framework. Can you crawl their documentation and add it to our knowledge base?"

"Help me learn React hooks by analyzing the official React documentation."

"Compare the API patterns between Express.js and Koa.js by crawling their docs."
```

## Integration File Structure

After integration, your project will have:

```
your-project/
├── .crawl4ai-mcp/           # Isolated MCP server environment
│   ├── server.py            # Main MCP server implementation
│   ├── pyproject.toml       # Dependencies and configuration
│   ├── .venv/               # Virtual environment (if using UV)
│   └── knowledge_cache/     # Cached crawl results
├── .gitignore               # Updated to exclude .crawl4ai-mcp/
└── [your existing files]    # Unchanged
```

## Rollback Instructions

To remove the integration:

```bash
# From your project root
./.crawl4ai-mcp/scripts/uninstall.sh
```

This will:
- Remove the `.crawl4ai-mcp/` directory
- Restore original Augment settings
- Clean up any added gitignore entries

## Troubleshooting

### Integration Fails
- Check Python version: `python --version`
- Verify UV installation: `uv --version`
- Check permissions: Ensure write access to project directory

### MCP Server Not Found
- Restart Augment Code after integration
- Check settings.json was updated correctly
- Verify server starts manually: `cd .crawl4ai-mcp && uv run python server.py`

### Crawling Fails
- Ensure internet connectivity
- Some sites block automated crawling
- Check Chrome/Chromium installation for JavaScript-heavy sites

## Advanced Configuration

### Custom Extraction Patterns
Edit `.crawl4ai-mcp/config.json` to customize:
- URL patterns for different documentation types
- Extraction strategies for specific frameworks
- Caching and rate limiting settings

### Multiple Projects
The integration is project-specific. Run the integration script in each project where you want crawling capabilities.

## Security Notes

- The MCP server runs locally and doesn't send data to external services
- Crawled content is cached locally in `.crawl4ai-mcp/knowledge_cache/`
- All network requests are made directly from your machine
- No API keys or external authentication required for basic functionality

## Next Steps

After successful integration:
1. Test with a simple documentation crawl
2. Explore the knowledge graph features
3. Customize extraction patterns for your specific needs
4. Consider setting up persistent storage for larger knowledge bases

The integration is designed to be invisible to your existing workflow while adding powerful documentation crawling capabilities to Augment.