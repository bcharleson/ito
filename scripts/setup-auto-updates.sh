#!/bin/bash

# Setup script for automatic Ito update checking

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🔧 Setting up automatic Ito update checking...${NC}"
echo

# Function to show options
show_options() {
    echo "Choose an option:"
    echo "1) Check for updates daily (recommended)"
    echo "2) Check for updates weekly"
    echo "3) Check for updates manually only"
    echo "4) Show current status"
    echo "5) Remove automatic checking"
    echo "6) Exit"
    echo
}

# Function to setup daily cron job
setup_daily_cron() {
    echo -e "${BLUE}Setting up daily update checking...${NC}"
    
    # Create cron job
    local cron_job="0 9 * * * cd $PROJECT_ROOT && ./scripts/auto-update-check.sh >> binary-updates.log 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "auto-update-check.sh"; then
        echo -e "${YELLOW}⚠️  Cron job already exists. Removing old one...${NC}"
        crontab -l 2>/dev/null | grep -v "auto-update-check.sh" | crontab -
    fi
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    
    echo -e "${GREEN}✅ Daily update checking configured!${NC}"
    echo "The script will run daily at 9:00 AM"
    echo "Logs will be saved to: $PROJECT_ROOT/binary-updates.log"
}

# Function to setup weekly cron job
setup_weekly_cron() {
    echo -e "${BLUE}Setting up weekly update checking...${NC}"
    
    # Create cron job (every Sunday at 9 AM)
    local cron_job="0 9 * * 0 cd $PROJECT_ROOT && ./scripts/auto-update-check.sh >> binary-updates.log 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "auto-update-check.sh"; then
        echo -e "${YELLOW}⚠️  Cron job already exists. Removing old one...${NC}"
        crontab -l 2>/dev/null | grep -v "auto-update-check.sh" | crontab -
    fi
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    
    echo -e "${GREEN}✅ Weekly update checking configured!${NC}"
    echo "The script will run every Sunday at 9:00 AM"
    echo "Logs will be saved to: $PROJECT_ROOT/binary-updates.log"
}

# Function to remove cron job
remove_cron_job() {
    echo -e "${BLUE}Removing automatic update checking...${NC}"
    
    if crontab -l 2>/dev/null | grep -q "auto-update-check.sh"; then
        crontab -l 2>/dev/null | grep -v "auto-update-check.sh" | crontab -
        echo -e "${GREEN}✅ Automatic update checking removed!${NC}"
    else
        echo -e "${YELLOW}No automatic update checking found.${NC}"
    fi
}

# Function to show current status
show_status() {
    echo -e "${BLUE}Current Status:${NC}"
    echo
    
    # Check if cron job exists
    if crontab -l 2>/dev/null | grep -q "auto-update-check.sh"; then
        echo -e "${GREEN}✅ Automatic update checking is enabled${NC}"
        echo "Cron job:"
        crontab -l | grep "auto-update-check.sh"
    else
        echo -e "${YELLOW}❌ Automatic update checking is not enabled${NC}"
    fi
    
    echo
    echo "Manual check command:"
    echo "  ./scripts/auto-update-check.sh"
    echo
    echo "Check current version:"
    echo "  ./scripts/check-binary-updates.sh status"
}

# Function to setup launchd (macOS alternative to cron)
setup_launchd() {
    echo -e "${BLUE}Setting up launchd service (macOS)...${NC}"
    
    local plist_file="$HOME/Library/LaunchAgents/com.ito.updater.plist"
    
    # Create plist file
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ito.updater</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PROJECT_ROOT/scripts/auto-update-check.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$PROJECT_ROOT</string>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$PROJECT_ROOT/binary-updates.log</string>
    <key>StandardErrorPath</key>
    <string>$PROJECT_ROOT/binary-updates.log</string>
</dict>
</plist>
EOF
    
    # Load the service
    launchctl load "$plist_file"
    
    echo -e "${GREEN}✅ Launchd service configured!${NC}"
    echo "The script will run daily at 9:00 AM"
    echo "Service file: $plist_file"
    echo "Logs will be saved to: $PROJECT_ROOT/binary-updates.log"
}

# Main menu
while true; do
    show_options
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            setup_daily_cron
            break
            ;;
        2)
            setup_weekly_cron
            break
            ;;
        3)
            echo -e "${BLUE}Manual checking only.${NC}"
            echo "To check for updates manually, run:"
            echo "  ./scripts/auto-update-check.sh"
            break
            ;;
        4)
            show_status
            ;;
        5)
            remove_cron_job
            break
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Please enter 1-6.${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
    echo
done

echo
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo
echo "Quick reference:"
echo "  Check for updates: ./scripts/auto-update-check.sh"
echo "  Check version:     ./scripts/check-binary-updates.sh status"
echo "  Force install:     ./scripts/check-binary-updates.sh install"
echo "  View logs:         cat binary-updates.log"
