#!/bin/bash

# Crawl4AI MCP Server Global Installation Script
# This script installs the Crawl4AI MCP server globally for Augment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Simple configuration
INSTALL_DIR="$HOME/.augment/crawl4ai-mcp"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 Installing Crawl4AI MCP Server for Augment${NC}"
echo -e "${BLUE}Installation Location: ${INSTALL_DIR}${NC}"

# Function to print status messages
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    echo -e "\n${BLUE}Checking prerequisites...${NC}"

    # Check Python version
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        if python3 -c 'import sys; exit(0 if sys.version_info >= (3, 10) else 1)'; then
            print_status "Python ${PYTHON_VERSION} found"
        else
            print_error "Python 3.10+ required, found ${PYTHON_VERSION}"
            exit 1
        fi
    else
        print_error "Python 3 not found"
        exit 1
    fi

    # Check for UV or pip
    if command -v uv &> /dev/null; then
        print_status "UV package manager found"
        PACKAGE_MANAGER="uv"
    elif command -v pip &> /dev/null; then
        print_status "pip found (fallback)"
        PACKAGE_MANAGER="pip"
    else
        print_error "Neither UV nor pip found"
        exit 1
    fi

    # Check for curl (needed for remote downloads)
    if command -v curl &> /dev/null; then
        print_status "curl found"
    else
        print_error "curl not found (required for downloading files)"
        exit 1
    fi
}

# Create installation directory
create_install_directory() {
    echo -e "\n${BLUE}Creating installation directory...${NC}"

    # Remove existing directory if it exists
    if [ -d "${INSTALL_DIR}" ]; then
        print_warning "Existing installation found, removing..."
        rm -rf "${INSTALL_DIR}"
    fi

    # Create directory structure
    mkdir -p "${INSTALL_DIR}/src/crawl4ai_mcp"
    mkdir -p "${INSTALL_DIR}/knowledge_cache"

    print_status "Created installation directory"
}

# Copy server files
copy_server_files() {
    echo -e "\n${BLUE}Installing server files...${NC}"

    # Check if we're running from the repository or via curl
    if [ -f "${SCRIPT_DIR}/../mcp-server/src/crawl4ai_mcp/server.py" ]; then
        # Running from cloned repository
        cp "${SCRIPT_DIR}/../mcp-server/src/crawl4ai_mcp/server.py" "${INSTALL_DIR}/src/crawl4ai_mcp/"
        cp "${SCRIPT_DIR}/../mcp-server/src/crawl4ai_mcp/__init__.py" "${INSTALL_DIR}/src/crawl4ai_mcp/"
        cp "${SCRIPT_DIR}/../mcp-server/pyproject.toml" "${INSTALL_DIR}/"
        print_status "Copied server files from local repository"
    else
        # Running via curl - download files directly from GitHub
        echo -e "${BLUE}Downloading server files from GitHub...${NC}"

        # Download server.py
        if ! curl -sSL "https://raw.githubusercontent.com/carlvaneijk/crawl4ai_augment/main/mcp-server/src/crawl4ai_mcp/server.py" \
            -o "${INSTALL_DIR}/src/crawl4ai_mcp/server.py"; then
            print_error "Failed to download server.py"
            exit 1
        fi

        # Download __init__.py
        if ! curl -sSL "https://raw.githubusercontent.com/carlvaneijk/crawl4ai_augment/main/mcp-server/src/crawl4ai_mcp/__init__.py" \
            -o "${INSTALL_DIR}/src/crawl4ai_mcp/__init__.py"; then
            print_error "Failed to download __init__.py"
            exit 1
        fi

        # Download pyproject.toml
        if ! curl -sSL "https://raw.githubusercontent.com/carlvaneijk/crawl4ai_augment/main/mcp-server/pyproject.toml" \
            -o "${INSTALL_DIR}/pyproject.toml"; then
            print_error "Failed to download pyproject.toml"
            exit 1
        fi

        print_status "Downloaded server files from GitHub"
    fi

    # Create a simple server runner
    cat > "${INSTALL_DIR}/server.py" << 'EOF'
#!/usr/bin/env python3
"""
Simple runner for the Crawl4AI MCP server
"""
import sys
import os

# Add the src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from crawl4ai_mcp.server import mcp

if __name__ == "__main__":
    mcp.run(transport="stdio")
EOF

    chmod +x "${INSTALL_DIR}/server.py"
    print_status "Server files installed"
}

# Install dependencies
install_dependencies() {
    echo -e "\n${BLUE}Installing dependencies...${NC}"

    cd "${INSTALL_DIR}"

    if [ "${PACKAGE_MANAGER}" = "uv" ]; then
        # Create virtual environment with UV
        uv venv
        print_status "Created virtual environment with UV"

        # Install dependencies
        uv pip install -e .
        print_status "Installed dependencies with UV"
    else
        # Use pip with virtual environment
        python3 -m venv .venv
        source .venv/bin/activate
        pip install -e .
        print_status "Installed dependencies with pip"
    fi
}

# Test the server
test_server() {
    echo -e "\n${BLUE}Testing server installation...${NC}"

    cd "${INSTALL_DIR}"

    # Test server startup
    if [ "${PACKAGE_MANAGER}" = "uv" ]; then
        timeout 5s uv run python server.py --help > /dev/null 2>&1 || true
    else
        source .venv/bin/activate
        timeout 5s python server.py --help > /dev/null 2>&1 || true
    fi

    print_status "Server installation test completed"
}

# Main installation flow
main() {
    check_prerequisites
    create_install_directory
    copy_server_files
    install_dependencies
    test_server

    echo -e "\n${GREEN}🎉 Crawl4AI MCP Server installed successfully!${NC}"
    echo -e "\n${YELLOW}⚠️  IMPORTANT: Add this server to Augment Code:${NC}"
    echo -e "\n${BLUE}Augment Settings Configuration:${NC}"
    echo "1. Open Augment Code → Settings (gear icon) → MCP Servers"
    echo "2. Click 'Add Server' and enter:"
    echo "   - Name: crawl4ai-knowledge"
    echo "   - Command: ${PACKAGE_MANAGER}"
    echo "   - Arguments: run python server.py"
    echo "   - Working Directory: ${INSTALL_DIR}"
    echo "   - Environment Variables: PYTHONPATH = ${INSTALL_DIR}/src"
    echo "3. Restart Augment Code completely"
    echo "4. Test with: 'Can you crawl the Python documentation?'"
    echo -e "\n${BLUE}Installation Location: ${INSTALL_DIR}${NC}"
    echo -e "${BLUE}To uninstall: rm -rf ${INSTALL_DIR}${NC}"
}

# Run main function
main "$@"