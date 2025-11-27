#!/bin/bash

# Download Files from Collaboration Server
# Easily download files created during Claude Code sessions

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CONFIG_FILE="$HOME/.claude-collab-config"

# Load config if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Parse command line arguments
REMOTE_PATH="${1}"
LOCAL_PATH="${2:-./}"
REMOTE_HOST="${3:-${COLLAB_HOST}}"
REMOTE_USER="${4:-${COLLAB_REMOTE_USER:-claudeteam}}"

print_usage() {
    echo ""
    echo -e "${CYAN}${BOLD}Download Files from Collaboration Server${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 <remote-path> [local-path] [server-ip] [remote-user]"
    echo ""
    echo "Examples:"
    echo "  # Download a single file"
    echo "  $0 ~/project/output.md"
    echo ""
    echo "  # Download a directory"
    echo "  $0 ~/project/docs/ ./local-docs/"
    echo ""
    echo "  # Download with explicit server details"
    echo "  $0 ~/file.txt ./ 68.183.159.246 claudeteam"
    echo ""
    echo "  # Download multiple files (wildcards)"
    echo "  $0 '~/project/*.md' ./markdown-files/"
    echo ""
    echo "Configuration:"
    echo "  Set these environment variables to avoid typing server details:"
    echo "    export COLLAB_HOST='68.183.159.246'"
    echo "    export COLLAB_REMOTE_USER='claudeteam'"
    echo ""
    echo "  Or run './start-collaboration.sh' once to save configuration"
    echo ""
}

# Validate inputs
if [ -z "$REMOTE_PATH" ]; then
    echo -e "${RED}Error: Remote path is required${NC}"
    print_usage
    exit 1
fi

if [ -z "$REMOTE_HOST" ]; then
    echo -e "${RED}Error: Server IP not provided${NC}"
    print_usage
    exit 1
fi

if [ -z "$REMOTE_USER" ]; then
    echo -e "${RED}Error: Remote username not provided${NC}"
    print_usage
    exit 1
fi

echo ""
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  Download Files from Collaboration Server            ║${NC}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Server:${NC}       ${REMOTE_HOST}"
echo -e "${BLUE}User:${NC}         ${REMOTE_USER}"
echo -e "${BLUE}Remote Path:${NC}  ${REMOTE_PATH}"
echo -e "${BLUE}Local Path:${NC}   ${LOCAL_PATH}"
echo ""

# Check if local path exists (if it's a directory)
if [ -d "$LOCAL_PATH" ]; then
    echo -e "${GREEN}✓${NC} Local directory exists: ${LOCAL_PATH}"
else
    # Create directory if it doesn't exist
    LOCAL_DIR=$(dirname "$LOCAL_PATH")
    if [ ! -d "$LOCAL_DIR" ]; then
        echo -e "${YELLOW}⚠${NC} Creating local directory: ${LOCAL_DIR}"
        mkdir -p "$LOCAL_DIR"
    fi
fi

# Check if remote path exists
echo -e "${BLUE}ℹ${NC} Checking if remote path exists..."

if ssh "${REMOTE_USER}@${REMOTE_HOST}" "[ -e ${REMOTE_PATH} ]"; then
    echo -e "${GREEN}✓${NC} Remote path found"
else
    echo -e "${RED}✗${NC} Remote path not found: ${REMOTE_PATH}"
    echo ""
    echo "Tips:"
    echo "  - Check the path is correct"
    echo "  - Use absolute paths (e.g., /home/user/file.txt)"
    echo "  - Or use ~ for home directory (e.g., ~/project/file.txt)"
    echo ""
    exit 1
fi

# Check if it's a file or directory
IS_DIR=$(ssh "${REMOTE_USER}@${REMOTE_HOST}" "[ -d ${REMOTE_PATH} ] && echo 'yes' || echo 'no'")

if [ "$IS_DIR" = "yes" ]; then
    echo -e "${BLUE}ℹ${NC} Remote path is a directory"

    # Count files
    FILE_COUNT=$(ssh "${REMOTE_USER}@${REMOTE_HOST}" "find ${REMOTE_PATH} -type f | wc -l")
    echo -e "${BLUE}ℹ${NC} Contains approximately ${FILE_COUNT} files"
    echo ""
    read -p "Download entire directory? [Y/n]: " confirm

    if [[ $confirm =~ ^[Nn] ]]; then
        echo "Cancelled"
        exit 0
    fi

    # Use scp with recursive flag
    echo ""
    echo -e "${BOLD}Downloading directory...${NC}"

    if scp -r "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}" "${LOCAL_PATH}"; then
        echo ""
        echo -e "${GREEN}✓${NC} Download complete!"
        echo -e "${BLUE}ℹ${NC} Files saved to: ${LOCAL_PATH}"
    else
        echo ""
        echo -e "${RED}✗${NC} Download failed"
        exit 1
    fi
else
    echo -e "${BLUE}ℹ${NC} Remote path is a file"

    # Get file size
    FILE_SIZE=$(ssh "${REMOTE_USER}@${REMOTE_HOST}" "du -h ${REMOTE_PATH} | cut -f1")
    echo -e "${BLUE}ℹ${NC} File size: ${FILE_SIZE}"

    # Download file
    echo ""
    echo -e "${BOLD}Downloading file...${NC}"

    if scp "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}" "${LOCAL_PATH}"; then
        echo ""
        echo -e "${GREEN}✓${NC} Download complete!"

        if [ -d "$LOCAL_PATH" ]; then
            # Downloaded to directory, show full path
            FILENAME=$(basename "$REMOTE_PATH")
            echo -e "${BLUE}ℹ${NC} File saved to: ${LOCAL_PATH}/${FILENAME}"
        else
            # Downloaded to specific file
            echo -e "${BLUE}ℹ${NC} File saved to: ${LOCAL_PATH}"
        fi
    else
        echo ""
        echo -e "${RED}✗${NC} Download failed"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""

# Offer to open the file/directory
if command -v open &> /dev/null && [ "$(uname)" = "Darwin" ]; then
    # macOS
    read -p "Open in Finder? [Y/n]: " open_finder
    if [[ ! $open_finder =~ ^[Nn] ]]; then
        open "$LOCAL_PATH"
    fi
elif command -v xdg-open &> /dev/null; then
    # Linux
    read -p "Open file manager? [Y/n]: " open_fm
    if [[ ! $open_fm =~ ^[Nn] ]]; then
        xdg-open "$LOCAL_PATH"
    fi
fi
