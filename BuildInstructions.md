# Crawl4AI MCP Server Deployment Plan

## Overview

This plan outlines how to deploy Crawl4AI as a Model Context Protocol (MCP) server for your local agentic coding setup, enabling your AI agent to dynamically extend the knowledge graph for frameworks, packages, and technical documentation.

## Architecture Overview

```
┌─────────────────┐     ┌────────────────┐     ┌─────────────────┐
│  Augment Code   │────▶│   MCP Server   │────▶│    Crawl4AI     │
│  (MCP Client)   │     │  (Python SDK)  │     │   (Scraping)    │
└─────────────────┘     └────────────────┘     └─────────────────┘
                               │
                               ▼
                    ┌────────────────────┐
                    │  Knowledge Graph   │
                    │   (Resources &     │
                    │    Documentation)  │
                    └────────────────────┘
```

## Prerequisites

### System Requirements
- Python 3.10 or later
- macOS (as per your preference)
- UV package manager (recommended for Python dependencies)
- Augment Code with MCP support enabled

### Required Installations
```bash
# Install UV package manager (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Crawl4AI
pip install crawl4ai

# For Chrome browser support (recommended)
pip install crawl4ai[chrome]
```

## Step 1: Create the MCP Server Structure

Create your project directory:

```bash
mkdir crawl4ai-mcp-server
cd crawl4ai-mcp-server

# Create Python virtual environment using UV
uv venv
source .venv/bin/activate  # On macOS

# Create project structure
mkdir -p src/crawl4ai_mcp
touch src/crawl4ai_mcp/__init__.py
touch src/crawl4ai_mcp/server.py
touch pyproject.toml
touch README.md
```

## Step 2: Install Dependencies

Create `pyproject.toml`:

```toml
[project]
name = "crawl4ai-mcp-server"
version = "0.1.0"
description = "MCP server for Crawl4AI integration"
requires-python = ">=3.10"
dependencies = [
    "mcp[cli]>=1.4.0",
    "crawl4ai>=0.4.0",
    "aiofiles>=24.0.0",
    "beautifulsoup4>=4.12.0",
    "lxml>=5.0.0",
]

[build-system]
requires = ["setuptools", "wheel"]
build-backend = "setuptools.build_meta"
```

Install dependencies:

```bash
uv pip install -e .
```

## Step 3: Implement the Crawl4AI MCP Server

Create `src/crawl4ai_mcp/server.py`:

```python
import asyncio
import json
from typing import Dict, List, Optional
from mcp.server.fastmcp import FastMCP
from crawl4ai import AsyncWebCrawler
from crawl4ai.extraction_strategy import LLMExtractionStrategy
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize MCP server
mcp = FastMCP("Crawl4AI Knowledge Graph Server")

# Global crawler instance
crawler = None

async def init_crawler():
    """Initialize the async web crawler"""
    global crawler
    if crawler is None:
        crawler = AsyncWebCrawler(
            browser_type="chromium",
            headless=True,
            verbose=False
        )
    return crawler

@mcp.tool()
async def crawl_documentation(url: str, extract_type: str = "markdown") -> Dict:
    """
    Crawl technical documentation and extract structured information.
    
    Args:
        url: The URL to crawl (e.g., framework documentation)
        extract_type: Type of extraction - 'markdown', 'structured', or 'links'
    
    Returns:
        Dictionary containing extracted content and metadata
    """
    try:
        crawler = await init_crawler()
        
        # Configure extraction based on type
        extraction_config = {
            "markdown": {"output_format": "markdown"},
            "structured": {
                "output_format": "json",
                "extraction_strategy": LLMExtractionStrategy(
                    provider="openai",
                    schema={
                        "type": "object",
                        "properties": {
                            "title": {"type": "string"},
                            "main_concepts": {"type": "array", "items": {"type": "string"}},
                            "code_examples": {"type": "array", "items": {"type": "string"}},
                            "api_methods": {"type": "array", "items": {"type": "object"}},
                            "dependencies": {"type": "array", "items": {"type": "string"}}
                        }
                    }
                )
            },
            "links": {"extract_links": True}
        }
        
        config = extraction_config.get(extract_type, extraction_config["markdown"])
        
        # Perform the crawl
        result = await crawler.arun(url=url, **config)
        
        return {
            "url": url,
            "title": result.metadata.get("title", ""),
            "content": result.markdown if extract_type == "markdown" else result.extracted_content,
            "links": result.links if extract_type == "links" else [],
            "metadata": result.metadata,
            "success": result.success
        }
        
    except Exception as e:
        logger.error(f"Error crawling {url}: {str(e)}")
        return {
            "url": url,
            "error": str(e),
            "success": False
        }

@mcp.tool()
async def extend_knowledge_graph(
    framework_name: str,
    base_url: str,
    depth: int = 2,
    patterns: Optional[List[str]] = None
) -> Dict:
    """
    Automatically extend the knowledge graph for a framework or package.
    
    Args:
        framework_name: Name of the framework/package
        base_url: Base documentation URL
        depth: How many levels deep to crawl
        patterns: URL patterns to include (e.g., ['/api/', '/guide/'])
    
    Returns:
        Dictionary containing the knowledge graph structure
    """
    knowledge_graph = {
        "framework": framework_name,
        "base_url": base_url,
        "nodes": {},
        "relationships": []
    }
    
    # URL queue for breadth-first crawling
    url_queue = [(base_url, 0)]
    visited_urls = set()
    
    crawler = await init_crawler()
    
    while url_queue and len(visited_urls) < 50:  # Limit to 50 pages
        current_url, current_depth = url_queue.pop(0)
        
        if current_url in visited_urls or current_depth > depth:
            continue
            
        visited_urls.add(current_url)
        
        # Crawl the page
        result = await crawl_documentation(current_url, "structured")
        
        if result.get("success"):
            # Add node to knowledge graph
            knowledge_graph["nodes"][current_url] = {
                "title": result.get("title"),
                "concepts": result.get("content", {}).get("main_concepts", []),
                "apis": result.get("content", {}).get("api_methods", []),
                "depth": current_depth
            }
            
            # Process links for next level
            if current_depth < depth:
                for link in result.get("links", []):
                    if should_crawl_link(link, base_url, patterns):
                        url_queue.append((link, current_depth + 1))
                        knowledge_graph["relationships"].append({
                            "from": current_url,
                            "to": link,
                            "type": "references"
                        })
    
    return knowledge_graph

def should_crawl_link(link: str, base_url: str, patterns: Optional[List[str]] = None) -> bool:
    """Determine if a link should be crawled based on patterns"""
    if not link.startswith(base_url):
        return False
    
    if patterns:
        return any(pattern in link for pattern in patterns)
    
    # Default patterns for technical documentation
    default_patterns = ['/api/', '/guide/', '/docs/', '/reference/', '/tutorial/']
    return any(pattern in link for pattern in default_patterns)

@mcp.resource("knowledge_graph")
async def get_knowledge_graph() -> str:
    """
    Retrieve the current state of the knowledge graph.
    
    Returns:
        JSON string of the knowledge graph
    """
    # This would typically load from a persistent store
    # For now, return a placeholder
    return json.dumps({
        "frameworks": [],
        "total_nodes": 0,
        "last_updated": None
    })

@mcp.prompt("analyze_framework")
async def analyze_framework_prompt(framework_name: str, documentation_url: str) -> str:
    """
    Generate a prompt for analyzing a new framework.
    
    Args:
        framework_name: Name of the framework
        documentation_url: URL to the framework's documentation
    
    Returns:
        Formatted prompt for framework analysis
    """
    return f"""
    Please analyze the {framework_name} framework by:
    
    1. First, use the extend_knowledge_graph tool with these parameters:
       - framework_name: "{framework_name}"
       - base_url: "{documentation_url}"
       - depth: 2
       - patterns: ["/api/", "/guide/", "/tutorial/"]
    
    2. Then, summarize:
       - Core concepts and architecture
       - Main APIs and their purposes
       - Common use patterns
       - Integration points with other tools
    
    3. Finally, suggest how this framework could be useful in our current project context.
    """

# Main entry point
if __name__ == "__main__":
    import sys
    mcp.run(transport="stdio")
```

## Step 4: Configure Augment Code

### Option A: Using Augment Settings Panel

1. Open Augment Code
2. Click the gear icon in the upper right
3. Navigate to MCP servers section
4. Add new server with:
   - **Name**: `crawl4ai-knowledge`
   - **Command**: `uv run python src/crawl4ai_mcp/server.py`
   - **Working Directory**: `/path/to/crawl4ai-mcp-server`

### Option B: Edit settings.json

Add to your Augment settings.json:

```json
{
  "augment": {
    "advanced": {
      "mcpServers": [
        {
          "name": "crawl4ai-knowledge",
          "command": "uv",
          "args": ["run", "python", "src/crawl4ai_mcp/server.py"],
          "cwd": "/path/to/crawl4ai-mcp-server",
          "env": {
            "PYTHONPATH": "/path/to/crawl4ai-mcp-server/src"
          }
        }
      ]
    }
  }
}
```

## Step 5: Test the MCP Server

Use the MCP inspector to test your server:

```bash
cd crawl4ai-mcp-server
mcp dev src/crawl4ai_mcp/server.py
```

This will open a web interface where you can test your tools.

## Step 6: Usage Examples

Once configured, you can interact with the server through Augment Code:

### Example 1: Crawl React Documentation
```
"Can you help me understand React hooks? Please crawl the React documentation and extend our knowledge graph."
```

### Example 2: Analyze a New Framework
```
"I need to learn about FastAPI. Please analyze its documentation at https://fastapi.tiangolo.com and add it to our knowledge base."
```

### Example 3: Compare Frameworks
```
"Compare the API design patterns between Express.js and FastAPI based on their documentation."
```

## Advanced Features

### 1. Persistent Knowledge Storage

Add a database backend for persistent storage:

```python
import sqlite3
from datetime import datetime

class KnowledgeStore:
    def __init__(self, db_path="knowledge_graph.db"):
        self.db_path = db_path
        self.init_db()
    
    def init_db(self):
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS frameworks (
                id INTEGER PRIMARY KEY,
                name TEXT UNIQUE,
                base_url TEXT,
                last_updated TIMESTAMP,
                metadata JSON
            )
        """)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS pages (
                id INTEGER PRIMARY KEY,
                framework_id INTEGER,
                url TEXT UNIQUE,
                title TEXT,
                content TEXT,
                extracted_data JSON,
                FOREIGN KEY (framework_id) REFERENCES frameworks (id)
            )
        """)
        conn.commit()
        conn.close()
```

### 2. Caching and Rate Limiting

Implement caching to avoid re-crawling:

```python
from functools import lru_cache
from datetime import datetime, timedelta

@lru_cache(maxsize=100)
async def get_cached_page(url: str, max_age_hours: int = 24):
    # Check if page exists in cache and is fresh
    # Return cached version or None
    pass
```

### 3. Custom Extraction Strategies

Create specialized extractors for different documentation types:

```python
class APIDocumentationExtractor:
    def extract(self, html_content: str) -> Dict:
        # Extract API endpoints, parameters, responses
        pass

class TutorialExtractor:
    def extract(self, html_content: str) -> Dict:
        # Extract step-by-step instructions, code examples
        pass
```

## Troubleshooting

### Common Issues

1. **MCP Server Not Found**
   - Ensure the path in settings.json is absolute
   - Check Python environment activation

2. **Crawling Fails**
   - Verify Chrome/Chromium is installed
   - Check network connectivity
   - Some sites may block automated crawling

3. **Memory Issues**
   - Implement pagination for large documentation sites
   - Use streaming responses for large datasets

### Debug Mode

Enable debug logging:

```python
import os
os.environ['MCP_DEBUG'] = '1'
logging.basicConfig(level=logging.DEBUG)
```

## Security Considerations

1. **URL Validation**: Always validate URLs before crawling
2. **Rate Limiting**: Implement rate limiting to respect server resources
3. **Authentication**: Some documentation may require authentication
4. **Content Filtering**: Filter out potentially harmful content

## Next Steps

1. **Enhance Extraction**: Implement more sophisticated extraction strategies
2. **Add Visualisation**: Create tools to visualise the knowledge graph
3. **Integration Tests**: Build comprehensive test suite
4. **Performance Optimisation**: Implement concurrent crawling with proper limits
5. **Export Formats**: Add tools to export knowledge in various formats (GraphQL, RDF, etc.)

## Resources

- [Crawl4AI Documentation](https://docs.crawl4ai.com/)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Augment Code MCP Setup](https://docs.augmentcode.com/setup-augment/mcp)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)

This deployment plan provides a robust foundation for integrating Crawl4AI with your agentic coding environment through MCP, enabling dynamic knowledge graph extension for any frameworks or packages you work with.