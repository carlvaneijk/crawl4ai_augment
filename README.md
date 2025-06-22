# Crawl4AI MCP Server Stack

A complete integration package for adding Crawl4AI documentation crawling capabilities to Augment Code through the Model Context Protocol (MCP).

## 🚀 Quick Start

**Option 1: One-line installation (recommended):**

```bash
# Install globally - serves all projects
curl -sSL https://raw.githubusercontent.com/carlvaneijk/crawl4ai_augment/main/scripts/integrate.sh | bash
```

**Option 2: Manual installation:**

```bash
# Clone the repository first
git clone https://github.com/carlvaneijk/crawl4ai_augment.git
cd crawl4ai_augment

# Run the installation script
./scripts/integrate.sh
```

### After Installation: Configure Augment

**Important**: After running the global installation, you need to add the MCP server to Augment:

1. **Open Augment Code** → **Settings** (gear icon) → **MCP Servers**
2. **Add Server** with these details:
   - **Name**: `crawl4ai-knowledge`
   - **Command**: `uv`
   - **Arguments**: `run python server.py`
   - **Working Directory**: `~/.augment/crawl4ai-mcp`
3. **Restart Augment Code**

⚠️ **JSON Configuration Note**: If editing settings.json manually, use `"augment.advanced.mcpServers"` as the key, NOT nested objects.

✅ **Global Benefits**: One installation serves ALL your projects - no per-project setup needed!

See [SELF_INTEGRATION_GUIDE.md](SELF_INTEGRATION_GUIDE.md) for detailed configuration instructions.

## 📁 Project Structure

```
crawl4ai_augment/                # This repository
├── README.md                    # Project overview and quick start guide
├── SELF_INTEGRATION_GUIDE.md    # Complete integration instructions for Augment
├── mcp-server/                  # Ready-to-deploy MCP server
│   ├── src/crawl4ai_mcp/
│   │   ├── server.py           # Main MCP server implementation
│   │   └── __init__.py
│   └── pyproject.toml          # Dependencies and configuration
├── scripts/
│   └── integrate.sh            # Automated global installation script
└── templates/
    ├── augment-settings.json   # Augment configuration template
    └── mcp-config.json         # MCP server configuration template

~/.augment/                      # Global installation location
└── crawl4ai-mcp/               # Installed MCP server (after running script)
    ├── server.py               # Server runner
    ├── src/crawl4ai_mcp/       # Server implementation
    ├── pyproject.toml          # Dependencies
    └── .venv/                  # Virtual environment
```

## 🎯 Key Features

- **Automated Documentation Crawling**: Extract structured information from technical docs
- **Knowledge Graph Building**: Automatically build knowledge graphs for frameworks
- **Non-Disruptive Integration**: Sidecar pattern that doesn't modify existing projects
- **Multiple Extraction Types**: Markdown, structured JSON, and link extraction
- **Intelligent Configuration**: Detects and preserves existing MCP server setups

## 🔧 Integration Strategy

The integration follows a **global installation pattern**:

1. **Global Location**: Installs in `~/.augment/crawl4ai-mcp/`
2. **One Server, All Projects**: Single installation serves all your projects
3. **Isolated Dependencies**: Uses UV or pip for isolated dependency installation
4. **Project-Independent**: No project directory modifications needed
5. **Augment-Friendly**: Installed outside project directories as recommended

## 📖 Usage

Once integrated, use natural language with Augment:

```
"I need to understand the FastAPI framework. Can you crawl their documentation and add it to our knowledge base?"

"Help me learn React hooks by analyzing the official React documentation."

"Compare the API patterns between Express.js and Koa.js by crawling their docs."
```

## 🛠️ Available Tools

- `crawl_documentation(url, extract_type)` - Crawl and extract from URLs
- `extend_knowledge_graph(framework_name, base_url, depth, patterns)` - Build knowledge graphs

*Note: Additional resources and prompts will be added in future versions once the core functionality is stable.*

## 🔄 Rollback

To remove the global installation:

```bash
rm -rf ~/.augment/crawl4ai-mcp
```

Then remove the MCP server from your Augment settings and restart Augment Code.

## 🔧 Troubleshooting

### Integration Fails with "No such file or directory"
- Ensure you have internet connectivity for downloading files
- Check that curl is installed: `curl --version`
- Try the manual integration method instead

### MCP Server Not Found in Augment
- Restart Augment Code after integration
- Check that the integration completed successfully
- Verify the server starts manually: `cd .crawl4ai-mcp && uv run python server.py --help`

### Permission Denied Errors
- Ensure you have write permissions in the project directory
- Try running with appropriate permissions or from a different directory

## 📚 Documentation

- **[SELF_INTEGRATION_GUIDE.md](SELF_INTEGRATION_GUIDE.md)** - Complete self-integration instructions for Augment
- **[README.md](README.md)** - This file - project overview and quick start guide

## 🔒 Security

- Runs locally with no external data transmission
- Cached content stored locally in `.crawl4ai-mcp/knowledge_cache/`
- No API keys required for basic functionality
- Respects robots.txt and implements rate limiting

## 🎯 Design Goals

This project is specifically designed to enable Augment to:

1. **Self-integrate** the capability into existing projects
2. **Abstract complexity** away from the agent
3. **Preserve existing workflows** without disruption
4. **Provide immediate value** through natural language interaction

The implementation prioritizes ease of integration and agent abstraction over manual configuration complexity.
