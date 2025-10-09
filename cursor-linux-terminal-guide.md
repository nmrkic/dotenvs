# Using Cursor in Linux Terminal

Yes, you can absolutely use Cursor in Linux terminal environments! Here's a comprehensive guide on how to install and use Cursor on Linux systems.

## Installation Methods

### Method 1: Download from Official Website (Recommended)

1. **Download the AppImage**:
   ```bash
   # Download the latest Cursor AppImage
   wget -O cursor.AppImage "https://downloader.cursor.sh/linux/appImage/x64"
   
   # Make it executable
   chmod +x cursor.AppImage
   
   # Move to a system directory (optional)
   sudo mv cursor.AppImage /usr/local/bin/cursor
   ```

2. **Create a desktop entry** (optional):
   ```bash
   cat > ~/.local/share/applications/cursor.desktop << EOF
   [Desktop Entry]
   Name=Cursor
   Comment=AI-powered code editor
   Exec=/usr/local/bin/cursor %F
   Icon=cursor
   Terminal=false
   Type=Application
   Categories=Development;TextEditor;
   MimeType=text/plain;
   EOF
   ```

### Method 2: Using Package Managers

#### For Ubuntu/Debian:
```bash
# Download the .deb package
wget -O cursor.deb "https://downloader.cursor.sh/linux/deb/x64"

# Install using dpkg
sudo dpkg -i cursor.deb

# Fix dependencies if needed
sudo apt-get install -f
```

#### For Arch Linux:
```bash
# Using AUR helper (yay)
yay -S cursor-bin

# Or manually from AUR
git clone https://aur.archlinux.org/cursor-bin.git
cd cursor-bin
makepkg -si
```

#### For Fedora/RHEL:
```bash
# Download RPM package
wget -O cursor.rpm "https://downloader.cursor.sh/linux/rpm/x64"

# Install using dnf
sudo dnf install cursor.rpm
```

## Command Line Usage

### Basic Commands

Once installed, you can use Cursor from the terminal:

```bash
# Open Cursor
cursor

# Open a specific file
cursor filename.py

# Open a directory/project
cursor /path/to/project

# Open current directory
cursor .

# Open multiple files
cursor file1.js file2.css file3.html

# Open with specific workspace
cursor --folder-uri /path/to/workspace
```

### Advanced Command Line Options

```bash
# Open in new window
cursor --new-window

# Wait for files to be closed before returning
cursor --wait

# Open file at specific line and column
cursor filename.py:25:10

# Diff two files
cursor --diff file1.txt file2.txt

# Install extensions from command line
cursor --install-extension ms-python.python

# List installed extensions
cursor --list-extensions

# Disable all extensions
cursor --disable-extensions

# Run in verbose mode
cursor --verbose
```

## Terminal Integration Tips

### 1. Shell Aliases
Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# Quick aliases for Cursor
alias c='cursor'
alias code='cursor'  # If migrating from VS Code
alias edit='cursor'

# Open current directory
alias c.='cursor .'

# Open with wait (useful for git commit messages)
alias cw='cursor --wait'
```

### 2. Git Integration
Set Cursor as your default Git editor:

```bash
# Set as git editor
git config --global core.editor "cursor --wait"

# For commit messages
git config --global sequence.editor "cursor --wait"
```

### 3. Environment Variables
```bash
# Add to your shell profile
export EDITOR="cursor --wait"
export VISUAL="cursor --wait"
```

## Terminal-Specific Workflows

### 1. Integrated Terminal Usage
- Cursor has a built-in terminal accessible via `Ctrl+`` (backtick)
- You can split terminals and run multiple shells
- Terminal inherits your system environment and shell configuration

### 2. Remote Development
```bash
# SSH into remote server and use Cursor
ssh user@remote-server
cursor /path/to/remote/project
```

### 3. Docker Integration
```bash
# Edit files in Docker containers
docker exec -it container_name cursor /app

# Mount local directory and edit
docker run -v $(pwd):/workspace -it ubuntu bash
cursor /workspace
```

## Troubleshooting Common Issues

### 1. AppImage Won't Run
```bash
# Install required libraries
sudo apt-get install libfuse2

# Or extract and run directly
./cursor.AppImage --appimage-extract
./squashfs-root/cursor
```

### 2. Permission Issues
```bash
# Fix permissions
chmod +x /path/to/cursor

# Run with proper user
sudo chown $USER:$USER /path/to/cursor
```

### 3. Missing Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install libnss3 libatk-bridge2.0-0 libdrm2 libgtk-3-0

# Fedora
sudo dnf install nss atk at-spi2-atk gtk3
```

## Advanced Terminal Features

### 1. Command Palette from Terminal
- Use `Ctrl+Shift+P` to open command palette
- Access all Cursor features without leaving keyboard

### 2. File Explorer
- `Ctrl+Shift+E` to toggle file explorer
- Navigate projects efficiently

### 3. Integrated Source Control
- `Ctrl+Shift+G` for Git integration
- Stage, commit, and push from within Cursor

### 4. Extensions for Terminal Users
Recommended extensions for terminal-heavy workflows:
- Terminal tabs
- Vim keybindings (if preferred)
- GitLens for enhanced Git integration
- Remote development extensions

## Performance Tips

1. **Disable unnecessary extensions** for faster startup
2. **Use workspace settings** for project-specific configurations
3. **Configure auto-save** to reduce manual saving
4. **Use keyboard shortcuts** for faster navigation

## Integration with Other Tools

### tmux Integration
```bash
# Create tmux session with Cursor
tmux new-session -d -s coding 'cursor .'
tmux attach-session -t coding
```

### Screen Integration
```bash
# Run Cursor in screen session
screen -S cursor-session cursor /path/to/project
```

This guide should get you started with using Cursor effectively in your Linux terminal environment!