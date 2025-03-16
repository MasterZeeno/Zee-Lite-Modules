MOD_REPO_NAME=$(basename "$MOD_REPOSITORY")
MOD_REPO_YT_ID="$(echo "${MOD_REPO_NAME,,}" | cut -d'-' -f1)-yt"
MOD_PATH_NAME="$(echo "${MOD_REPO_NAME^^}" | cut -d'-' -f1)PATH"
MOD_NAME_YT="$MOD_AUTHOR YouTube Lite"
MOD_DESC_YT="$MOD_NAME_YT Magisk Module"
SITE_URL='https://github.com'
SITE_API='https://api.github.com'
SITE_RAW='https://raw.githubusercontent.com'
ZIP_URL="$SITE_URL/$MOD_AUTHOR/$MOD_REPO_NAME/releases/download"
LATEST_URL="$SITE_API/repos/$ORIG_AUTHOR/$ORIG_REPO_NAME/releases/latest"
UPDATE_URL_RAW="$SITE_RAW/$MOD_AUTHOR/$MOD_REPO_NAME/main/$MOD_REPO_YT_ID"
TO_MATCH='VERSION='
CUSTOM_FX='RESOLVE_VERSION'
TO_APPEND="VERSION=\$($CUSTOM_FX \"\$VERSION\")"
TO_DELETE='Join t.me'
