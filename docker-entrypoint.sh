#!/bin/bash
set -e

echo "=== Custom Entrypoint Startup ==="

# 1. Populate CoreScripts if /server/data/data doesn't exist
if [ ! -d "/server/data/data" ]; then
  echo "Data folder empty, populating with CoreScripts..."
  cp -a /server/CoreScripts/. /server/data/
fi

# 2. Sync active scripts to the server data folder
echo "Installing active scripts..."
mkdir -p /server/data/scripts/custom

if [ -d "/server/scripts_active" ]; then
  cp -r /server/scripts_active/. /server/data/scripts/custom/
  echo "Copied active scripts to /server/data/scripts/custom/"
fi

# 3. Generate customScripts.lua automatically to load the active scripts
CUSTOM_SCRIPTS_FILE="/server/data/scripts/customScripts.lua"
echo "Generating customScripts.lua..."

cat << 'EOF' > "$CUSTOM_SCRIPTS_FILE"
-- Load up your custom scripts here! Ideally, your custom scripts will be placed in the scripts/custom folder and then get loaded like this:
--
-- require("custom/yourScript")
--
-- Refer to the Tutorial.md file for information on how to use various event and command hooks in your scripts.

EOF

# For each .lua file in /server/scripts_active, append the require statement
if [ -d "/server/scripts_active" ]; then
  for filepath in /server/scripts_active/*.lua; do
    if [ -f "$filepath" ]; then
      filename=$(basename "$filepath" .lua)
      echo "require(\"custom/$filename\")" >> "$CUSTOM_SCRIPTS_FILE"
      echo "  Registered script: $filename"
    fi
  done
fi

# 4. Mirror config files from external config directory if they exist
if [ -d "/server/config" ]; then
  echo "Checking for external configuration overrides..."
  
  # Mirror tes3mp-server-default.cfg if it exists
  if [ -f "/server/config/tes3mp-server-default.cfg" ]; then
    echo "Mirroring tes3mp-server-default.cfg..."
    cp /server/config/tes3mp-server-default.cfg /server/tes3mp-server-default.cfg
  fi

  # Mirror config.lua if it exists
  if [ -f "/server/config/config.lua" ]; then
    echo "Mirroring config.lua..."
    cp /server/config/config.lua /server/data/scripts/config.lua
  fi

  # Mirror requiredDataFiles.json if it exists
  if [ -f "/server/config/requiredDataFiles.json" ]; then
    echo "Mirroring requiredDataFiles.json..."
    mkdir -p /server/data/data
    cp /server/config/requiredDataFiles.json /server/data/data/requiredDataFiles.json
  fi
fi

echo "=== Custom Entrypoint Startup Complete ==="

# 5. Hand over to the original entrypoint script of the container
exec /entrypoint.sh "$@"
