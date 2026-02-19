#!/usr/bin/env bash
# Test suite for config.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/yaml.sh"
source "$SCRIPT_DIR/../lib/config.sh"

# Test helpers
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_start() {
    printf "Testing: %s... " "$1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    printf "PASS\n"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    printf "FAIL: %s\n" "$1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_eq() {
    local expected="$1"
    local actual="$2"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        test_fail "expected '$expected', got '$actual'"
        return 1
    fi
}

assert_file_exists() {
    local path="$1"
    if [[ -f "$path" ]]; then
        return 0
    else
        test_fail "file does not exist: $path"
        return 1
    fi
}

assert_dir_exists() {
    local path="$1"
    if [[ -d "$path" ]]; then
        return 0
    else
        test_fail "directory does not exist: $path"
        return 1
    fi
}

# --- Tests ---

test_config_init() {
    test_start "config_init - creates workspace"

    local test_dir="/tmp/mars/mars_test_$$"
    local orig_dir="$PWD"
    mkdir -p "$test_dir"
    cd "$test_dir"

    config_init "test-workspace" "$test_dir"

    assert_file_exists "$test_dir/mars.yaml" || { cd "$orig_dir"; rm -rf "$test_dir"; return 1; }
    assert_file_exists "$test_dir/.gitignore" || { cd "$orig_dir"; rm -rf "$test_dir"; return 1; }
    assert_dir_exists "$test_dir/repos" || { cd "$orig_dir"; rm -rf "$test_dir"; return 1; }

    # Check .gitignore content
    if ! grep -q "repos/" "$test_dir/.gitignore"; then
        test_fail ".gitignore doesn't contain repos/"
        cd "$orig_dir"
        rm -rf "$test_dir"
        return 1
    fi

    cd "$orig_dir"
    rm -rf "$test_dir"
    test_pass
}

test_config_find_root() {
    test_start "config_find_root - finds mars.yaml upward"

    local test_dir="/tmp/mars/mars_test_$$"
    local orig_dir="$PWD"
    mkdir -p "$test_dir/repos/subrepo/deep"

    # Create mars.yaml at root
    echo "version: 1" > "$test_dir/mars.yaml"

    # Search from deep directory
    cd "$test_dir/repos/subrepo/deep"

    if config_find_root; then
        assert_eq "$test_dir" "$MARS_WORKSPACE_ROOT" || { cd "$orig_dir"; rm -rf "$test_dir"; return 1; }
        cd "$orig_dir"
        rm -rf "$test_dir"
        test_pass
    else
        test_fail "config_find_root should have found mars.yaml"
        cd "$orig_dir"
        rm -rf "$test_dir"
        return 1
    fi
}

test_config_repo_count() {
    test_start "config_repo_count"

    local test_dir="/tmp/mars/mars_test_$$"
    mkdir -p "$test_dir"

    cat > "$test_dir/mars.yaml" << 'EOF'
version: 1
workspace:
  name: test
repos:
  - url: git@github.com:org/repo1.git
    tags: [frontend]
  - url: git@github.com:org/repo2.git
    tags: [backend]
  - url: git@github.com:org/repo3.git
    tags: [frontend]
defaults:
  branch: main
EOF

    MARS_CONFIG_FILE="$test_dir/mars.yaml"
    config_load

    local total
    total=$(config_repo_count)
    assert_eq "3" "$total" || { rm -rf "$test_dir"; return 1; }

    local frontend
    frontend=$(config_repo_count "frontend")
    assert_eq "2" "$frontend" || { rm -rf "$test_dir"; return 1; }

    rm -rf "$test_dir"
    test_pass
}

# --- Run tests ---

printf "\n=== Config Tests ===\n\n"

test_config_init
test_config_find_root
test_config_repo_count

printf "\n=== Results ===\n"
printf "Passed: %d/%d\n" "$TESTS_PASSED" "$TESTS_RUN"

if [[ $TESTS_FAILED -gt 0 ]]; then
    printf "Failed: %d\n" "$TESTS_FAILED"
    exit 1
fi

exit 0
