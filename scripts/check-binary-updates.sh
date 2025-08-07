#!/bin/bash

# Ito Binary Update Checker
# This script checks for new binary releases and handles updates with human confirmation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
REPO="heyito/ito"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOWNLOADS_DIR="$PROJECT_ROOT/downloads"
BACKUP_DIR="$PROJECT_ROOT/backups"
LOG_FILE="$PROJECT_ROOT/binary-updates.log"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
    echo "$message"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get current installed version
get_current_version() {
    # Try to get version from the installed app
    if [ -d "/Applications/Ito.app" ]; then
        # Try to get version from Info.plist
        local version=$(defaults read "/Applications/Ito.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
        echo "$version"
    else
        echo "not_installed"
    fi
}

# Function to get latest release info from GitHub
get_latest_release() {
    print_status "Fetching latest release information from GitHub..."
    
    # Use GitHub API to get latest release
    local response=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        print_error "Failed to fetch release information"
        return 1
    fi
    
    # Extract version and download URL
    local version=$(echo "$response" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    local download_url=$(echo "$response" | grep -o '"browser_download_url": "[^"]*\.dmg"' | head -1 | cut -d'"' -f4)
    
    if [ -z "$version" ] || [ -z "$download_url" ]; then
        print_error "Could not parse release information"
        return 1
    fi
    
    echo "$version|$download_url"
}

# Function to compare versions
compare_versions() {
    local version1=$1
    local version2=$2
    
    # Remove 'v' prefix if present
    version1=${version1#v}
    version2=${version2#v}
    
    # Handle development versions
    if [[ "$version1" == *"-dev"* ]] && [[ "$version2" == *"-dev"* ]]; then
        # Both are dev versions, compare normally
        if [ "$version1" = "$version2" ]; then
            return 0  # equal
        elif [ "$version1" \> "$version2" ]; then
            return 1  # version1 is newer
        else
            return 2  # version2 is newer
        fi
    elif [[ "$version1" == *"-dev"* ]]; then
        return 2  # version2 is newer (stable vs dev)
    elif [[ "$version2" == *"-dev"* ]]; then
        return 1  # version1 is newer (stable vs dev)
    else
        # Standard version comparison
        if [ "$version1" = "$version2" ]; then
            return 0  # equal
        elif [ "$version1" \> "$version2" ]; then
            return 1  # version1 is newer
        else
            return 2  # version2 is newer
        fi
    fi
}

# Function to download and install update
download_and_install() {
    local version=$1
    local download_url=$2
    
    print_status "Downloading version $version..."
    
    # Create downloads directory if it doesn't exist
    mkdir -p "$DOWNLOADS_DIR"
    
    # Download the file
    local filename="Ito-$version.dmg"
    local filepath="$DOWNLOADS_DIR/$filename"
    
    if curl -L -o "$filepath" "$download_url"; then
        print_success "Download completed: $filepath"
        
        # Verify the download
        if [ -f "$filepath" ] && [ -s "$filepath" ]; then
            print_status "Download verified successfully"
            
            # Create backup of current installation
            if [ -d "/Applications/Ito.app" ]; then
                print_status "Creating backup of current installation..."
                mkdir -p "$BACKUP_DIR"
                local backup_name="Ito-backup-$(date +%Y%m%d-%H%M%S).app"
                cp -R "/Applications/Ito.app" "$BACKUP_DIR/$backup_name"
                print_success "Backup created: $BACKUP_DIR/$backup_name"
            fi
            
            # Install the new version
            print_status "Installing new version..."
            
            # Mount the DMG
            local mount_point=$(hdiutil attach "$filepath" | grep "/Volumes/" | awk '{print $3}')
            
            if [ -n "$mount_point" ]; then
                # Copy the app to Applications
                if cp -R "$mount_point/Ito.app" "/Applications/"; then
                    print_success "Installation completed successfully!"
                    
                    # Unmount the DMG
                    hdiutil detach "$mount_point" >/dev/null 2>&1
                    
                    # Clean up downloaded file
                    rm "$filepath"
                    
                    log_message "Successfully updated Ito to version $version"
                    return 0
                else
                    print_error "Failed to copy application to /Applications"
                    hdiutil detach "$mount_point" >/dev/null 2>&1
                    return 1
                fi
            else
                print_error "Failed to mount DMG file"
                return 1
            fi
        else
            print_error "Download verification failed"
            return 1
        fi
    else
        print_error "Failed to download file"
        return 1
    fi
}

# Function to show update information
show_update_info() {
    local current_version=$1
    local latest_version=$2
    local download_url=$3
    
    echo
    print_status "Update Information:"
    echo "  Current Version: $current_version"
    echo "  Latest Version:  $latest_version"
    echo "  Download URL:    $download_url"
    echo
}

# Function to check for updates
check_for_updates() {
    print_status "Checking for Ito binary updates..."
    
    # Get current version
    local current_version=$(get_current_version)
    print_status "Current version: $current_version"
    
    # Get latest release
    local release_info=$(get_latest_release)
    if [ $? -ne 0 ]; then
        print_error "Failed to get latest release information"
        return 1
    fi
    
    local latest_version=$(echo "$release_info" | cut -d'|' -f1)
    local download_url=$(echo "$release_info" | cut -d'|' -f2)
    
    print_status "Latest version: $latest_version"
    
    # Compare versions
    compare_versions "$current_version" "$latest_version"
    local comparison_result=$?
    
    case $comparison_result in
        0)
            print_success "You have the latest version ($current_version)"
            return 0
            ;;
        1)
            print_warning "Your version ($current_version) is newer than the latest release ($latest_version)"
            print_warning "This might be a development version or pre-release"
            return 0
            ;;
        2)
            print_status "New version available: $latest_version"
            show_update_info "$current_version" "$latest_version" "$download_url"
            
            # Ask for confirmation
            echo -e "${YELLOW}Do you want to update to version $latest_version? (y/N)${NC}"
            read -r response
            
            if [[ "$response" =~ ^[Yy]$ ]]; then
                download_and_install "$latest_version" "$download_url"
                return $?
            else
                print_status "Update cancelled by user"
                return 0
            fi
            ;;
    esac
}

# Function to show help
show_help() {
    echo "Ito Binary Update Checker"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  check     Check for updates (default)"
    echo "  install   Force install latest version"
    echo "  status    Show current version status"
    echo "  help      Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Check for updates"
    echo "  $0 check              # Check for updates"
    echo "  $0 install            # Force install latest"
    echo "  $0 status             # Show version status"
}

# Function to show status
show_status() {
    local current_version=$(get_current_version)
    local release_info=$(get_latest_release 2>/dev/null)
    
    echo "Current Status:"
    echo "  Installed Version: $current_version"
    
    if [ $? -eq 0 ]; then
        local latest_version=$(echo "$release_info" | cut -d'|' -f1)
        echo "  Latest Version:    $latest_version"
        
        compare_versions "$current_version" "$latest_version"
        local comparison_result=$?
        
        case $comparison_result in
            0)
                echo "  Status:           Up to date"
                ;;
            1)
                echo "  Status:           Ahead of latest (dev/pre-release)"
                ;;
            2)
                echo "  Status:           Update available"
                ;;
        esac
    else
        echo "  Latest Version:    Unable to fetch"
        echo "  Status:           Unknown"
    fi
}

# Function to force install latest
force_install() {
    print_status "Force installing latest version..."
    
    local release_info=$(get_latest_release)
    if [ $? -ne 0 ]; then
        print_error "Failed to get latest release information"
        return 1
    fi
    
    local latest_version=$(echo "$release_info" | cut -d'|' -f1)
    local download_url=$(echo "$release_info" | cut -d'|' -f2)
    
    download_and_install "$latest_version" "$download_url"
    return $?
}

# Main function
main() {
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    # Parse command line arguments
    local command=${1:-check}
    
    case $command in
        check)
            check_for_updates
            ;;
        install)
            force_install
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
