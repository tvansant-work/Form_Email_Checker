#!/bin/bash

# Configuration
GITHUB_USER="tvansant-work"
GITHUB_REPO="Form_Email_Checker"
APP_NAME="Form_Checker"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH"
SHORTCUT="$HOME/Desktop/Form Checker.command"
BASE_DIR="$HOME/Library/Application Support/$APP_NAME"

echo "=================================================="
echo "  Form Checker - Installer"
echo "=================================================="

# 1. Setup folder and Python environment
echo ""
echo "Step 1/3: Preparing Python environment..."
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# 2. Download all app files from GitHub
echo ""
echo "Step 2/3: Downloading app files from GitHub..."
curl -s -L -o form_checker.py "$RAW_BASE/form_checker.py"
curl -s -L -o requirements.txt   "$RAW_BASE/requirements.txt"
curl -s -L -o app_icon.png       "$RAW_BASE/app_icon.png"

curl -s -L -o launcher.sh "$RAW_BASE/launcher.sh"
chmod +x launcher.sh

echo "  form_checker.py  ($(wc -c < form_checker.py | tr -d ' ') bytes)"
echo "  requirements.txt"
echo "  app_icon.png"
echo "  launcher.sh"

# 3. Install dependencies
echo ""
echo "  Installing Python dependencies..."
source venv/bin/activate
pip install -r requirements.txt --quiet
./venv/bin/pip install pyobjc-framework-Cocoa --quiet

# 4. Create Desktop Shortcut pointing to launcher.sh
echo ""
echo "Step 3/3: Creating Desktop Shortcut..."
echo "\"$BASE_DIR/launcher.sh\"" > "$SHORTCUT"
chmod +x "$SHORTCUT"

# 5. Apply Icon
./venv/bin/python3 - << 'PYEOF'
import Cocoa, os
icon_path = os.path.expanduser("~/Library/Application Support/Form_Checker/app_icon.png")
file_path = os.path.expanduser("~/Desktop/Form Checker.command")
if os.path.exists(icon_path) and os.path.exists(file_path):
    img = Cocoa.NSImage.alloc().initWithContentsOfFile_(icon_path)
    if img: Cocoa.NSWorkspace.sharedWorkspace().setIcon_forFile_options_(img, file_path, 0)
PYEOF

echo "=================================================="
echo "  Installation Complete!"
echo "  Look for 'Form Checker.command' on your Desktop."
echo "  You can now close this Terminal window."
echo "=================================================="