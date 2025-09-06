#!/bin/bash
set -euo pipefail

echo "=== Testing Core Workflows ==="
echo

# Test 1: Ground Pull
echo "1. Testing ground-pull..."
if make ground-pull > /tmp/ground-pull.out 2>&1; then
    echo "   ✓ ground-pull works"
else
    echo "   ✗ ground-pull failed:"
    cat /tmp/ground-pull.out
    exit 1
fi

# Test 2: Ground Plan
echo "2. Testing ground-plan..."
if make ground-plan > /tmp/ground-plan.out 2>&1; then
    echo "   ✓ ground-plan works"
    SESSION_FILE=$(grep "Created session:" /tmp/ground-plan.out | cut -d: -f2 | xargs)
    if [ -f "$SESSION_FILE" ]; then
        echo "   ✓ Session file created: $SESSION_FILE"
    fi
else
    echo "   ✗ ground-plan failed"
    exit 1
fi

# Test 3: Probe
echo "3. Testing probe..."
if make probe > /tmp/probe.out 2>&1; then
    echo "   ✓ probe works"
    if [ -f "docs/_generated/snapshot.json" ]; then
        echo "   ✓ Snapshot generated"
    fi
else
    echo "   ✗ probe failed"
    exit 1
fi

# Test 4: Policy Generation
echo "4. Testing policy generation..."
cd infra/policy/intent
if ./generate.sh > /tmp/generate.out 2>&1; then
    echo "   ✓ Policy generation works"
    if [ -f "../generated/tailscale-acl.json" ]; then
        echo "   ✓ Tailscale ACL generated"
    fi
else
    echo "   ✗ Policy generation failed"
fi
cd ../../..

# Test 5: Commit Protection
echo "5. Testing commit protection..."
echo "test" >> docs/_grounding/facts.yml

# Temporarily disable pipefail for this specific test
set +o pipefail
python3 scripts/ground.py commit 2>&1 | tee /tmp/commit-test.out | grep -q "ERROR"
PROTECTION_WORKS=$?
set -o pipefail

if [ $PROTECTION_WORKS -eq 0 ]; then
    echo "   ✓ Commit protection working"
    git checkout -- docs/_grounding/facts.yml
else
    echo "   ✗ Commit protection may not be working"
    cat /tmp/commit-test.out
fi

echo
echo "=== All Core Workflows Tested ==="
