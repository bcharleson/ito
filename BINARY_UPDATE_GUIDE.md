# 🔄 Ito Binary Update System

This guide explains how to use the binary update system to keep your Ito app up-to-date with the latest releases.

## 🚀 Quick Start

### Manual Check
```bash
# Check for updates (with confirmation prompt)
./scripts/auto-update-check.sh

# Check current version status
./scripts/check-binary-updates.sh status
```

### Automatic Updates
```bash
# Set up automatic daily checking
./scripts/setup-auto-updates.sh
```

## 📋 Available Scripts

### 1. `check-binary-updates.sh` - Main Update Checker

**Usage:**
```bash
./scripts/check-binary-updates.sh [command]
```

**Commands:**
- `check` - Check for updates (default)
- `install` - Force install latest version
- `status` - Show current version status
- `help` - Show help message

**Examples:**
```bash
# Check for updates with confirmation
./scripts/check-binary-updates.sh

# Force install latest version
./scripts/check-binary-updates.sh install

# Show current version status
./scripts/check-binary-updates.sh status
```

### 2. `auto-update-check.sh` - Simple Update Checker

**Usage:**
```bash
./scripts/auto-update-check.sh
```

This script provides a simple interface for checking updates with timestamps and logging.

### 3. `setup-auto-updates.sh` - Automatic Update Setup

**Usage:**
```bash
./scripts/setup-auto-updates.sh
```

This interactive script helps you set up automatic update checking.

## ⚙️ Setup Options

### Option 1: Daily Updates (Recommended)
- Checks for updates every day at 9:00 AM
- Good for staying current with the latest releases

### Option 2: Weekly Updates
- Checks for updates every Sunday at 9:00 AM
- Good balance between staying current and not checking too frequently

### Option 3: Manual Only
- No automatic checking
- Run `./scripts/auto-update-check.sh` when you want to check

## 🔧 How It Works

### Version Detection
1. **Current Version**: Reads from `/Applications/Ito.app/Contents/Info.plist`
2. **Latest Version**: Fetches from GitHub API (`heyito/ito` repository)
3. **Comparison**: Intelligently compares versions (handles dev versions)

### Update Process
1. **Check**: Compares current vs latest version
2. **Confirm**: Prompts for user confirmation
3. **Download**: Downloads the latest `.dmg` file
4. **Backup**: Creates backup of current installation
5. **Install**: Mounts DMG and copies to Applications
6. **Cleanup**: Removes downloaded files

### Safety Features
- ✅ **Backup Creation**: Always backs up current version
- ✅ **Human Confirmation**: Never auto-updates without permission
- ✅ **Download Verification**: Verifies file integrity
- ✅ **Error Handling**: Graceful failure with clear messages
- ✅ **Logging**: All actions logged to `binary-updates.log`

## 📊 Monitoring

### View Logs
```bash
# View update logs
cat binary-updates.log

# View recent logs
tail -f binary-updates.log
```

### Check Status
```bash
# Check if automatic updates are enabled
crontab -l | grep auto-update-check

# Check current version
./scripts/check-binary-updates.sh status
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. "Permission Denied"
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

#### 2. "App Not Found"
- Ensure Ito is installed in `/Applications/Ito.app`
- The script will show "not_installed" if not found

#### 3. "Network Error"
- Check your internet connection
- GitHub API might be temporarily unavailable

#### 4. "Download Failed"
- Check available disk space
- Verify network connection
- Try running the script again

### Manual Recovery

If automatic updates fail, you can:

1. **Check the logs**:
   ```bash
   cat binary-updates.log
   ```

2. **Manual download**:
   - Visit [GitHub releases](https://github.com/heyito/ito/releases)
   - Download the latest `.dmg` file
   - Install manually

3. **Restore from backup**:
   ```bash
   # List available backups
   ls -la backups/
   
   # Restore a backup
   cp -R backups/Ito-backup-YYYYMMDD-HHMMSS.app /Applications/Ito.app
   ```

## 🔒 Security Notes

### What the Script Does
- ✅ **Reads** your current app version
- ✅ **Downloads** new versions from GitHub
- ✅ **Installs** to `/Applications/`
- ✅ **Creates** backups before updates

### What the Script Doesn't Do
- ❌ **Never** auto-updates without confirmation
- ❌ **Never** sends data anywhere
- ❌ **Never** modifies system settings
- ❌ **Never** requires admin privileges (beyond app installation)

### Privacy
- All version checking uses public GitHub API
- No personal data is transmitted
- All logs are stored locally

## 📝 Configuration

### Customizing Check Frequency

To change the automatic check frequency:

1. **Remove current cron job**:
   ```bash
   crontab -l | grep -v "auto-update-check.sh" | crontab -
   ```

2. **Add custom cron job**:
   ```bash
   # Example: Check every 3 days at 10 AM
   (crontab -l 2>/dev/null; echo "0 10 */3 * * cd $PWD && ./scripts/auto-update-check.sh >> binary-updates.log 2>&1") | crontab -
   ```

### Customizing Log Location

Edit the scripts to change log file location:
```bash
# In check-binary-updates.sh, change:
LOG_FILE="$PROJECT_ROOT/binary-updates.log"

# To your preferred location:
LOG_FILE="/path/to/your/logs/ito-updates.log"
```

## 🎯 Best Practices

### For Regular Users
1. **Set up daily checking** for the latest features
2. **Review logs occasionally** to ensure everything is working
3. **Keep backups** in case you need to rollback

### For Developers
1. **Use manual checking** to avoid conflicts with development
2. **Monitor the repository** for release announcements
3. **Test updates** in a development environment first

## 📞 Support

If you encounter issues:

1. **Check the logs**: `cat binary-updates.log`
2. **Verify your setup**: `./scripts/check-binary-updates.sh status`
3. **Try manual update**: `./scripts/check-binary-updates.sh install`
4. **Check GitHub**: [Ito Releases](https://github.com/heyito/ito/releases)

## 🔄 Integration with Development

When you're ready to contribute:

1. **Use the development scripts** we created earlier
2. **Sync with upstream** using `./scripts/dev-workflow.sh sync`
3. **Create feature branches** for your contributions
4. **Test thoroughly** before submitting pull requests

The binary update system is designed to work alongside your development workflow without conflicts.
