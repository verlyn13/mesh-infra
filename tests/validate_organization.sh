#!/bin/bash
set -euo pipefail

echo "=== Validating File Organization ==="

ISSUES=0

# Check no test scripts in root
if ls *.sh 2>/dev/null | grep -E "(test|verify)" > /dev/null; then
    echo "✗ Test scripts found in root (should be in tests/)"
    ((ISSUES++))
else
    echo "✓ No test scripts in root"
fi

# Check scripts/ has only repo tools
if ls scripts/*.sh 2>/dev/null | grep -v "emergency" > /dev/null; then
    echo "⚠ Shell scripts in scripts/ (should be Python only?)"
else
    echo "✓ scripts/ contains repo management tools"
fi

# Check infra/scripts has infrastructure scripts
if [ -f "infra/scripts/init-day1.sh" ] && [ -f "infra/scripts/test-mesh.sh" ]; then
    echo "✓ Infrastructure scripts in correct location"
else
    echo "✗ Missing infrastructure scripts"
    ((ISSUES++))
fi

# Check tests/ exists and has test scripts
if [ -d "tests" ] && ls tests/*.sh 2>/dev/null > /dev/null; then
    echo "✓ Test scripts in tests/"
else
    echo "✗ tests/ directory missing or empty"
    ((ISSUES++))
fi

# Check for documentation
if [ -f "docs/_grounding/file-organization.md" ]; then
    echo "✓ File organization policy documented"
else
    echo "✗ File organization policy missing"
    ((ISSUES++))
fi

# Check protected files exist
for file in "docs/_grounding/facts.yml" \
           "docs/_grounding/module_map.json" \
           "CODEOWNERS"; do
    if [ -f "$file" ]; then
        echo "✓ Protected file exists: $file"
    else
        echo "✗ Missing protected file: $file"
        ((ISSUES++))
    fi
done

echo
if [ $ISSUES -eq 0 ]; then
    echo "✅ File organization validated successfully!"
else
    echo "⚠ Found $ISSUES organization issues"
fi