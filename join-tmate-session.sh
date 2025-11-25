#!/bin/bash

# Join tmate Collaboration Session
# For COLLABORATORS joining a tmate session

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get username from argument or hostname
USER_NAME="${1}"
TMATE_CONNECTION="${2}"

if [ -z "$USER_NAME" ]; then
    USER_NAME=$(hostname -s 2>/dev/null || hostname)
    if [ -z "$USER_NAME" ]; then
        USER_NAME="User"
    fi
fi

if [ -z "$TMATE_CONNECTION" ]; then
    echo -e "${RED}Error: tmate connection string required!${NC}"
    echo ""
    echo "Usage:"
    echo -e "  ${YELLOW}$0 <username> <tmate-connection>${NC}"
    echo ""
    echo "Example:"
    echo -e "  ${YELLOW}$0 collaborator 'ABjen7Ptvb9v3vt5N34eDvk6Z@nyc1.tmate.io'${NC}"
    echo ""
    echo "The host should provide the tmate connection string"
    exit 1
fi

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Joining tmate Collaboration Session   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Your name: ${USER_NAME}${NC}"
echo -e "${BLUE}Connecting to: ${TMATE_CONNECTION}${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}  IMPORTANT: Manual User Attribution   ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}With tmate, please manually prefix your messages:${NC}"
echo -e "  ${GREEN}[${USER_NAME}] your message here${NC}"
echo ""
echo -e "${BLUE}Example:${NC}"
echo -e "  ${GREEN}[${USER_NAME}] Can we add JWT authentication?${NC}"
echo ""
echo -e "${YELLOW}Press Enter to continue...${NC}"
read

echo ""
echo -e "${GREEN}Connecting to shared session...${NC}"
echo ""

# Connect to tmate session
ssh $TMATE_CONNECTION
