#!/bin/bash

# Ito Update Script
# This script checks for new releases from the upstream repository and updates your fork

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
UPSTREAM_REPO="heyito/ito"
UPSTREAM_BRANCH="dev"
CURRENT_BRANCH=$(git branch --show-current)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists git; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi
    
    if ! command_exists bun; then
        print_error "Bun is not installed. Please install Bun first."
        exit 1
    fi
    
    if ! command_exists rustc; then
        print_warning "Rust is not installed. You'll need to install it for building native components."
        print_status "Install Rust with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to get latest release info
get_latest_release() {
    # Fetch latest tags from upstream
    git fetch upstream --tags --quiet
    
    # Get the latest tag
    LATEST_TAG=$(git ls-remote --tags upstream | grep -v "{}" | tail -n 1 | cut -f2 | sed 's/refs\/tags\///')
    
    if [ -z "$LATEST_TAG" ]; then
        return 1
    fi
    
    echo "$LATEST_TAG"
}

# Function to get current version
get_current_version() {
    # Try to get current version from git tag
    CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo "$CURRENT_TAG"
}

# Function to compare versions
compare_versions() {
    local version1=$1
    local version2=$2
    
    # Remove 'v' prefix if present
    version1=${version1#v}
    version2=${version2#v}
    
    # Handle development versions (e.g., 0.2.5-dev)
    # Strip development suffixes for comparison
    version1=$(echo "$version1" | sed 's/-dev$//' | sed 's/-alpha.*$//' | sed 's/-beta.*$//' | sed 's/-rc.*$//')
    version2=$(echo "$version2" | sed 's/-dev$//' | sed 's/-alpha.*$//' | sed 's/-beta.*$//' | sed 's/-rc.*$//')
    
    # Split version into parts
    IFS='.' read -ra V1 <<< "$version1"
    IFS='.' read -ra V2 <<< "$version2"
    
    # Compare each part
    for i in {0..2}; do
        local num1=${V1[$i]:-0}
        local num2=${V2[$i]:-0}
        
        # Convert to integers, defaulting to 0 if not numeric
        if [[ "$num1" =~ ^[0-9]+$ ]]; then
            num1_int=$num1
        else
            num1_int=0
        fi
        
        if [[ "$num2" =~ ^[0-9]+$ ]]; then
            num2_int=$num2
        else
            num2_int=0
        fi
        
        if [ "$num1_int" -gt "$num2_int" ]; then
            return 1  # version1 is newer
        elif [ "$num1_int" -lt "$num2_int" ]; then
            return 2  # version2 is newer
        fi
    done
    
    return 0  # versions are equal
}

# Function to backup current state
backup_current_state() {
    print_status "Creating backup of current state..."
    
    BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$BACKUP_BRANCH" --quiet
    
    print_success "Backup created on branch: $BACKUP_BRANCH"
    echo "$BACKUP_BRANCH"
}

# Function to perform update
perform_update() {
    local backup_branch=$1
    
    print_status "Starting update process..."
    
    # Switch back to original branch
    git checkout "$CURRENT_BRANCH" --quiet
    
    # Fetch latest changes from upstream
    print_status "Fetching latest changes from upstream..."
    git fetch upstream --quiet
    
    # Merge upstream changes
    print_status "Merging upstream changes..."
    if git merge "upstream/$UPSTREAM_BRANCH" --no-edit; then
        print_success "Successfully merged upstream changes"
    else
        print_error "Merge conflict detected. Please resolve conflicts manually."
        print_status "You can switch to backup branch with: git checkout $backup_branch"
        return 1
    fi
    
    # Update dependencies
    print_status "Updating dependencies..."
    bun install
    
    # Build native components if Rust is available
    if command_exists rustc; then
        print_status "Building native components..."
        if ./build-binaries.sh; then
            print_success "Native components built successfully"
        else
            print_warning "Failed to build native components. You may need to install Rust."
        fi
    else
        print_warning "Skipping native component build (Rust not installed)"
    fi
    
    # Clean up
    print_status "Cleaning up..."
    bun run lint:fix 2>/dev/null || true
    git gc --prune=now --quiet
    
    print_success "Update completed successfully!"
}

# Function to cleanup backup
cleanup_backup() {
    local backup_branch=$1
    
    print_status "Cleaning up backup branch..."
    git branch -D "$backup_branch" 2>/dev/null || true
    print_success "Backup cleaned up"
}

# Function to show update summary
show_update_summary() {
    local current_version=$1
    local latest_version=$2
    local backup_branch=$3
    
    echo
    echo "=========================================="
    echo "           UPDATE SUMMARY"
    echo "=========================================="
    echo "Current version: $current_version"
    echo "Latest version:  $latest_version"
    echo "Backup branch:   $backup_branch"
    echo "=========================================="
    echo
}

# Main function
main() {
    echo "🚀 Ito Update Script"
    echo "===================="
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Get current and latest versions
    CURRENT_VERSION=$(get_current_version)
    
    print_status "Fetching latest release information..."
    LATEST_VERSION=$(get_latest_release)
    
    if [ $? -ne 0 ] || [ -z "$LATEST_VERSION" ]; then
        print_error "Failed to get latest version information"
        exit 1
    fi
    
    print_status "Current version: $CURRENT_VERSION"
    print_status "Latest version: $LATEST_VERSION"
    
    # Compare versions
    compare_versions "$CURRENT_VERSION" "$LATEST_VERSION"
    VERSION_COMPARISON=$?
    
    if [ $VERSION_COMPARISON -eq 0 ]; then
        print_success "You are already on the latest version!"
        exit 0
    elif [ $VERSION_COMPARISON -eq 1 ]; then
        print_warning "Your version appears to be newer than the latest release"
        print_status "This might indicate you're on a development branch"
    fi
    
    echo
    print_status "A newer version is available!"
    echo
    echo "Changes that will be applied:"
    echo "  - Merge latest changes from upstream"
    echo "  - Update dependencies"
    echo "  - Rebuild native components (if Rust is available)"
    echo "  - Clean up temporary files"
    echo
    
    # Ask for confirmation
    read -p "Do you want to proceed with the update? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Update cancelled"
        exit 0
    fi
    
    # Create backup
    BACKUP_BRANCH=$(backup_current_state)
    
    # Perform update
    if perform_update "$BACKUP_BRANCH"; then
        print_success "Update completed successfully!"
        
        # Ask if user wants to keep backup
        echo
        read -p "Do you want to keep the backup branch ($BACKUP_BRANCH)? (y/N): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            cleanup_backup "$BACKUP_BRANCH"
        else
            print_status "Backup branch '$BACKUP_BRANCH' kept for safety"
        fi
        
        show_update_summary "$CURRENT_VERSION" "$LATEST_VERSION" "$BACKUP_BRANCH"
        
        echo
        print_success "🎉 Update completed! You can now run 'bun run dev' to start the application."
        
    else
        print_error "Update failed. You can switch to backup with: git checkout $BACKUP_BRANCH"
        exit 1
    fi
}

# Run main function
main "$@"
