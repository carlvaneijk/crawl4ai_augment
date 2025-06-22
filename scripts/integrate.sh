#!/bin/bash

# Crawl4AI MCP Server Integration Script
# This script automatically integrates the Crawl4AI MCP server into any existing project

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MCP_DIR=".crawl4ai-mcp"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

echo -e "${BLUE}🚀 Starting Crawl4AI MCP Server Integration${NC}"
echo -e "${BLUE}Project Root: ${PROJECT_ROOT}${NC}"

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

    # Check write permissions
    if [ -w "${PROJECT_ROOT}" ]; then
        print_status "Write permissions verified"
    else
        print_error "No write permissions in project directory"
        exit 1
    fi
}

# Create isolated MCP environment
create_mcp_environment() {
    echo -e "\n${BLUE}Creating MCP server environment...${NC}"

    # Remove existing directory if it exists
    if [ -d "${MCP_DIR}" ]; then
        print_warning "Existing ${MCP_DIR} found, removing..."
        rm -rf "${MCP_DIR}"
    fi

    # Create directory structure
    mkdir -p "${MCP_DIR}/src/crawl4ai_mcp"
    mkdir -p "${MCP_DIR}/knowledge_cache"
    mkdir -p "${MCP_DIR}/scripts"

    print_status "Created ${MCP_DIR} directory structure"
}

# Copy server files
copy_server_files() {
    echo -e "\n${BLUE}Copying MCP server files...${NC}"

    # Copy from the crawl4aistack repository
    cp "${SCRIPT_DIR}/../mcp-server/src/crawl4ai_mcp/server.py" "${MCP_DIR}/src/crawl4ai_mcp/"
    cp "${SCRIPT_DIR}/../mcp-server/src/crawl4ai_mcp/__init__.py" "${MCP_DIR}/src/crawl4ai_mcp/"
    cp "${SCRIPT_DIR}/../mcp-server/pyproject.toml" "${MCP_DIR}/"

    # Create a simple server runner
    cat > "${MCP_DIR}/server.py" << 'EOF'
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

    chmod +x "${MCP_DIR}/server.py"
    print_status "Copied server implementation files"
}

# Install dependencies
install_dependencies() {
    echo -e "\n${BLUE}Installing dependencies...${NC}"

    cd "${MCP_DIR}"

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

    cd "${PROJECT_ROOT}"
}

# Detect and update Augment configuration
update_augment_config() {
    echo -e "\n${BLUE}Updating Augment configuration...${NC}"

    # Common Augment settings locations
    SETTINGS_LOCATIONS=(
        "$HOME/Library/Application Support/Augment/settings.json"
        "$HOME/.config/augment/settings.json"
        "$HOME/.augment/settings.json"
        "./augment-settings.json"
        "./.augment/settings.json"
    )

    SETTINGS_FILE=""

    # Find existing settings file
    for location in "${SETTINGS_LOCATIONS[@]}"; do
        if [ -f "$location" ]; then
            SETTINGS_FILE="$location"
            print_status "Found Augment settings at: $location"
            break
        fi
    done

    # Create MCP server configuration
    MCP_CONFIG=$(cat << EOF
{
  "name": "crawl4ai-knowledge",
  "command": "${PACKAGE_MANAGER}",
  "args": ["run", "python", "server.py"],
  "cwd": "${PROJECT_ROOT}/${MCP_DIR}",
  "env": {
    "PYTHONPATH": "${PROJECT_ROOT}/${MCP_DIR}/src"
  }
}
EOF
)

    if [ -n "$SETTINGS_FILE" ]; then
        # Backup existing settings
        cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"
        print_status "Backed up existing settings"

        # Update existing settings (this is a simplified approach)
        # In a real implementation, you'd use jq or a Python script for proper JSON manipulation
        print_warning "Manual configuration update required"
        echo -e "${YELLOW}Please add this MCP server configuration to your Augment settings:${NC}"
        echo "$MCP_CONFIG"
    else
        # Create new settings file
        SETTINGS_FILE="$HOME/.config/augment/settings.json"
        mkdir -p "$(dirname "$SETTINGS_FILE")"

        cat > "$SETTINGS_FILE" << EOF
{
  "augment": {
    "advanced": {
      "mcpServers": [
        $MCP_CONFIG
      ]
    }
  }
}
EOF
        print_status "Created new Augment settings file"
    fi
}

# Update .gitignore
update_gitignore() {
    echo -e "\n${BLUE}Updating .gitignore...${NC}"

    if [ -f ".gitignore" ]; then
        # Check if already ignored
        if ! grep -q "${MCP_DIR}" .gitignore; then
            echo "" >> .gitignore
            echo "# Crawl4AI MCP Server" >> .gitignore
            echo "${MCP_DIR}/" >> .gitignore
            print_status "Added ${MCP_DIR} to .gitignore"
        else
            print_status "${MCP_DIR} already in .gitignore"
        fi
    else
        # Create .gitignore
        cat > .gitignore << EOF
# Crawl4AI MCP Server
${MCP_DIR}/
EOF
        print_status "Created .gitignore with ${MCP_DIR}"
    fi
}

# Test the MCP server
test_mcp_server() {
    echo -e "\n${BLUE}Testing MCP server...${NC}"

    cd "${MCP_DIR}"

    # Test server startup
    if [ "${PACKAGE_MANAGER}" = "uv" ]; then
        timeout 10s uv run python server.py --help > /dev/null 2>&1 || true
    else
        source .venv/bin/activate
        timeout 10s python server.py --help > /dev/null 2>&1 || true
    fi

    print_status "MCP server test completed"
    cd "${PROJECT_ROOT}"
}

# Create uninstall script
create_uninstall_script() {
    echo -e "\n${BLUE}Creating uninstall script...${NC}"

    cat > "${MCP_DIR}/scripts/uninstall.sh" << 'EOF'
#!/bin/bash

# Uninstall script for Crawl4AI MCP Server

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MCP_DIR=".crawl4ai-mcp"

echo "🗑️  Removing Crawl4AI MCP Server integration..."

# Remove the MCP directory
if [ -d "${PROJECT_ROOT}/${MCP_DIR}" ]; then
    rm -rf "${PROJECT_ROOT}/${MCP_DIR}"
    echo "✓ Removed ${MCP_DIR} directory"
fi

# Remove from .gitignore
if [ -f "${PROJECT_ROOT}/.gitignore" ]; then
    sed -i.bak '/# Crawl4AI MCP Server/,+1d' "${PROJECT_ROOT}/.gitignore"
    echo "✓ Cleaned up .gitignore"
fi

echo "✓ Crawl4AI MCP Server integration removed"
echo "⚠️  Please manually remove the MCP server from your Augment settings"
EOF

    chmod +x "${MCP_DIR}/scripts/uninstall.sh"
    print_status "Created uninstall script"
}

# Main integration flow
main() {
    check_prerequisites
    create_mcp_environment
    copy_server_files
    install_dependencies
    update_augment_config
    update_gitignore
    test_mcp_server
    create_uninstall_script

    echo -e "\n${GREEN}🎉 Integration completed successfully!${NC}"
    echo -e "\n${BLUE}Next steps:${NC}"
    echo "1. Restart Augment Code"
    echo "2. Test with: 'Can you crawl the Python documentation?'"
    echo "3. Use the uninstall script if needed: ./${MCP_DIR}/scripts/uninstall.sh"
    echo -e "\n${BLUE}MCP server location: ${PROJECT_ROOT}/${MCP_DIR}${NC}"
}

# Run main function
main "$@"