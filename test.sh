#!/bin/bash

MOD_REPO_NAME=$(basename "$MOD_REPOSITORY")
MOD_REPO_YT_ID="$(echo "${MOD_REPO_NAME,,}" | cut -d'-' -f1)-yt"
MOD_PATH_NAME="$(echo "${MOD_REPO_NAME^^}" | cut -d'-' -f1)PATH"

echo "MOD_AUTHOR: $MOD_AUTHOR"
echo "MOD_REPOSITORY: $MOD_REPOSITORY"
echo "MOD_REPO_NAME: $MOD_REPO_NAME"
echo "MOD_REPO_YT_ID: $MOD_REPO_YT_ID"
echo "MOD_PATH_NAME: $MOD_PATH_NAME"
