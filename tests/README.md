# Test Suite

This directory contains all test scripts for the mesh infrastructure project.

## Test Scripts

### verify_foundation.sh
Validates the basic repository structure and ensures all required files and directories are in place.

**Usage:**
```bash
./tests/verify_foundation.sh
```

### test_workflows.sh
Tests the complete workflow including session management, policy generation, and commit protection.

**Usage:**
```bash
./tests/test_workflows.sh
```

## Running Tests

From the project root:
```bash
# Run all tests
for test in tests/*.sh; do
    echo "Running $test..."
    bash "$test"
done

# Run specific test
bash tests/verify_foundation.sh
```

## Test Categories

- **Foundation Tests**: Verify repository structure and basic setup
- **Workflow Tests**: Test agent workflows and protection mechanisms
- **Integration Tests**: End-to-end testing (future)
- **Network Tests**: Use `make test` to run mesh connectivity tests