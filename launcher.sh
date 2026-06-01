#!/bin/bash

# ======================================================
GITHUB_USER="tvansant-work"
GITHUB_REPO="Form_Email_Checker"
BRANCH="main"
# ======================================================

APP_DIR="$HOME/.form_checker_app"
MAC_APP_PATH="$HOME/Desktop/Form Checker.app"
UPDATED_FILES=""

check_update() {
    FILE_NAME=$1
    URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/$FILE_NAME"
    TMP_FILE="$APP_DIR/${FILE_NAME}.tmp"
    
    if curl -sSfL "$URL" -o "$TMP_FILE" 2>/dev/null; then
        if [ ! -f "$APP_DIR/$FILE_NAME" ] || ! cmp -s "$TMP_FILE" "$APP_DIR/$FILE_NAME"; then
            mv "$TMP_FILE" "$APP_DIR/$FILE_NAME"
            UPDATED_FILES="$UPDATED_FILES"$'\n'"- $FILE_NAME"
            return 0 
        else
            rm -f "$TMP_FILE"
        fi
    else
        rm -f "$TMP_FILE"
    fi
    return 1 
}

check_update "form_checker.py"
check_update "install.sh"

if check_update "requirements.txt"; then
    source "$APP_DIR/venv/bin/activate"
    pip install -r "$APP_DIR/requirements.txt" > /dev/null 2>&1
fi

if check_update "app_icon.png"; then
    if [ -d "$MAC_APP_PATH" ]; then
        sips -s format icns "$APP_DIR/app_icon.png" --out "$MAC_APP_PATH/Contents/Resources/applet.icns" > /dev/null 2>&1
        touch "$MAC_APP_PATH" 
    fi
fi

if check_update "launcher.sh"; then
    if [ -d "$MAC_APP_PATH" ]; then
        rm -f "$MAC_APP_PATH/Contents/MacOS/launcher"
        cp "$APP_DIR/launcher.sh" "$MAC_APP_PATH/Contents/MacOS/launcher"
        chmod +x "$MAC_APP_PATH/Contents/MacOS/launcher"
    fi
fi

if [ -n "$UPDATED_FILES" ]; then
    APPLESCRIPT_MSG="The following files were downloaded and applied:"$'\n'"$UPDATED_FILES"
    osascript -e "display alert \"Form Checker Updated\" message \"$APPLESCRIPT_MSG\" as informational"
fi

source "$APP_DIR/venv/bin/activate"
python3 "$APP_DIR/form_checker.py"