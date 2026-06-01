#!/bin/bash
echo "==========================================="
echo "   Installing SEQTA Form Checker App...    "
echo "==========================================="

# ======================================================
GITHUB_USER="tvansant-work"
GITHUB_REPO="Form_Email_Checker"
BRANCH="main"
# ======================================================

APP_DIR="$HOME/.form_checker_app"
VENV_DIR="$APP_DIR/venv"
DESKTOP_DIR="$HOME/Desktop"
APP_NAME="Form Checker.app"

# 1. Create a hidden folder for the app's internal files
mkdir -p "$APP_DIR"

echo "Downloading files from GitHub..."
curl -sSL "https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/form_checker.py" -o "$APP_DIR/form_checker.py"
curl -sSL "https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/requirements.txt" -o "$APP_DIR/requirements.txt"
curl -sSL "https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/launcher.sh" -o "$APP_DIR/launcher.sh"
curl -sSL --fail "https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/app_icon.png" -o "$APP_DIR/app_icon.png" || echo "No icon found on GitHub, using default."

echo "Setting up Python environment (this may take a minute)..."
if ! command -v python3 &> /dev/null
then
    echo "Python3 could not be found. Please ensure Python3 is installed on your Mac."
    exit
fi

# 2. Create the virtual environment and install requirements
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip > /dev/null 2>&1
echo "Installing Pandas and OpenPyXL..."
pip install -r "$APP_DIR/requirements.txt" > /dev/null 2>&1

echo "Creating Desktop App Shortcut..."
MAC_APP_PATH="$DESKTOP_DIR/$APP_NAME"

# Clean up any old versions
rm -rf "$MAC_APP_PATH" 

# 3. Build the macOS .app bundle structure
mkdir -p "$MAC_APP_PATH/Contents/MacOS"
mkdir -p "$MAC_APP_PATH/Contents/Resources"

# Put launcher in the app bundle
cp "$APP_DIR/launcher.sh" "$MAC_APP_PATH/Contents/MacOS/launcher"
chmod +x "$MAC_APP_PATH/Contents/MacOS/launcher"

# 4. Generate the proper Mac Icon (.icns) from the PNG
if [ -f "$APP_DIR/app_icon.png" ]; then
    sips -s format icns "$APP_DIR/app_icon.png" --out "$MAC_APP_PATH/Contents/Resources/applet.icns" > /dev/null 2>&1
fi

# 5. Create Info.plist to tell macOS how to run the app
cat << 'EOF' > "$MAC_APP_PATH/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIconFile</key>
    <string>applet.icns</string>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleName</key>
    <string>Form Checker</string>
    <key>CFBundleIdentifier</key>
    <string>com.school.formchecker</string>
</dict>
</plist>
EOF

echo "==========================================="
echo " Installation Complete! "
echo " Look for 'Form Checker' on your Desktop."
echo " You can now close this Terminal window."
echo "==========================================="