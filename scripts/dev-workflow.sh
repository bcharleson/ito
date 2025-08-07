#!/bin/bash

# Ito Development Workflow Script
# This script helps with the development workflow for contributing to Ito

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
UPSTREAM_REPO="heyito/ito"
FORK_REPO="bcharleson/ito"
MAIN_BRANCH="dev"
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

print_dev() {
    echo -e "${PURPLE}[DEV]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking development prerequisites..."
    
    if ! command_exists git; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi
    
    if ! command_exists bun; then
        print_error "Bun is not installed. Please install Bun first."
        exit 1
    fi
    
    if ! command_exists gh; then
        print_warning "GitHub CLI is not installed. Install it for easier PR management."
        print_status "Install with: brew install gh"
    fi
    
    print_success "Development prerequisites check completed"
}

# Function to sync with upstream
sync_with_upstream() {
    print_status "Syncing with upstream repository..."
    
    # Fetch latest changes
    git fetch upstream --quiet
    
    # Check if we're on the main branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]; then
        print_warning "You're not on the main branch ($MAIN_BRANCH). Switching..."
        git checkout "$MAIN_BRANCH" --quiet
    fi
    
    # Merge upstream changes
    if git merge "upstream/$MAIN_BRANCH" --no-edit; then
        print_success "Successfully synced with upstream"
    else
        print_error "Merge conflict detected. Please resolve conflicts manually."
        return 1
    fi
    
    # Push to your fork
    git push origin "$MAIN_BRANCH" --quiet
    print_success "Pushed changes to your fork"
}

# Function to create feature branch
create_feature_branch() {
    local feature_name=$1
    
    if [ -z "$feature_name" ]; then
        print_error "Feature name is required"
        print_status "Usage: $0 create-feature <feature-name>"
        exit 1
    fi
    
    # Sanitize feature name
    FEATURE_NAME=$(echo "$feature_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    
    print_status "Creating feature branch: $FEATURE_NAME"
    
    # Ensure we're on main branch and synced
    git checkout "$MAIN_BRANCH" --quiet
    sync_with_upstream
    
    # Create and switch to feature branch
    git checkout -b "feature/$FEATURE_NAME" --quiet
    
    print_success "Feature branch 'feature/$FEATURE_NAME' created and checked out"
    print_dev "You can now start making your changes!"
}

# Function to commit changes
commit_changes() {
    local commit_type=$1
    local message=$2
    
    if [ -z "$commit_type" ] || [ -z "$message" ]; then
        print_error "Commit type and message are required"
        print_status "Usage: $0 commit <type> <message>"
        print_status "Types: feat, fix, docs, style, refactor, test, chore"
        exit 1
    fi
    
    print_status "Committing changes..."
    
    # Check if there are changes to commit
    if git diff --quiet && git diff --cached --quiet; then
        print_warning "No changes to commit"
        return 0
    fi
    
    # Add all changes
    git add .
    
    # Create commit message
    COMMIT_MSG="$commit_type: $message"
    
    # Commit
    if git commit -m "$COMMIT_MSG"; then
        print_success "Changes committed: $COMMIT_MSG"
    else
        print_error "Failed to commit changes"
        return 1
    fi
}

# Function to push changes
push_changes() {
    local force=$1
    
    print_status "Pushing changes to your fork..."
    
    CURRENT_BRANCH=$(git branch --show-current)
    
    if [ "$force" = "true" ]; then
        git push origin "$CURRENT_BRANCH" --force-with-lease
        print_warning "Force pushed changes"
    else
        git push origin "$CURRENT_BRANCH"
        print_success "Pushed changes to origin/$CURRENT_BRANCH"
    fi
}

# Function to create pull request
create_pull_request() {
    local title=$1
    local description=$2
    
    if [ -z "$title" ]; then
        print_error "PR title is required"
        print_status "Usage: $0 create-pr <title> [description]"
        exit 1
    fi
    
    print_status "Creating pull request..."
    
    CURRENT_BRANCH=$(git branch --show-current)
    
    if [ "$CURRENT_BRANCH" = "$MAIN_BRANCH" ]; then
        print_error "Cannot create PR from main branch. Switch to a feature branch first."
        exit 1
    fi
    
    # Push changes if not already pushed
    if ! git ls-remote --exit-code origin "$CURRENT_BRANCH" >/dev/null 2>&1; then
        push_changes
    fi
    
    # Create PR using GitHub CLI if available
    if command_exists gh; then
        if [ -n "$description" ]; then
            gh pr create --title "$title" --body "$description" --base "$MAIN_BRANCH"
        else
            gh pr create --title "$title" --base "$MAIN_BRANCH"
        fi
        print_success "Pull request created!"
    else
        print_status "GitHub CLI not available. Please create PR manually:"
        echo "  URL: https://github.com/$FORK_REPO/compare/$MAIN_BRANCH...$CURRENT_BRANCH"
        echo "  Title: $title"
        if [ -n "$description" ]; then
            echo "  Description: $description"
        fi
    fi
}

# Function to test changes
test_changes() {
    print_status "Running tests and checks..."
    
    # Install dependencies
    print_status "Installing dependencies..."
    bun install
    
    # Run linting
    print_status "Running linting..."
    if bun run lint; then
        print_success "Linting passed"
    else
        print_error "Linting failed. Run 'bun run lint:fix' to auto-fix issues."
        return 1
    fi
    
    # Run tests if available
    if grep -q '"test"' package.json; then
        print_status "Running tests..."
        if bun test; then
            print_success "Tests passed"
        else
            print_error "Tests failed"
            return 1
        fi
    else
        print_warning "No tests configured"
    fi
    
    # Build check
    print_status "Checking build..."
    if bun run build:unpack; then
        print_success "Build check passed"
    else
        print_error "Build failed"
        return 1
    fi
    
    print_success "All checks passed!"
}

# Function to cleanup feature branch
cleanup_feature_branch() {
    local branch_name=$1
    
    if [ -z "$branch_name" ]; then
        print_error "Branch name is required"
        print_status "Usage: $0 cleanup <branch-name>"
        exit 1
    fi
    
    print_status "Cleaning up feature branch: $branch_name"
    
    # Switch to main branch
    git checkout "$MAIN_BRANCH" --quiet
    
    # Delete local branch
    if git branch -D "$branch_name" 2>/dev/null; then
        print_success "Deleted local branch: $branch_name"
    else
        print_warning "Local branch '$branch_name' not found or already deleted"
    fi
    
    # Delete remote branch
    if git push origin --delete "$branch_name" 2>/dev/null; then
        print_success "Deleted remote branch: $branch_name"
    else
        print_warning "Remote branch '$branch_name' not found or already deleted"
    fi
}

# Function to show status
show_status() {
    print_status "Current development status:"
    echo
    
    CURRENT_BRANCH=$(git branch --show-current)
    echo "Current branch: $CURRENT_BRANCH"
    
    # Show uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Uncommitted changes:"
        git status --short
    else
        echo "No uncommitted changes"
    fi
    
    # Show recent commits
    echo
    echo "Recent commits:"
    git log --oneline -5
    
    # Show remote status
    echo
    echo "Remote status:"
    git remote -v
}

# Function to show help
show_help() {
    echo "🚀 Ito Development Workflow"
    echo "=========================="
    echo
    echo "Available commands:"
    echo
    echo "  sync                    - Sync with upstream repository"
    echo "  create-feature <name>   - Create a new feature branch"
    echo "  commit <type> <msg>     - Commit changes with conventional commit format"
    echo "  push [--force]          - Push changes to your fork"
    echo "  test                    - Run tests and checks"
    echo "  create-pr <title> [desc] - Create a pull request"
    echo "  cleanup <branch>        - Clean up a feature branch"
    echo "  status                  - Show current development status"
    echo "  help                    - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 create-feature 'add dark mode'"
    echo "  $0 commit feat 'add dark mode support'"
    echo "  $0 push"
    echo "  $0 create-pr 'Add dark mode support' 'This PR adds dark mode...'"
    echo "  $0 cleanup feature/add-dark-mode"
    echo
}

# Main function
main() {
    local command=$1
    shift || true
    
    # Check prerequisites
    check_prerequisites
    
    case "$command" in
        "sync")
            sync_with_upstream
            ;;
        "create-feature")
            create_feature_branch "$1"
            ;;
        "commit")
            commit_changes "$1" "$2"
            ;;
        "push")
            if [ "$1" = "--force" ]; then
                push_changes "true"
            else
                push_changes "false"
            fi
            ;;
        "test")
            test_changes
            ;;
        "create-pr")
            create_pull_request "$1" "$2"
            ;;
        "cleanup")
            cleanup_feature_branch "$1"
            ;;
        "status")
            show_status
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
