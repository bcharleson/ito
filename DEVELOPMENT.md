# Ito Development Guide

This guide covers the development setup and workflow for contributing to the Ito project.

## 🚀 Quick Start

### Prerequisites

1. **Install Rust** (required for native components):

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Install Bun** (if not already installed):

   ```bash
   curl -fsSL https://bun.sh/install | bash
   ```

3. **Install GitHub CLI** (optional, for easier PR management):
   ```bash
   brew install gh
   ```

### Initial Setup

1. **Clone your fork**:

   ```bash
   git clone https://github.com/bcharleson/ito.git
   cd ito
   ```

2. **Set up remotes** (already done in your case):

   ```bash
   git remote rename origin upstream
   git remote add origin https://github.com/bcharleson/ito.git
   ```

3. **Install dependencies**:

   ```bash
   bun install
   ```

4. **Build native components**:

   ```bash
   ./build-binaries.sh
   ```

5. **Set up the server** (required for transcription):
   ```bash
   cd server
   cp .env.example .env
   # Edit .env with your API keys
   bun install
   bun run local-db-up
   bun run db:migrate
   bun run dev
   ```

## 📜 Development Scripts

We've created two main scripts to streamline your development workflow:

### 1. Update Script (`./scripts/update-ito.sh`)

Checks for new releases from the upstream repository and updates your fork.

**Usage:**

```bash
./scripts/update-ito.sh
```

**What it does:**

- Checks for new releases from upstream
- Compares versions and prompts for confirmation
- Creates a backup branch before updating
- Merges upstream changes
- Updates dependencies
- Rebuilds native components (if Rust is available)
- Cleans up temporary files

### 2. Development Workflow Script (`./scripts/dev-workflow.sh`)

Manages the entire development workflow from feature creation to PR submission.

**Usage:**

```bash
./scripts/dev-workflow.sh <command> [options]
```

**Available commands:**

#### Sync with Upstream

```bash
./scripts/dev-workflow.sh sync
```

Syncs your fork with the latest changes from the upstream repository.

#### Create Feature Branch

```bash
./scripts/dev-workflow.sh create-feature "add dark mode"
```

Creates a new feature branch from the latest upstream changes.

#### Commit Changes

```bash
./scripts/dev-workflow.sh commit feat "add dark mode support"
```

Commits changes using conventional commit format.

**Commit types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance tasks

#### Push Changes

```bash
./scripts/dev-workflow.sh push
./scripts/dev-workflow.sh push --force  # Force push if needed
```

#### Run Tests

```bash
./scripts/dev-workflow.sh test
```

Runs linting, tests, and build checks.

#### Create Pull Request

```bash
./scripts/dev-workflow.sh create-pr "Add dark mode support" "This PR adds dark mode..."
```

#### Show Status

```bash
./scripts/dev-workflow.sh status
```

Shows current branch, uncommitted changes, and recent commits.

#### Cleanup Feature Branch

```bash
./scripts/dev-workflow.sh cleanup feature/add-dark-mode
```

Deletes a feature branch after PR is merged.

## 🔄 Development Workflow

### 1. Start a New Feature

```bash
# Sync with upstream first
./scripts/dev-workflow.sh sync

# Create a feature branch
./scripts/dev-workflow.sh create-feature "add keyboard shortcuts"

# Make your changes...
# Edit files, add features, etc.
```

### 2. Commit Your Changes

```bash
# Commit with conventional commit format
./scripts/dev-workflow.sh commit feat "add customizable keyboard shortcuts"

# Push to your fork
./scripts/dev-workflow.sh push
```

### 3. Test Your Changes

```bash
# Run all tests and checks
./scripts/dev-workflow.sh test
```

### 4. Create a Pull Request

```bash
# Create PR to upstream repository
./scripts/dev-workflow.sh create-pr "Add customizable keyboard shortcuts" "This PR adds the ability to customize keyboard shortcuts..."
```

### 5. After PR is Merged

```bash
# Clean up the feature branch
./scripts/dev-workflow.sh cleanup feature/add-keyboard-shortcuts

# Sync with upstream to get your changes
./scripts/dev-workflow.sh sync
```

## 🛠️ Development Environment

### Running the Application

1. **Start the server** (in one terminal):

   ```bash
   cd server
   bun run dev
   ```

2. **Start the application** (in another terminal):
   ```bash
   bun run dev
   ```

### Building for Production

```bash
# Build for macOS
bun run build:mac

# Build unpacked for testing
bun run build:unpack
```

### Code Quality

```bash
# Run linting
bun run lint

# Fix linting issues
bun run lint:fix

# Format code
bun run format
```

## 📁 Project Structure

```
ito/
├── app/                    # Electron renderer (React frontend)
│   ├── components/         # React components
│   ├── store/             # Zustand state management
│   └── styles/            # TailwindCSS styles
├── lib/                   # Shared library code
│   ├── main/              # Electron main process
│   ├── preload/           # Preload scripts & IPC
│   └── media/             # Audio/keyboard native interfaces
├── native/                # Native components (Rust/Swift)
├── server/                # gRPC transcription server
├── scripts/               # Development scripts
│   ├── update-ito.sh      # Update script
│   ├── dev-workflow.sh    # Development workflow
│   └── setup-scripts.sh   # Setup script
└── resources/             # Build resources & assets
```

## 🔧 Configuration

### Environment Variables

Create `.env` files in both the root and server directories:

**Root `.env`:**

```env
# Add any client-side environment variables
```

**Server `.env`:**

```env
# Database
DATABASE_URL=postgresql://localhost:5432/ito

# Auth0
AUTH0_DOMAIN=your-domain.auth0.com
AUTH0_CLIENT_ID=your-client-id
AUTH0_CLIENT_SECRET=your-client-secret

# Groq API
GROQ_API_KEY=your-groq-api-key

# Other services...
```

### Git Configuration

Ensure your git is configured for your fork:

```bash
git remote -v
# Should show:
# origin  https://github.com/bcharleson/ito.git (fetch)
# origin  https://github.com/bcharleson/ito.git (push)
# upstream        https://github.com/heyito/ito.git (fetch)
# upstream        https://github.com/heyito/ito.git (push)
```

## 🚨 Troubleshooting

### Common Issues

1. **Rust not installed**: Install Rust with `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

2. **Server not running**: Make sure to start the server with `cd server && bun run dev`

3. **Merge conflicts**: Resolve conflicts manually, then continue with the script

4. **Build failures**: Check that all dependencies are installed and Rust is available

### Getting Help

- Check the [main Ito repository](https://github.com/heyito/ito) for issues and discussions
- Review the [original README](README.md) for detailed setup instructions
- Check the server README in `server/README.md` for server-specific issues

## 📝 Contributing Guidelines

### Before Contributing

1. **Sync with upstream** to ensure you're working with the latest code
2. **Create a feature branch** for your changes
3. **Follow the existing code style** (use the provided linting rules)
4. **Test your changes** thoroughly
5. **Write clear commit messages** using conventional commit format

### Pull Request Process

1. **Create a feature branch** from the latest upstream
2. **Make your changes** and test thoroughly
3. **Commit with conventional format**: `type: description`
4. **Push to your fork** and create a PR to upstream
5. **Wait for review** and address any feedback
6. **Clean up** after the PR is merged

### Code Style

- Use TypeScript for all new code
- Follow the existing ESLint and Prettier configurations
- Write tests for new features
- Update documentation for API changes

## 🎯 Quick Reference

### Daily Workflow

```bash
# Check for updates
./scripts/update-ito.sh

# Start development
./scripts/dev-workflow.sh create-feature "my-feature"
# ... make changes ...
./scripts/dev-workflow.sh commit feat "add my feature"
./scripts/dev-workflow.sh push
./scripts/dev-workflow.sh test
./scripts/dev-workflow.sh create-pr "Add my feature"
```

### Useful Aliases

Add these to your `~/.zshrc` or `~/.bashrc`:

```bash
alias ito-update='./scripts/update-ito.sh'
alias ito-dev='./scripts/dev-workflow.sh'
alias ito-sync='./scripts/dev-workflow.sh sync'
alias ito-test='./scripts/dev-workflow.sh test'
alias ito-status='./scripts/dev-workflow.sh status'
```

---

Happy contributing! 🚀
