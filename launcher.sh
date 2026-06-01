#!/bin/bash
GITHUB_USER="tvansant-work"
GITHUB_REPO="Form_Email_Checker"
APP_NAME="Form_Checker"
BASE_DIR="$HOME/Library/Application Support/$APP_NAME"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH"

cd "$BASE_DIR"

echo "=================================================="
echo "  Checking for updates from GitHub..."
echo "=================================================="

# Helper: download a file, compare checksums, report what changed.
fetch_and_report() {
  local URL="$1"
  local DEST="$2"
  local LABEL="$3"
  local TMP="${DEST}.tmp"

  curl -s -L -H "Cache-Control: no-cache" -H "Pragma: no-cache" -o "$TMP" "$URL"

  if [ ! -s "$TMP" ]; then
    echo "  WARNING  $LABEL - download failed, keeping existing version"
    rm -f "$TMP"
    return 1
  fi

  if [ -f "$DEST" ]; then
    OLD_SUM=$(md5 -q "$DEST" 2>/dev/null || md5sum "$DEST" | cut -d' ' -f1)
    NEW_SUM=$(md5 -q "$TMP"  2>/dev/null || md5sum "$TMP"  | cut -d' ' -f1)
    if [ "$OLD_SUM" = "$NEW_SUM" ]; then
      echo "  up to date  $LABEL"
      rm -f "$TMP"
      return 1
    else
      mv "$TMP" "$DEST"
      return 0
    fi
  else
    mv "$TMP" "$DEST"
    return 0
  fi
}

# Check for launcher updates first
fetch_and_report "$RAW_BASE/launcher.sh" "launcher.sh" "launcher.sh      "
LAUNCHER_UPDATED=$?
if [ $LAUNCHER_UPDATED -eq 0 ]; then
  chmod +x launcher.sh
  echo ""
  echo "  Launcher updated — restarting with new version..."
  echo "=================================================="
  exec "$BASE_DIR/launcher.sh"
fi

fetch_and_report "$RAW_BASE/form_checker.py" "form_checker.py" "form_checker.py"
fetch_and_report "$RAW_BASE/requirements.txt"   "requirements.txt"   "requirements.txt  "
fetch_and_report "$RAW_BASE/app_icon.png"        "app_icon.png"       "app_icon.png      "

# Sync dependencies
source venv/bin/activate
pip install -r requirements.txt --quiet

# Re-apply icon to Desktop Shortcut
./venv/bin/python3 - << 'PYEOF'
import Cocoa, os
icon_path = os.path.expanduser("~/Library/Application Support/Form_Checker/app_icon.png")
file_path = os.path.expanduser("~/Desktop/Form Checker.command")
if os.path.exists(icon_path) and os.path.exists(file_path):
    icon_image = Cocoa.NSImage.alloc().initWithContentsOfFile_(icon_path)
    if icon_image:
        Cocoa.NSWorkspace.sharedWorkspace().setIcon_forFile_options_(icon_image, file_path, 0)
PYEOF

echo "=================================================="
echo "  Starting Form Checker..."
echo "=================================================="

exec ./venv/bin/python3 form_checker.py