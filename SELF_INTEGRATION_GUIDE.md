# Crawl4AI MCP Server - Self-Integration Guide

## Overview
This guide enables Augment to automatically integrate the Crawl4AI MCP server globally, making it available to all projects. The integration is designed to be non-disruptive and project-independent.

## Prerequisites Check
Before integration, verify these requirements:
- Python 3.10+ available
- UV package manager installed (or pip as fallback)
- Augment Code with MCP support
- Write access to home directory

## Integration Strategy
The integration follows a **global installation pattern** - the MCP server is installed once in a global location (`~/.augment/mcp-servers/`) and serves all projects.

## Step 1: Global Installation

Install the MCP server globally so it's available to all projects:

```bash
# One-line installation
curl -sSL https://raw.githubusercontent.com/carlvaneijk/crawl4ai_augment/main/scripts/integrate.sh | bash
```

Or manually run the integration script:

```bash
# Clone the integration package
git clone https://github.com/carlvaneijk/crawl4ai_augment.git
cd crawl4ai_augment

# Run the installation script
./scripts/integrate.sh
```

## Step 2: What the Integration Script Does

The script automatically:

1. **Creates global environment**: Sets up `~/.augment/crawl4ai-mcp/` directory
2. **Installs dependencies**: Uses UV or pip to install required packages
3. **Copies server files**: Deploys the MCP server implementation
4. **Tests connection**: Verifies the server starts correctly
5. **Provides configuration**: Shows the exact settings needed for Augment

## Step 3: Configure Augment Code MCP Server

After the integration script completes, you need to add the MCP server to Augment's configuration:

### Option A: Using Augment Settings Panel (Recommended)

1. **Open Augment Code**
2. **Click the gear icon** in the upper right corner
3. **Navigate to "MCP Servers"** section
4. **Click "Add Server"** and enter:
   - **Name**: `crawl4ai-knowledge`
   - **Command**: `uv`
   - **Arguments**: `run python server.py`
   - **Working Directory**: `~/.augment/crawl4ai-mcp`
   - **Environment Variables**:
     - Key: `PYTHONPATH`
     - Value: `~/.augment/crawl4ai-mcp/src`

### Option B: Edit settings.json Manually

1. **Find your Augment settings file** (usually at `~/Library/Application Support/Augment/settings.json`)
2. **Add the MCP server configuration**:

⚠️ **Important**: Use the flat key structure `"augment.advanced.mcpServers"`, NOT nested objects!

```json
{
  "augment.advanced.mcpServers": [
    {
      "name": "crawl4ai-knowledge",
      "command": "uv",
      "args": ["run", "python", "server.py"],
      "cwd": "/Users/YOUR_USERNAME/.augment/crawl4ai-mcp",
      "env": {
        "PYTHONPATH": "/Users/YOUR_USERNAME/.augment/crawl4ai-mcp/src"
      }
    }
  ]
}
```

**Important**: Replace `YOUR_USERNAME` with your actual username, or use the full path shown by the installation script.

### If You Have Existing MCP Servers

If you already have other MCP servers configured, add the crawl4ai server to the existing array:

```json
{
  "augment.advanced.mcpServers": [
    {
      "name": "your-existing-server",
      "command": "...",
      "args": ["..."]
    },
    {
      "name": "crawl4ai-knowledge",
      "command": "uv",
      "args": ["run", "python", "server.py"],
      "cwd": "/FULL/PATH/TO/YOUR/PROJECT/.crawl4ai-mcp",
      "env": {
        "PYTHONPATH": "/FULL/PATH/TO/YOUR/PROJECT/.crawl4ai-mcp/src"
      }
    }
  ]
}
```

## Step 4: Restart Augment Code

After adding the MCP server configuration:

1. **Restart Augment Code** completely (quit and reopen)
2. **Verify the server is loaded** - you should see "crawl4ai-knowledge" in the MCP servers list
3. **Check for any error messages** in the Augment logs

## Step 5: Test the Integration

Test that the MCP server is working:

1. **Open a chat in Augment**
2. **Try a simple crawl command**:
   ```
   "Can you crawl the Python documentation homepage and tell me what you find?"
   ```
3. **Verify the tools are available** - Augment should be able to use the crawling capabilities

## Step 6: Usage Instructions

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
- **Restart Augment Code** completely after adding the MCP server configuration
- **Check the JSON structure** - ensure you're using `"augment.advanced.mcpServers"` as the key, NOT nested `"augment": { "advanced": { "mcpServers": [...] } }`
- **Check the MCP server configuration** in Augment settings - ensure the working directory path is correct
- **Verify server starts manually**: `cd .crawl4ai-mcp && uv run python server.py`
- **Check Augment logs** for any error messages about the MCP server
- **Ensure absolute paths** are used in the configuration, not relative paths

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

## Additional Resources

- **[Crawl4AI Documentation](https://docs.crawl4ai.com/)** - Official Crawl4AI documentation
- **[MCP Specification](https://modelcontextprotocol.io/)** - Model Context Protocol specification
- **[Augment Code MCP Setup](https://docs.augmentcode.com/setup-augment/mcp)** - Augment MCP configuration guide

The integration is designed to be invisible to your existing workflow while adding powerful documentation crawling capabilities to Augment.