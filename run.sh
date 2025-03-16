#!/bin/bash
CUR_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
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
[[ ${1:-0} -eq 1 ]] && : > "$CUR_DIR/TAG"
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
trap 'rm -rf "$TEMPORARY_DIR"' EXIT
TEMPORARY_DIR=$(mkdir_safe "$CUR_DIR/temporary")
DOWNLOADS_DIR=$(mkdir_safe "$CUR_DIR/downloads")
RELEASES_DIR=$(mkdir_safe "$CUR_DIR/releases")
UPDATE_JSON_DIR=$(mkdir_safe "$MOD_REPO_YT_ID")
LATEST_DATA=$(curl -s "$LATEST_URL")
LATEST_NAME=$(get_info name)
LATEST_TAG=$(get_info tag_name)
CURR_TAG=$(cat_safe "$CUR_DIR/TAG")
if [[ $LATEST_NAME =~ [Yy]ou[Tt]ube ]]; then
  if is_not_latest "$LATEST_TAG" "$CURR_TAG"; then
    echo "Alert: New release detected! [$LATEST_TAG]"
    rm -rf "$RELEASES_DIR"/*
    echo "$LATEST_TAG" > "$CUR_DIR/TAG"
  else
    echo "Alert: Already on latest version! [$LATEST_TAG]"
    exit
  fi
else
  exit
fi
URLS=($(echo "$LATEST_DATA" | grep -Eo '"browser_download_url": *"[^"]+\.zip"' | sed -E 's/"browser_download_url": *"([^"]+)"/\1/'))
for URL in "${URLS[@]}"; do
  ZIP_FILE=$(basename "$URL")
  if [ ! -f "$DOWNLOADS_DIR/$ZIP_FILE" ]; then
    aria2c --console-log-level=warn -x 16 -s 64 -j 1 \
      --max-tries=3 --retry-wait=2 -d "$DOWNLOADS_DIR" "$URL" || {
      echo "Error: '$ZIP_FILE' - failed to download."
      exit 1
    }
  fi
  if unzip -oq "$DOWNLOADS_DIR/$ZIP_FILE" -d "$TEMPORARY_DIR"; then
    echo
    for FILE in customize service uninstall; do
      FILE="$TEMPORARY_DIR/$FILE.sh"
      if [[ -s $FILE ]]; then
        CONTENTS=$(< "$FILE")
        if ! grep -qF "$TO_APPEND" <<< "$CONTENTS"; then
          CONTENTS=$(sed "s|.*$TO_MATCH.*|& $TO_APPEND|" <<< "$CONTENTS")
        fi
        NEW_CONTENTS=$(sed -e "/.*$TO_DELETE.*/d" \
          -e "s|rvhc|$MOD_REPO_NAME|g" \
          -e "s|/data/adb/.*.apk|/data/adb/$MOD_REPO_NAME/base.apk|g" \
          -e "s|$ORIG_PATH_NAME=.*|$MOD_PATH_NAME=/data/adb/$MOD_REPO_NAME/base.apk|g" \
          -e "s|$ORIG_PATH_NAME|$MOD_PATH_NAME|g" <<< "$CONTENTS")
        if [[ $NEW_CONTENTS != "$CONTENTS" ]]; then
          echo "$NEW_CONTENTS" > "$FILE"
          echo "Success: '$(basename "$FILE")' - modified."
        else
          echo "Skipped: '$(basename "$FILE")' - already modified."
        fi
      else
        echo "Error: '$(basename "$FILE")' - not found/empty."
      fi
    done
    echo
    CONFIG_FILE="$TEMPORARY_DIR/config"
    if [[ -s $CONFIG_FILE ]]; then
      CONTENTS=$(sed '/^PKG_VER=/s/=\([^v].*\)/=v\1/' "$CONFIG_FILE")
      CONFIG_FX="$CUSTOM_FX() { case \"\$1\" in v*) echo \"\$1\" ;; *) echo \"v\$1\" ;; esac; }"
      if ! grep -qF "$CONFIG_FX" <<< "$CONTENTS"; then
        echo "$CONTENTS" > "$CONFIG_FILE"
        echo "$CONFIG_FX" >> "$CONFIG_FILE"
        echo "Success: '$(basename "$CONFIG_FILE") file' - modified."
      else
        echo "Skipped: '$(basename "$CONFIG_FILE") file' - already modified."
      fi
    else
      echo "Error: '$(basename "$CONFIG_FILE") file' - not found/empty."
    fi
    echo
    MOD_PROP="$TEMPORARY_DIR/module.prop"
    if [[ -s $MOD_PROP ]]; then
      MODIFIED=0
      CONTENTS=$(< "$MOD_PROP")
      JSONFILE=$(sed 's/_/-/; s/\.zip$/.json/' <<< "$ZIP_FILE")
      for ITEM in "id=$MOD_REPO_NAME" "name=$MOD_NAME_YT" \
        "author=$MOD_AUTHOR" "description=$MOD_DESC_YT" \
        "updateJson=$UPDATE_URL_RAW/$JSONFILE"; do
        search="${ITEM%=*}"
        replace="${ITEM##*=}"
        if ! grep -qF "$ITEM" <<< "$CONTENTS"; then
          CONTENTS=$(sed "s|^$search=.*|$search=$replace|" <<< "$CONTENTS")
          echo "Success: '[$search]' - modified."
          MODIFIED=1
        else
          echo "Skipped: '[$search]' - already modified."
        fi
      done
      [[ $MODIFIED -eq 1 ]] && echo "$CONTENTS" > "$MOD_PROP"
      echo
      LOCAL_JSONFILE="$UPDATE_JSON_DIR/$JSONFILE"
      jq -n --arg version "$(get_info version "$MOD_PROP")" \
        --argjson versionCode "$(get_info versionCode "$MOD_PROP")" \
        --arg zipUrl "$ZIP_URL/$LATEST_TAG/$ZIP_FILE" \
        '{ version: $version, versionCode: $versionCode, zipUrl: $zipUrl }' > \
        "$LOCAL_JSONFILE" && echo "Success: '$JSONFILE' - modified." || echo "Error: '$JSONFILE' - failed to modify."
    else
      echo "Error: '$(basename "$MOD_PROP")' - not found/empty."
    fi
    (cd "$TEMPORARY_DIR" && zip -mqr "$RELEASES_DIR/$ZIP_FILE" .) && echo "Success: '$ZIP_FILE' - zipped." || {
      echo "Error: '$ZIP_FILE' - failed to zip."
      exit 1
    }
  fi
done
