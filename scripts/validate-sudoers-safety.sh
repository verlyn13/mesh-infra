#!/bin/bash
# validate-sudoers-safety.sh - Check for dangerous sudo patterns that could kill SSH
# CRITICAL: Prevents accidental SSH lockouts from wildcard sudo rules

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Sudoers Safety Validation ==="
echo "Checking for dangerous patterns that could disrupt SSH..."
echo ""

ERRORS=0
WARNINGS=0

# Find all sudoers files
SUDOERS_FILES="/etc/sudoers"
if [[ -d /etc/sudoers.d ]]; then
    SUDOERS_FILES="$SUDOERS_FILES $(find /etc/sudoers.d -type f 2>/dev/null | tr '\n' ' ')"
fi

# Dangerous patterns to check
declare -A CRITICAL_PATTERNS=(
    ["systemctl stop \*"]="Can stop ANY service including SSH!"
    ["systemctl restart \*"]="Can restart ANY service including SSH!"
    ["systemctl start \*"]="Wildcard service control is dangerous"
    ["systemctl \* sshd"]="Direct SSH service control should be restricted"
    ["systemctl \* ssh"]="Direct SSH service control should be restricted"
    ["service \* stop"]="Can stop ANY service including SSH!"
    ["service sshd"]="Direct SSH service control should be restricted"
    ["killall \*"]="Can kill any process including sshd!"
    ["pkill \*"]="Can kill any process including sshd!"
    ["kill -9"]="Force kill without process restrictions"
)

# Warning patterns (less critical but concerning)
declare -A WARNING_PATTERNS=(
    ["ALL=(ALL) NOPASSWD: ALL"]="Full passwordless sudo - extremely dangerous!"
    ["systemctl daemon-reload"]="Can reload systemd configuration"
    ["/sbin/shutdown"]="Can shutdown the system"
    ["/sbin/reboot"]="Can reboot the system"
    ["/sbin/halt"]="Can halt the system"
)

# Check each sudoers file
for file in $SUDOERS_FILES; do
    if [[ ! -f "$file" ]]; then
        continue
    fi
    
    echo "Checking: $file"
    
    # Check for critical patterns
    for pattern in "${!CRITICAL_PATTERNS[@]}"; do
        if sudo grep -q "$pattern" "$file" 2>/dev/null; then
            echo -e "  ${RED}✗ CRITICAL: Found '$pattern'${NC}"
            echo -e "    ${RED}Risk: ${CRITICAL_PATTERNS[$pattern]}${NC}"
            ((ERRORS++))
        fi
    done
    
    # Check for warning patterns
    for pattern in "${!WARNING_PATTERNS[@]}"; do
        if sudo grep -q "$pattern" "$file" 2>/dev/null; then
            echo -e "  ${YELLOW}⚠ WARNING: Found '$pattern'${NC}"
            echo -e "    ${YELLOW}Risk: ${WARNING_PATTERNS[$pattern]}${NC}"
            ((WARNINGS++))
        fi
    done
    
    # Check for mesh-ops specific rules
    if sudo grep -q "mesh-ops" "$file" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Contains mesh-ops rules${NC}"
        
        # Verify safe patterns
        if sudo grep -q "systemctl.*tailscaled$" "$file" 2>/dev/null; then
            echo -e "    ${GREEN}✓ Tailscale control is specific (safe)${NC}"
        fi
        
        if sudo grep -q "systemctl --user" "$file" 2>/dev/null; then
            echo -e "    ${GREEN}✓ User systemctl is scoped (safe)${NC}"
        fi
    fi
done

echo ""
echo "=== Recommended Safe Patterns ==="
echo ""
echo "GOOD - Specific service control:"
echo "  mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tailscaled"
echo "  mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx"
echo ""
echo "GOOD - User-scoped systemctl (can't affect system services):"
echo "  mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl --user *"
echo ""
echo "BAD - Dangerous wildcards:"
echo "  mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop *"
echo "  mesh-ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl * sshd"
echo ""

# Summary
echo "=== Summary ==="
if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}Found $ERRORS critical issues that could lock you out!${NC}"
    echo -e "${RED}FIX IMMEDIATELY: These patterns can kill SSH access${NC}"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}Found $WARNINGS warnings - review recommended${NC}"
    exit 0
else
    echo -e "${GREEN}✓ No dangerous sudo patterns detected${NC}"
    echo -e "${GREEN}✓ SSH service should be protected from accidental disruption${NC}"
    exit 0
fi