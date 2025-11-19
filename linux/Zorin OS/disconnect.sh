#!/bin/bash
# VSCode SOCKS5 Namespace Disconnect - Ubuntu/Debian

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_SCRIPT="$SCRIPT_DIR/../../common/disconnect-base.sh"

# Run the base disconnect script
if [ -f "$BASE_SCRIPT" ]; then
    bash "$BASE_SCRIPT"
else
    echo "Error: Base script not found at $BASE_SCRIPT"
    exit 1
fi
