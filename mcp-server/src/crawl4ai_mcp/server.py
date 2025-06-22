import asyncio
import json
import os
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