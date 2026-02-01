#!/usr/bin/env bash
# Integration tests for Mars CLI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARS_CMD="$SCRIPT_DIR/../mars"
ORIG_DIR="$PWD"

# Test workspace directory
TEST_DIR=""

# Test helpers
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

cleanup() {
    cd "$ORIG_DIR" 2>/dev/null || true
    if [[ -n "$TEST_DIR" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

trap cleanup EXIT

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

setup_test_dir() {
    cleanup
    TEST_DIR="/tmp/claude/mars_integ_$$_$RANDOM"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
}

# --- Tests ---

test_help() {
    test_start "mars --help"

    local output
    output=$("$MARS_CMD" --help 2>&1) || true
    if echo "$output" | grep -q "Multi Agentic Repo Workspace Manager"; then
        test_pass
    else
        test_fail "help output missing expected text"
    fi
}

test_version() {
    test_start "mars --version"

    local output
    output=$("$MARS_CMD" --version 2>&1) || true
    if echo "$output" | grep -q "^Mars v"; then
        test_pass
    else
        test_fail "version output format incorrect"
    fi
}

test_init_creates_files() {
    test_start "mars init - creates expected files"

    setup_test_dir

    # Run init with stdin to answer prompts
    echo -e "test-workspace\nn" | "$MARS_CMD" init > /dev/null 2>&1

    if [[ -f "mars.yaml" ]] && [[ -f ".gitignore" ]] && [[ -d "repos" ]]; then
        test_pass
    else
        test_fail "missing expected files/directories"
    fi
}

test_add_repo() {
    test_start "mars add - adds repository to config"

    setup_test_dir
    echo -e "add-test\nn" | "$MARS_CMD" init > /dev/null 2>&1

    "$MARS_CMD" add "git@github.com:test/repo.git" --tags "test,demo" > /dev/null 2>&1

    if grep -q "git@github.com:test/repo.git" mars.yaml; then
        test_pass
    else
        test_fail "repo not found in mars.yaml"
    fi
}

test_list_repos() {
    test_start "mars list - shows configured repos"

    setup_test_dir
    echo -e "list-test\nn" | "$MARS_CMD" init > /dev/null 2>&1
    "$MARS_CMD" add "git@github.com:test/repo1.git" > /dev/null 2>&1
    "$MARS_CMD" add "git@github.com:test/repo2.git" > /dev/null 2>&1

    local output
    output=$("$MARS_CMD" list 2>&1)

    if echo "$output" | grep -q "repo1" && echo "$output" | grep -q "repo2"; then
        test_pass
    else
        test_fail "repos not listed"
    fi
}

test_status_not_cloned() {
    test_start "mars status - shows not cloned"

    setup_test_dir
    echo -e "status-test\nn" | "$MARS_CMD" init > /dev/null 2>&1
    "$MARS_CMD" add "git@github.com:test/repo.git" > /dev/null 2>&1

    local output
    output=$("$MARS_CMD" status 2>&1)

    if echo "$output" | grep -q "not cloned"; then
        test_pass
    else
        test_fail "should show 'not cloned' status"
    fi
}

test_clone_with_real_repo() {
    test_start "mars clone - clones real repository"

    setup_test_dir
    echo -e "clone-test\nn" | "$MARS_CMD" init > /dev/null 2>&1

    # Use a small, public repo for testing
    "$MARS_CMD" add "https://github.com/octocat/Hello-World.git" > /dev/null 2>&1

    if "$MARS_CMD" clone 2>&1 | grep -q "Cloned"; then
        if [[ -d "repos/Hello-World/.git" ]]; then
            test_pass
        else
            test_fail "repo directory not created"
        fi
    else
        test_fail "clone command failed"
    fi
}

test_exec_command() {
    test_start "mars exec - runs command in repos"

    setup_test_dir
    echo -e "exec-test\nn" | "$MARS_CMD" init > /dev/null 2>&1
    "$MARS_CMD" add "https://github.com/octocat/Hello-World.git" > /dev/null 2>&1
    "$MARS_CMD" clone > /dev/null 2>&1

    local output
    output=$("$MARS_CMD" exec "git log -1 --oneline" 2>&1)

    if echo "$output" | grep -q "Success"; then
        test_pass
    else
        test_fail "exec should show success"
    fi
}

test_tag_filtering() {
    test_start "mars --tag filtering"

    setup_test_dir
    echo -e "tag-test\nn" | "$MARS_CMD" init > /dev/null 2>&1
    "$MARS_CMD" add "git@github.com:test/frontend.git" --tags "frontend" > /dev/null 2>&1
    "$MARS_CMD" add "git@github.com:test/backend.git" --tags "backend" > /dev/null 2>&1

    local output
    output=$("$MARS_CMD" list --tag frontend 2>&1)

    if echo "$output" | grep -q "frontend" && ! echo "$output" | grep -q "backend"; then
        test_pass
    else
        test_fail "tag filtering not working correctly"
    fi
}

# --- Run tests ---

printf "\n=== Mars CLI Integration Tests ===\n\n"

# Basic tests (no network)
test_help
test_version
test_init_creates_files
test_add_repo
test_list_repos
test_status_not_cloned
test_tag_filtering

# Network tests (optional - skip if offline)
if ping -c 1 github.com &> /dev/null; then
    printf "\n--- Network Tests ---\n\n"
    test_clone_with_real_repo
    test_exec_command
else
    printf "\n--- Skipping network tests (no connectivity) ---\n"
fi

printf "\n=== Results ===\n"
printf "Passed: %d/%d\n" "$TESTS_PASSED" "$TESTS_RUN"

if [[ $TESTS_FAILED -gt 0 ]]; then
    printf "Failed: %d\n" "$TESTS_FAILED"
    exit 1
fi

exit 0
