#!/bin/bash

# ======================================================
# NOTE: Update these variables to match your GitHub!
# ======================================================
GITHUB_USER="tvansant-work"
GITHUB_REPO="Form_Email_Checker"
BRANCH="main"
# ======================================================

APP_DIR="$HOME/.form_checker_app"
MAC_APP_PATH="$HOME/Desktop/Form Checker.app"
UPDATED_FILES=""

# Function to securely download and check for updates
check_update() {
    FILE_NAME=$1
    URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/$FILE_NAME"
    TMP_FILE="$APP_DIR/${FILE_NAME}.tmp"
    
    # Download file securely (-s silent, -f fail silently on missing file, -L follow redirects)
    if curl -sSfL "$URL" -o "$TMP_FILE" 2>/dev/null; then
        # If local file doesn't exist, or is different from the newly downloaded one
        if [ ! -f "$APP_DIR/$FILE_NAME" ] || ! cmp -s "$TMP_FILE" "$APP_DIR/$FILE_NAME"; then
            mv "$TMP_FILE" "$APP_DIR/$FILE_NAME"
            # Add to our list of updated files with a newline
            UPDATED_FILES="$UPDATED_FILES"$'\n'"- $FILE_NAME"
            return 0 # True, it updated
        else
            # File is identical, delete the temp file
            rm -f "$TMP_FILE"
        fi
    else
        # Download failed (e.g., offline or file missing on GitHub), clean up
        rm -f "$TMP_FILE"
    fi
    return 1 # False, no update
}

# 1. Check basic files for updates
check_update "form_checker.py"
check_update "install.sh"

# 2. Check requirements and silently update Python packages if changed
if check_update "requirements.txt"; then
    source "$APP_DIR/venv/bin/activate"
    pip install -r "$APP_DIR/requirements.txt" > /dev/null 2>&1
fi

# 3. Check icon and update the Mac App bundle if changed
if check_update "app_icon.png"; then
    if [ -d "$MAC_APP_PATH" ]; then
        sips -s format icns "$APP_DIR/app_icon.png" --out "$MAC_APP_PATH/Contents/Resources/applet.icns" > /dev/null 2>&1
        touch "$MAC_APP_PATH" # Forces macOS to refresh the icon visually
    fi
fi

# 4. Check launcher itself and update the running App bundle if changed
if check_update "launcher.sh"; then
    if [ -d "$MAC_APP_PATH" ]; then
        # Safely replace the executable script by removing it first
        rm -f "$MAC_APP_PATH/Contents/MacOS/launcher"
        cp "$APP_DIR/launcher.sh" "$MAC_APP_PATH/Contents/MacOS/launcher"
        chmod +x "$MAC_APP_PATH/Contents/MacOS/launcher"
    fi
fi

# 5. Notify the user if updates occurred using a native Mac alert
if [ -n "$UPDATED_FILES" ]; then
    APPLESCRIPT_MSG="The following files were downloaded and applied:"$'\n'"$UPDATED_FILES"
    osascript -e "display alert \"Form Checker Updated\" message \"$APPLESCRIPT_MSG\" as informational"
fi

# 6. Finally, activate the virtual environment and run the app
source "$APP_DIR/venv/bin/activate"
python3 "$APP_DIR/form_checker.py"