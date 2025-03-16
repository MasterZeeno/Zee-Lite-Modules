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

export CUR_DIR="$(pwd)"
export RELEASES_DIR=$(mkdir_safe "$CUR_DIR/releases")
export CURRENT_TAG_FILE=$(touch_safe "$CUR_DIR/TAG")

export MOD_REPO_NAME=$(basename "$MOD_REPOSITORY")
export MOD_REPO_YT_ID="$(echo "${MOD_REPO_NAME,,}" | cut -d'-' -f1)-yt"
export MOD_NAME_YT="$MOD_AUTHOR YouTube Lite"
export MOD_DESC_YT="$MOD_NAME_YT Magisk Module"

export SITE_URL='https://github.com'
export SITE_API='https://api.github.com'
export SITE_RAW='https://raw.githubusercontent.com'
export ZIP_URL="$SITE_URL/$MOD_AUTHOR/$MOD_REPO_NAME/releases/download"
export LATEST_URL="$SITE_API/repos/$ORIG_AUTHOR/$ORIG_REPO_NAME/releases/latest"
export UPDATE_URL_RAW="$SITE_RAW/$MOD_AUTHOR/$MOD_REPO_NAME/main/$MOD_REPO_YT_ID"

export LATEST_DATA=$(curl -s "$LATEST_URL")
export LATEST_NAME=$(get_info name)
export LATEST_TAG=$(get_info tag_name)

for func in $(declare -F | awk '{print $3}'); do
  export -f "$func"
done
