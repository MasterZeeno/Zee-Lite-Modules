#!/bin/bash

[[ -z "$MOD_REPO_NAME" ]] && exit 1

MOD_PATH_NAME="$(echo "${MOD_REPO_NAME^^}" | cut -d'-' -f1)PATH"

TO_MATCH='VERSION='
CUSTOM_FX='RESOLVE_VERSION'
TO_APPEND="VERSION=\$($CUSTOM_FX \"\$VERSION\")"
TO_DELETE='Join t.me'

TEMPORARY_DIR=$(mkdir_safe "$CUR_DIR/temporary")
DOWNLOADS_DIR=$(mkdir_safe "$CUR_DIR/downloads")
UPDATE_JSON_DIR=$(mkdir_safe "$MOD_REPO_YT_ID")

CURR_TAG=$(cat_safe "$CURRENT_TAG_FILE")

if [[ $LATEST_NAME =~ [Yy]ou[Tt]ube ]]; then
  if is_not_latest "$LATEST_TAG" "$CURR_TAG"; then
    echo "Alert: New release detected! [$LATEST_TAG]"
    rm -rf "$RELEASES_DIR"/*
    echo "$LATEST_TAG" > "$CURRENT_TAG_FILE"
  else
    echo "Alert: Already on latest version! [$LATEST_TAG]"
    exit 0
  fi
else
  exit 1
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
