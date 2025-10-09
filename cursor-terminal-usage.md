# Cursor Terminal Usage Guide

## Basic Commands

### Opening Projects
```bash
# Open current directory
cursor .

# Open specific directory
cursor /path/to/your/project

# Open specific file
cursor filename.py

# Open multiple files
cursor file1.js file2.py file3.html
```

### Advanced Usage
```bash
# Open in new window
cursor --new-window /path/to/project

# Open with specific workspace settings
cursor --user-data-dir /custom/path /project/path

# Wait for files to be closed before returning
cursor --wait file.txt

# Open file at specific line and column
cursor --goto file.py:25:10
```

## Integration with Terminal Workflow

### 1. **Quick File Editing**
```bash
# Edit configuration files
cursor ~/.bashrc
cursor /etc/nginx/nginx.conf

# Edit project files
cursor src/main.py
cursor package.json
```

### 2. **Project Navigation**
```bash
# Navigate and open
cd ~/projects/my-app
cursor .

# Open from anywhere
cursor ~/projects/my-app
```

### 3. **Git Integration**
```bash
# Open repository
git clone https://github.com/user/repo.git
cd repo
cursor .

# Open specific branch files
git checkout feature-branch
cursor src/
```

## Terminal Shortcuts in Cursor

### Opening Terminal in Cursor
- `Ctrl + \`` - Toggle integrated terminal
- `Ctrl + Shift + \`` - New terminal instance
- `Ctrl + Shift + P` → "Terminal: Create New Terminal"

### Terminal Navigation
- `Ctrl + PageUp/PageDown` - Switch between terminals
- `Ctrl + Shift + C` - Copy from terminal
- `Ctrl + Shift + V` - Paste to terminal

## Environment Variables

### Setting up PATH
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
# Add Cursor to PATH
export PATH="$PATH:/usr/local/bin"

# Create alias for convenience
alias c='cursor'
alias code='cursor'  # If migrating from VS Code
```

### Cursor-specific Environment Variables
```bash
# Custom user data directory
export CURSOR_USER_DATA_DIR="$HOME/.cursor-custom"

# Disable GPU acceleration if needed
export CURSOR_DISABLE_GPU=1

# Enable verbose logging
export CURSOR_VERBOSE=1
```

## Remote Development

### SSH Integration
```bash
# Connect to remote server
cursor --remote ssh-remote+username@hostname /remote/path

# With custom SSH config
cursor --remote ssh-remote+my-server /home/user/project
```

### Docker Integration
```bash
# Open project in Docker container
cursor --remote container+container-name /workspace

# Attach to running container
docker exec -it container-name bash
cursor .
```

## Troubleshooting

### Common Issues
1. **Command not found**: Ensure Cursor is in your PATH
2. **Permission denied**: Check file permissions with `ls -la`
3. **Display issues**: Set `DISPLAY` variable for X11 forwarding

### Debug Commands
```bash
# Check Cursor installation
which cursor
cursor --version

# Test with verbose output
cursor --verbose .

# Check system compatibility
ldd /usr/local/bin/cursor
```

## Workflow Examples

### Web Development
```bash
# Start new React project
npx create-react-app my-app
cd my-app
cursor .
npm start  # In Cursor's integrated terminal
```

### Python Development
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate
cursor .
pip install -r requirements.txt
```

### System Administration
```bash
# Edit system configs
sudo cursor /etc/hosts
sudo cursor /etc/nginx/sites-available/default

# View logs while editing
tail -f /var/log/nginx/error.log &
cursor /etc/nginx/nginx.conf
```