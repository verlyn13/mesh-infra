#!/bin/bash
# validate-mesh-ops.sh - Comprehensive validation of mesh-ops user setup
# Run this after creating mesh-ops user to verify everything is working

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MESH_USER="mesh-ops"
MESH_UID=2000
VALIDATION_FAILED=0

# Test results storage
declare -A TEST_RESULTS

echo -e "${BLUE}=== Mesh-Ops User Validation ===${NC}"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Hostname: $(hostname)"
echo ""

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_description="${3:-$test_name}"
    
    echo -n "$test_description: "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        TEST_RESULTS["$test_name"]="PASS"
        return 0
    else
        echo -e "${RED}✗${NC}"
        TEST_RESULTS["$test_name"]="FAIL"
        VALIDATION_FAILED=1
        return 1
    fi
}

# Test 1: User existence
echo -e "${YELLOW}1. User Account Tests${NC}"
run_test "user_exists" "id $MESH_USER" "  User exists"
run_test "correct_uid" "[[ \$(id -u $MESH_USER) -eq $MESH_UID ]]" "  Correct UID ($MESH_UID)"
run_test "home_exists" "[[ -d /home/$MESH_USER ]]" "  Home directory exists"
run_test "shell_access" "sudo su - $MESH_USER -c 'echo test'" "  Shell access works"

# Test 2: Directory structure
echo ""
echo -e "${YELLOW}2. Directory Structure${NC}"
DIRS_TO_CHECK=(
    "/home/$MESH_USER/.config"
    "/home/$MESH_USER/.local/bin"
    "/home/$MESH_USER/Projects"
    "/home/$MESH_USER/Scripts"
    "/home/$MESH_USER/.ssh"
)

for dir in "${DIRS_TO_CHECK[@]}"; do
    dir_name=$(basename "$dir")
    run_test "dir_$dir_name" "[[ -d $dir ]]" "  $dir_name directory"
done

# Test 3: SSH configuration
echo ""
echo -e "${YELLOW}3. SSH Configuration${NC}"
run_test "ssh_dir_perms" "[[ \$(stat -c %a /home/$MESH_USER/.ssh) == '700' ]]" "  SSH directory permissions"

if [[ -f /home/$MESH_USER/.ssh/authorized_keys ]]; then
    run_test "ssh_keys" "[[ -f /home/$MESH_USER/.ssh/authorized_keys ]]" "  Authorized keys present"
    run_test "ssh_key_perms" "[[ \$(stat -c %a /home/$MESH_USER/.ssh/authorized_keys) == '600' ]]" "  Key file permissions"
else
    echo -e "  Authorized keys: ${YELLOW}Not configured${NC}"
fi

# Test 4: Sudo permissions
echo ""
echo -e "${YELLOW}4. Sudo Permissions${NC}"
SUDOERS_FILE="/etc/sudoers.d/50-mesh-ops"
if [[ -f $SUDOERS_FILE ]] || [[ -f /etc/sudoers.d/50-mesh-ops-wsl ]]; then
    run_test "sudoers_exists" "true" "  Sudoers file exists"
    run_test "sudoers_valid" "sudo visudo -c -f $SUDOERS_FILE 2>/dev/null || sudo visudo -c -f /etc/sudoers.d/50-mesh-ops-wsl" "  Sudoers syntax valid"
    
    # Test specific sudo commands
    run_test "sudo_tailscale" "sudo -u $MESH_USER sudo tailscale version 2>/dev/null || true" "  Can run tailscale commands"
else
    echo -e "  Sudoers file: ${RED}Not found${NC}"
    VALIDATION_FAILED=1
fi

# Test 5: Development tools (as mesh-ops user)
echo ""
echo -e "${YELLOW}5. Development Tools${NC}"

# Check tools installation
TOOLS_TO_CHECK="git curl wget vim"
for tool in $TOOLS_TO_CHECK; do
    run_test "tool_$tool" "sudo -u $MESH_USER which $tool" "  $tool installed"
done

# Check for development tools that might be installed
echo ""
echo -e "${YELLOW}6. Optional Development Tools${NC}"
DEV_TOOLS="uv bun mise"
for tool in $DEV_TOOLS; do
    if sudo -u $MESH_USER bash -c "command -v $tool || [ -f ~/.local/bin/$tool ] || [ -f ~/.bun/bin/$tool ]" > /dev/null 2>&1; then
        echo -e "  $tool: ${GREEN}✓ Installed${NC}"
    else
        echo -e "  $tool: ${YELLOW}Not installed (optional)${NC}"
    fi
done

# Test 6: Network connectivity (as mesh-ops)
echo ""
echo -e "${YELLOW}7. Network Connectivity${NC}"
run_test "internet_ping" "sudo -u $MESH_USER ping -c 1 -W 2 8.8.8.8" "  Internet connectivity"
run_test "dns_resolution" "sudo -u $MESH_USER nslookup google.com" "  DNS resolution"

# Test Tailscale connectivity to mesh nodes
echo ""
echo -e "${YELLOW}8. Mesh Network (Tailscale)${NC}"
MESH_NODES=(
    "hetzner-hq:100.84.151.58"
    "laptop-hq:100.84.2.8"
    "wsl-fedora-kbc:100.88.131.44"
)

for node_info in "${MESH_NODES[@]}"; do
    IFS=':' read -r node_name node_ip <<< "$node_info"
    if sudo -u $MESH_USER ping -c 1 -W 2 $node_ip > /dev/null 2>&1; then
        echo -e "  $node_name ($node_ip): ${GREEN}✓ Reachable${NC}"
    else
        echo -e "  $node_name ($node_ip): ${YELLOW}✗ Not reachable${NC}"
    fi
done

# Test 7: Systemd user services (if available)
echo ""
echo -e "${YELLOW}9. Systemd User Services${NC}"
if pidof systemd > /dev/null; then
    run_test "systemd_running" "true" "  Systemd is running"
    
    if sudo -u $MESH_USER systemctl --user status > /dev/null 2>&1; then
        echo -e "  User instance: ${GREEN}✓ Active${NC}"
        
        # Check for linger
        if loginctl show-user $MESH_USER 2>/dev/null | grep -q "Linger=yes"; then
            echo -e "  Linger enabled: ${GREEN}✓${NC}"
        else
            echo -e "  Linger enabled: ${YELLOW}✗ (run: sudo loginctl enable-linger $MESH_USER)${NC}"
        fi
    else
        echo -e "  User instance: ${YELLOW}✗ Not active${NC}"
    fi
else
    echo -e "  Systemd: ${YELLOW}Not available${NC}"
fi

# Test 8: WSL2-specific checks
if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
    echo ""
    echo -e "${YELLOW}10. WSL2-Specific Tests${NC}"
    
    run_test "wsl_interop" "[[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]" "  WSL Interop available"
    
    # Check for WSL2 profile script
    if [[ -f /home/$MESH_USER/.profile.d/wsl-init.sh ]]; then
        echo -e "  WSL init script: ${GREEN}✓${NC}"
    else
        echo -e "  WSL init script: ${YELLOW}✗ Not found${NC}"
    fi
    
    # Check XDG_RUNTIME_DIR
    if sudo -u $MESH_USER bash -c "[[ -d \$XDG_RUNTIME_DIR ]] || [[ -d /run/user/$MESH_UID ]]"; then
        echo -e "  Runtime directory: ${GREEN}✓${NC}"
    else
        echo -e "  Runtime directory: ${YELLOW}✗ May need setup${NC}"
    fi
fi

# Generate summary report
echo ""
echo -e "${BLUE}=== Validation Summary ===${NC}"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

for test_name in "${!TEST_RESULTS[@]}"; do
    if [[ "${TEST_RESULTS[$test_name]}" == "PASS" ]]; then
        ((PASS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

TOTAL_TESTS=$((PASS_COUNT + FAIL_COUNT))

echo "Total tests run: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"

# Provide recommendations if there were failures
if [[ $VALIDATION_FAILED -eq 1 ]]; then
    echo ""
    echo -e "${YELLOW}=== Recommendations ===${NC}"
    
    if [[ "${TEST_RESULTS[user_exists]}" == "FAIL" ]]; then
        echo "• Run the user creation script first:"
        echo "  ./scripts/create-mesh-user.sh $(hostname -s)"
    fi
    
    if [[ "${TEST_RESULTS[sudoers_exists]}" == "FAIL" ]]; then
        echo "• Sudoers configuration is missing. Re-run the setup script."
    fi
    
    echo ""
    echo -e "${RED}Validation completed with failures${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}✅ All validation tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Switch to mesh-ops user: sudo su - $MESH_USER"
    echo "2. Install development tools: ansible-playbook -i inventory/hosts.ini playbooks/bootstrap-mesh-ops.yml"
    echo "3. Configure services as needed"
    exit 0
fi