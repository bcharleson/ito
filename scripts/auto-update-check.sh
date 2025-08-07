#!/bin/bash

# Auto Update Checker for Ito
# This script can be run manually or via cron to check for updates

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🔍 Checking for Ito updates...${NC}"
echo "Date: $(date)"
echo "---"

# Run the update checker
"$SCRIPT_DIR/check-binary-updates.sh" check

echo "---"
echo -e "${GREEN}✅ Update check completed${NC}"
