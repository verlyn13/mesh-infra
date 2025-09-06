#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Foundation Verification Report ==="
echo "Date: $(date)"
echo "Directory: $(pwd)"
echo

# Track issues
ISSUES=0

# Function to check file exists and is not empty
check_file() {
    if [ -f "$1" ]; then
        if [ -s "$1" ]; then
            echo -e "${GREEN}✓${NC} $1 exists ($(wc -l < "$1") lines)"
            return 0
        else
            echo -e "${YELLOW}⚠${NC} $1 exists but is empty"
            ((ISSUES++))
            return 1
        fi
    else
        echo -e "${RED}✗${NC} $1 missing"
        ((ISSUES++))
        return 1
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 directory exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 directory missing"
        ((ISSUES++))
        return 1
    fi
}

echo "### Core Structure ###"
check_dir "docs/_grounding"
check_dir "docs/_grounding/adr"
check_dir "docs/_generated"
check_dir "infra/policy/intent"
check_dir "infra/policy/generated"
check_dir "infra/bootstrap"
check_dir "infra/backup/wg"
check_dir "infra/scripts"
check_dir "scripts"
check_dir ".session"

echo
echo "### Grounding Bundle (CRITICAL) ###"
check_file "docs/_grounding/facts.yml"
check_file "docs/_grounding/module_map.json"
check_file "docs/_grounding/roadmap.md"
check_file "docs/_grounding/session_template.md"

echo
echo "### Documentation ###"
check_file "README.md"
check_file "AGENTS.md"
check_file "docs/_grounding/Day1.md"
check_file "docs/_grounding/network-reference.yaml"
check_file "infra/ESCAPE_HATCHES.md"
check_file ".claude-instructions"

echo
echo "### Policy Layer ###"
check_file "infra/policy/intent/network.yaml"
check_file "infra/policy/intent/generate.sh"
if [ -x "infra/policy/intent/generate.sh" ]; then
    echo -e "${GREEN}✓${NC} generate.sh is executable"
else
    echo -e "${RED}✗${NC} generate.sh is not executable"
    ((ISSUES++))
fi

echo
echo "### Scripts ###"
check_file "scripts/ground.py"
check_file "scripts/repo_probe.py"
check_file "scripts/doc_check.py"
check_file "scripts/policy_check.py"
check_file "infra/scripts/init-day1.sh"
check_file "infra/scripts/test-mesh.sh"

# Check executability
for script in scripts/*.py infra/scripts/*.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo -e "${GREEN}✓${NC} $script is executable"
    elif [ -f "$script" ]; then
        echo -e "${YELLOW}⚠${NC} $script exists but not executable"
        ((ISSUES++))
    fi
done

echo
echo "### Git Configuration ###"
check_file ".gitignore"
check_file "CODEOWNERS"
check_file "Makefile"

echo
echo "### Content Validation ###"

# Check facts.yml structure
if [ -f "docs/_grounding/facts.yml" ]; then
    if grep -q "version:" docs/_grounding/facts.yml && \
       grep -q "nodes:" docs/_grounding/facts.yml && \
       grep -q "hetzner:" docs/_grounding/facts.yml; then
        echo -e "${GREEN}✓${NC} facts.yml has expected structure"
    else
        echo -e "${RED}✗${NC} facts.yml structure incomplete"
        ((ISSUES++))
    fi
fi

# Check network.yaml has required invariants
if [ -f "infra/policy/intent/network.yaml" ]; then
    if grep -q "security_invariants:" infra/policy/intent/network.yaml && \
       grep -q "admin_ports_never_public" infra/policy/intent/network.yaml; then
        echo -e "${GREEN}✓${NC} network.yaml has security invariants"
    else
        echo -e "${RED}✗${NC} network.yaml missing security invariants"
        ((ISSUES++))
    fi
fi

# Check Makefile targets
if [ -f "Makefile" ]; then
    EXPECTED_TARGETS="help ground-pull ground-plan probe init-day1 escape-hatch test"
    MISSING_TARGETS=""
    for target in $EXPECTED_TARGETS; do
        if ! grep -q "^${target}:" Makefile; then
            MISSING_TARGETS="$MISSING_TARGETS $target"
        fi
    done
    if [ -z "$MISSING_TARGETS" ]; then
        echo -e "${GREEN}✓${NC} Makefile has all expected targets"
    else
        echo -e "${YELLOW}⚠${NC} Makefile missing targets:$MISSING_TARGETS"
        ((ISSUES++))
    fi
fi

echo
echo "### Python Dependencies ###"
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Python3 available: $(python3 --version)"
    
    # Check for required modules
    for module in yaml json pathlib subprocess; do
        if python3 -c "import $module" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Python module '$module' available"
        else
            echo -e "${YELLOW}⚠${NC} Python module '$module' not available"
        fi
    done
else
    echo -e "${RED}✗${NC} Python3 not found"
    ((ISSUES++))
fi

echo
echo "### Summary ###"
if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ Foundation is SOLID - No issues found!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Found $ISSUES issues that need attention${NC}"
    exit 1
fi
