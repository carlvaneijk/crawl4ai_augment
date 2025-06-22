# Crawl4AI MCP Server Stack

A complete integration package for adding Crawl4AI documentation crawling capabilities to Augment Code through the Model Context Protocol (MCP).

## 🚀 Quick Start

**Option 1: One-line integration (recommended for Augment):**

```bash
# From any project directory where you want crawling capabilities
curl -sSL https://raw.githubusercontent.com/carlvaneijk/crawl4ai_augment/main/scripts/integrate.sh | bash
```

**Option 2: Manual integration:**

```bash
# Clone the repository first
git clone https://github.com/carlvaneijk/crawl4ai_augment.git
cd crawl4ai_augment

# Then run integration from your target project directory
cd /path/to/your/project
/path/to/crawl4ai_augment/scripts/integrate.sh
```

## 📁 Project Structure

```
crawl4ai_augment/
├── README.md                    # Project overview and quick start guide
├── SELF_INTEGRATION_GUIDE.md    # Complete integration instructions for Augment
├── mcp-server/                  # Ready-to-deploy MCP server
│   ├── src/crawl4ai_mcp/
│   │   ├── server.py           # Main MCP server implementation
│   │   └── __init__.py
│   └── pyproject.toml          # Dependencies and configuration
├── scripts/
│   └── integrate.sh            # Automated integration script
└── templates/
    ├── augment-settings.json   # Augment configuration template
    └── mcp-config.json         # MCP server configuration template
```

## 🎯 Key Features

- **Automated Documentation Crawling**: Extract structured information from technical docs
- **Knowledge Graph Building**: Automatically build knowledge graphs for frameworks
- **Non-Disruptive Integration**: Sidecar pattern that doesn't modify existing projects
- **Multiple Extraction Types**: Markdown, structured JSON, and link extraction
- **Intelligent Configuration**: Detects and preserves existing MCP server setups

## 🔧 Integration Strategy

The integration follows a **sidecar pattern**:

1. **Isolated Environment**: Creates `.crawl4ai-mcp/` directory in your project
2. **Dependency Management**: Uses UV or pip for isolated dependency installation
3. **Configuration Detection**: Finds and updates existing Augment settings
4. **Non-Destructive**: Preserves all existing MCP servers and configurations
5. **Reversible**: Includes uninstall script for clean removal

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
- `get_knowledge_graph()` - Retrieve current knowledge graph state
- `analyze_framework_prompt(framework_name, documentation_url)` - Generate analysis prompts

## 🔄 Rollback

To remove the integration:

```bash
./.crawl4ai-mcp/scripts/uninstall.sh
```

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
