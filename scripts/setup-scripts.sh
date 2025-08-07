#!/bin/bash

# Setup script for Ito development scripts

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}Setting up Ito development scripts...${NC}"

# Make scripts executable
chmod +x "$SCRIPT_DIR/update-ito.sh"
chmod +x "$SCRIPT_DIR/dev-workflow.sh"

echo -e "${GREEN}✅ Scripts are now executable!${NC}"
echo

echo -e "${BLUE}📋 Usage Instructions:${NC}"
echo
echo "1. Update Script (check for new releases):"
echo "   ./scripts/update-ito.sh"
echo
echo "2. Development Workflow:"
echo "   ./scripts/dev-workflow.sh help                    # Show all commands"
echo "   ./scripts/dev-workflow.sh sync                    # Sync with upstream"
echo "   ./scripts/dev-workflow.sh create-feature <name>   # Create feature branch"
echo "   ./scripts/dev-workflow.sh commit <type> <msg>     # Commit changes"
echo "   ./scripts/dev-workflow.sh push                    # Push to your fork"
echo "   ./scripts/dev-workflow.sh test                    # Run tests"
echo "   ./scripts/dev-workflow.sh create-pr <title>       # Create PR"
echo "   ./scripts/dev-workflow.sh status                  # Show status"
echo
echo "3. Quick aliases (add to your ~/.zshrc or ~/.bashrc):"
echo "   alias ito-update='./scripts/update-ito.sh'"
echo "   alias ito-dev='./scripts/dev-workflow.sh'"
echo
echo -e "${GREEN}🎉 Setup complete! You can now use the scripts from the project root.${NC}"
