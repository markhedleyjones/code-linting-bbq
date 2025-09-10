#!/usr/bin/env bash

# Test script to verify linter functionality with files and directories

set -e

echo "=== Testing Linter Argument Handling ==="
echo

# Create test directory structure
TEST_DIR="/tmp/linter_test_$$"
mkdir -p "$TEST_DIR/src"
mkdir -p "$TEST_DIR/include"

# Create test C++ files
cat >"$TEST_DIR/src/main.cpp" <<'EOF'
#include <iostream>

int main() {
    std::cout << "Hello World" << std::endl;
    return 0;
}
EOF

cat >"$TEST_DIR/include/header.h" <<'EOF'
#ifndef HEADER_H
#define HEADER_H

class TestClass {
public:
    void doSomething();
};

#endif
EOF

# Create test Python files
cat >"$TEST_DIR/test.py" <<'EOF'
def hello():
    print("Hello World")

if __name__ == "__main__":
    hello()
EOF

cat >"$TEST_DIR/src/module.py" <<'EOF'
class MyClass:
    def __init__(self):
        self.value = 42
    
    def get_value(self):
        return self.value
EOF

echo "Test files created in $TEST_DIR"
echo
echo "Directory structure:"
find "$TEST_DIR" -type f | sort
echo

# Function to run a test
run_test() {
	local linter="$1"
	shift
	local description="$1"
	shift

	echo "----------------------------------------"
	echo "Testing: $linter"
	echo "Description: $description"
	echo "Command: $linter $@"
	echo

	if command -v "$linter" >/dev/null 2>&1; then
		cd "$TEST_DIR"
		if $linter "$@"; then
			echo "✓ Test passed"
		else
			echo "✗ Test failed (but command executed)"
		fi
	else
		echo "⚠ Linter not found in PATH: $linter"
	fi
	echo
}

# Test each linter with different argument combinations
echo "=== Testing Individual Linters ==="
echo

# Test with no arguments (should scan current directory)
cd "$TEST_DIR"
run_test lint-sq-clang "No arguments (scan current dir)"

# Test with specific file
run_test lint-sq-clang "Single C++ file" src/main.cpp

# Test with directory
run_test lint-sq-clang "Directory" src/

# Test with multiple files
run_test lint-sq-clang "Multiple files" src/main.cpp include/header.h

# Test Python linters
run_test lint-sq-flake8 "Single Python file" test.py
run_test lint-sq-flake8 "Directory with Python" src/
run_test lint-sq-flake8 "Multiple arguments" test.py src/

# Test the main lint-sq with arguments
echo "=== Testing Main lint-sq Script ==="
echo
run_test lint-sq "No arguments"
run_test lint-sq "Specific files" src/main.cpp test.py
run_test lint-sq "Directory" src/

# Cleanup
echo "=== Cleanup ==="
rm -rf "$TEST_DIR"
echo "Test directory removed"
echo
echo "=== Testing Complete ==="
