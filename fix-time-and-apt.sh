#!/bin/bash
# Fix system time and APT configuration
# Run this on the test server before deployment

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Time & APT Configuration Fix${NC}"
echo -e "${GREEN}========================================${NC}"
echo

# 1. Show current time
echo -e "${YELLOW}[1/6]${NC} Current system time:"
date
CURRENT_YEAR=$(date +%Y)
if [ "$CURRENT_YEAR" != "2025" ]; then
    echo -e "  ${RED}!${NC} Warning: Year is $CURRENT_YEAR (should be 2025)"
fi
echo

# 2. Install and configure NTP
echo -e "${YELLOW}[2/6]${NC} Installing NTP service..."
export DEBIAN_FRONTEND=noninteractive
apt install -y systemd-timesyncd 2>&1 | grep -v "^debconf:" || true
echo "  ✓ NTP service installed"
echo

# 3. Configure NTP server
echo -e "${YELLOW}[3/6]${NC} Configuring NTP server (192.168.122.10)..."
mkdir -p /etc/systemd/timesyncd.conf.d/
cat > /etc/systemd/timesyncd.conf.d/local.conf << EOF
[Time]
NTP=192.168.122.10
FallbackNTP=time.cloudflare.com time.google.com
EOF
echo "  ✓ NTP server configured"
echo

# 4. Restart and enable NTP synchronization
echo -e "${YELLOW}[4/6]${NC} Restarting NTP service..."
systemctl restart systemd-timesyncd
timedatectl set-ntp true
echo "  ✓ NTP enabled"
echo

# 5. Wait for time sync
echo -e "${YELLOW}[5/6]${NC} Waiting for time synchronization (10 seconds)..."
sleep 10
echo

# 6. Show updated time and status
echo -e "${YELLOW}[6/6]${NC} Updated system time:"
date
NEW_YEAR=$(date +%Y)
if [ "$NEW_YEAR" = "2025" ]; then
    echo -e "  ${GREEN}✓${NC} Year is correct: 2025"
else
    echo -e "  ${RED}!${NC} Year is still wrong: $NEW_YEAR"
fi
echo
echo "NTP Status:"
timedatectl show-timesync --all
echo

# Test APT update
echo -e "${YELLOW}[TEST]${NC} Testing APT update..."
if apt update -qq 2>&1; then
    echo -e "  ${GREEN}✓${NC} APT update successful!"
else
    echo -e "  ${YELLOW}!${NC} APT update might still have issues"
    echo -e "  ${YELLOW}→${NC} Check: systemctl status systemd-timesyncd"
    echo -e "  ${YELLOW}→${NC} Manual sync: sudo timedatectl set-ntp true"
fi

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Time fix complete!${NC}"
echo -e "${GREEN}NTP Server: 192.168.122.10${NC}"
echo -e "${GREEN}========================================${NC}"
