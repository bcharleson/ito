# 🔄 Safe Sync Guide for Ito Development

This guide explains how to safely sync with upstream changes without losing your development work.

## 🛡️ How Sync Protects Your Work

### 1. **Your Changes Are Never Lost**

- All your commits are permanently stored in Git history
- Even if conflicts occur, your work is always recoverable
- The sync script creates backup branches before any changes

### 2. **Safe Sync Process**

```bash
# The sync script does this automatically:
./scripts/dev-workflow.sh sync

# What happens behind the scenes:
# 1. Creates backup branch: backup-YYYYMMDD-HHMMSS
# 2. Fetches latest from upstream
# 3. Attempts to merge upstream changes
# 4. If conflicts: Stops and shows you how to resolve
# 5. If successful: Updates your fork
```

## 📊 Understanding Your Current State

### Your Repository Structure:

```
Your Fork (bcharleson/ito)
├── dev branch (your main branch)
│   ├── Your scripts commit (99ac976) ← YOUR WORK
│   └── Upstream commits (81bc180, etc.)
└── feature branches
    └── feature/test-feature (your test branch)
```

### Upstream Repository:

```
Main Repo (heyito/ito)
└── dev branch
    └── Original commits (81bc180, etc.) ← NO YOUR WORK
```

## 🔄 What Happens During Sync

### Scenario 1: No Conflicts (Most Common)

```bash
# If upstream has new commits that don't conflict:
./scripts/dev-workflow.sh sync

# Result: Your work + upstream work = merged successfully
```

### Scenario 2: Conflicts (Rare but Handled)

```bash
# If upstream changed the same files you changed:
./scripts/dev-workflow.sh sync

# Result: Script stops and shows you exactly what to do
# You manually resolve conflicts, then continue
```

## 🛠️ Step-by-Step Safe Sync Process

### Step 1: Check Current State

```bash
./scripts/dev-workflow.sh status
```

### Step 2: Create Backup (Automatic)

```bash
./scripts/dev-workflow.sh sync
# Script automatically creates: backup-20240807-143022
```

### Step 3: Handle Conflicts (If Any)

If conflicts occur, the script will show you:

```bash
# 1. Switch to backup branch (safe state)
git checkout backup-20240807-143022

# 2. Resolve conflicts manually
# Edit conflicted files, remove conflict markers

# 3. Continue sync
./scripts/dev-workflow.sh sync
```

## 🎯 Real-World Examples

### Example 1: Safe Sync (No Conflicts)

```bash
# You have: development scripts
# Upstream has: new features
# Result: Both work together perfectly

./scripts/dev-workflow.sh sync
# ✅ Success: Your scripts + upstream features merged
```

### Example 2: Conflict Resolution

```bash
# You modified: app/components/HomeKit.tsx
# Upstream modified: app/components/HomeKit.tsx
# Result: Git shows you exactly what to do

./scripts/dev-workflow.sh sync
# ⚠️ Conflict detected
# Script shows you how to resolve it
```

## 🔍 How to Check What Would Happen

### Before Syncing:

```bash
# See what upstream has that you don't
git fetch upstream
git log HEAD..upstream/dev --oneline

# See what you have that upstream doesn't
git log upstream/dev..HEAD --oneline
```

### Check for Potential Conflicts:

```bash
# See which files might conflict
git diff --name-only HEAD upstream/dev
```

## 🛡️ Recovery Options

### If Something Goes Wrong:

```bash
# 1. Switch to backup branch (always safe)
git checkout backup-YYYYMMDD-HHMMSS

# 2. Start over
git checkout dev
git reset --hard backup-YYYYMMDD-HHMMSS

# 3. Try sync again
./scripts/dev-workflow.sh sync
```

### If You Lose Track:

```bash
# See all your branches
git branch -a

# See your commits
git log --oneline --all --graph
```

## 📋 Best Practices

### 1. **Always Work on Feature Branches**

```bash
# Don't work directly on dev
./scripts/dev-workflow.sh create-feature "my-feature"
# Make changes on feature branch
./scripts/dev-workflow.sh commit feat "my changes"
```

### 2. **Sync Regularly**

```bash
# Sync before starting new work
./scripts/dev-workflow.sh sync

# Sync after upstream releases
./scripts/update-ito.sh
```

### 3. **Test After Sync**

```bash
# After syncing, test your changes still work
./scripts/dev-workflow.sh test
bun run dev
```

## 🚨 Emergency Recovery

### If You're Unsure:

```bash
# 1. Check what branch you're on
git branch --show-current

# 2. See recent commits
git log --oneline -5

# 3. See uncommitted changes
git status

# 4. If needed, reset to safe state
git checkout dev
git reset --hard origin/dev
```

### If You Need to Start Over:

```bash
# 1. Backup your work
git checkout -b emergency-backup

# 2. Reset to clean state
git checkout dev
git reset --hard upstream/dev

# 3. Re-apply your changes
git cherry-pick emergency-backup
```

## 🎯 Quick Reference

### Safe Sync Commands:

```bash
# Check status
./scripts/dev-workflow.sh status

# Safe sync
./scripts/dev-workflow.sh sync

# Check for updates
./scripts/update-ito.sh

# Create feature branch
./scripts/dev-workflow.sh create-feature "feature-name"
```

### Recovery Commands:

```bash
# List all branches (including backups)
git branch -a

# Switch to backup
git checkout backup-YYYYMMDD-HHMMSS

# Reset to safe state
git reset --hard origin/dev
```

---

**Remember**: Your work is always safe in Git. The sync scripts are designed to protect your changes and give you clear instructions if anything goes wrong.
