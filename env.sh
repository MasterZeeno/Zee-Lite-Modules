touch_safe() {
  local file="$1"
  [[ -f $file ]] || touch "$file"
  echo "$file"
}

mkdir_safe() {
  local dir="$1"
  [[ -d $dir ]] || mkdir -p "$dir"
  echo "$dir"
}

cat_safe() {
  local file="$1"
  [[ -f $file ]] || touch "$file"
  cat "$file"
}

get_info() {
  local PROP="$1"
  local DATA="${2:-$LATEST_DATA}"
  local OPTR="${3:-=}"
  [[ -f $DATA ]] && DATA=$(< "$DATA")
  [[ -z $PROP ]] && echo "$DATA"
  if echo "$DATA" | jq -e . > /dev/null 2>&1; then
    jq -r --arg key "$PROP" '.[$key] // ""' <<< "$DATA"
  else
    awk -F "$OPTR" -v k="$PROP" '$1 == k {print $2}' <<< "$DATA"
  fi
}

is_not_latest() {
  local LATEST="$1"
  local CURRENT="$2"
  [[ -z $CURRENT ]] && return 0
  [[ $CURRENT != "$(printf '%s\n%s' "$LATEST" "$CURRENT" | sort -rV | head -n1)" ]] && return 0
  return 1
}

has_release_zips() {
  if find "$RELEASES_DIR" -type f -name "*.zip" -quit; then
    return 0
  else
    echo "No ZIP files found in the release folder."
    return 1
  fi
}

RELEASES_DIR=$(mkdir_safe releases)
CURRENT_TAG_FILE=$(touch_safe TAG)

MOD_REPO_NAME=$(basename "$MOD_REPOSITORY")
MOD_REPO_YT_ID="$(echo "${MOD_REPO_NAME,,}" | cut -d'-' -f1)-yt"
MOD_NAME_YT="$MOD_AUTHOR YouTube Lite"
MOD_DESC_YT="$MOD_NAME_YT Magisk Module"

SITE_URL='https://github.com'
SITE_API='https://api.github.com'
SITE_RAW='https://raw.githubusercontent.com'
ZIP_URL="$SITE_URL/$MOD_AUTHOR/$MOD_REPO_NAME/releases/download"
LATEST_URL="$SITE_API/repos/$ORIG_AUTHOR/$ORIG_REPO_NAME/releases/latest"
UPDATE_URL_RAW="$SITE_RAW/$MOD_AUTHOR/$MOD_REPO_NAME/main/$MOD_REPO_YT_ID"

LATEST_DATA=$(curl -s "$LATEST_URL")
LATEST_NAME=$(get_info name)
LATEST_TAG=$(get_info tag_name)

export RELEASES_DIR

export MOD_REPO_YT_ID
export MOD_NAME_YT
export MOD_DESC_YT

export LATEST_DATA
export LATEST_NAME
export LATEST_TAG

export CURRENT_TAG_FILE
