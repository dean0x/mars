#!/usr/bin/env bash
# Test suite for yaml.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/yaml.sh"

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
    local msg="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        test_fail "expected '$expected', got '$actual' ${msg}"
        return 1
    fi
}

# --- Tests ---

test_path_from_url() {
    test_start "yaml_path_from_url - SSH URL"
    local result
    result=$(yaml_path_from_url "git@github.com:org/myrepo.git")
    assert_eq "myrepo" "$result" && test_pass

    test_start "yaml_path_from_url - HTTPS URL"
    result=$(yaml_path_from_url "https://github.com/org/myrepo.git")
    assert_eq "myrepo" "$result" && test_pass

    test_start "yaml_path_from_url - No .git suffix"
    result=$(yaml_path_from_url "git@github.com:org/myrepo")
    assert_eq "myrepo" "$result" && test_pass
}

test_parse_simple() {
    test_start "yaml_parse - simple config"

    local test_file="/tmp/mars/mars_test_$$.yaml"
    cat > "$test_file" << 'EOF'
version: 1

workspace:
  name: "test-workspace"

repos:
  - url: git@github.com:org/repo1.git
    tags: [frontend, web]
  - url: git@github.com:org/repo2.git
    path: custom-path
    tags: [backend]

defaults:
  branch: develop
EOF

    yaml_parse "$test_file"

    assert_eq "test-workspace" "$YAML_WORKSPACE_NAME" || { rm "$test_file"; return 1; }
    assert_eq "develop" "$YAML_DEFAULTS_BRANCH" || { rm "$test_file"; return 1; }
    assert_eq "2" "$YAML_REPO_COUNT" || { rm "$test_file"; return 1; }

    # Check first repo
    assert_eq "git@github.com:org/repo1.git" "${YAML_REPO_URLS[0]}" || { rm "$test_file"; return 1; }
    assert_eq "repo1" "${YAML_REPO_PATHS[0]}" || { rm "$test_file"; return 1; }
    assert_eq "frontend,web" "${YAML_REPO_TAGS[0]}" || { rm "$test_file"; return 1; }

    # Check second repo
    assert_eq "custom-path" "${YAML_REPO_PATHS[1]}" || { rm "$test_file"; return 1; }
    assert_eq "backend" "${YAML_REPO_TAGS[1]}" || { rm "$test_file"; return 1; }

    rm "$test_file"
    test_pass
}

test_get_repos_filter() {
    test_start "yaml_get_repos - filter by tag"

    local test_file="/tmp/mars/mars_test_$$.yaml"
    cat > "$test_file" << 'EOF'
version: 1
workspace:
  name: test
repos:
  - url: git@github.com:org/repo1.git
    tags: [frontend]
  - url: git@github.com:org/repo2.git
    tags: [backend]
  - url: git@github.com:org/repo3.git
    tags: [frontend, api]
defaults:
  branch: main
EOF

    yaml_parse "$test_file"

    # Filter by frontend - should get 2
    local frontend_repos
    frontend_repos=$(yaml_get_repos "frontend")
    local frontend_count=0
    while IFS= read -r line; do
        [[ -n "$line" ]] && frontend_count=$((frontend_count + 1))
    done <<< "$frontend_repos"
    assert_eq "2" "$frontend_count" || { rm "$test_file"; return 1; }

    # Filter by backend - should get 1
    local backend_repos
    backend_repos=$(yaml_get_repos "backend")
    local backend_count=0
    while IFS= read -r line; do
        [[ -n "$line" ]] && backend_count=$((backend_count + 1))
    done <<< "$backend_repos"
    assert_eq "1" "$backend_count" || { rm "$test_file"; return 1; }

    rm "$test_file"
    test_pass
}

test_write_yaml() {
    test_start "yaml_write - roundtrip"

    # Setup
    YAML_WORKSPACE_NAME="roundtrip-test"
    YAML_DEFAULTS_BRANCH="main"
    YAML_REPO_COUNT=1
    YAML_REPO_URLS=("git@github.com:test/repo.git")
    YAML_REPO_PATHS=("repo")
    YAML_REPO_TAGS=("test,demo")

    local test_file="/tmp/mars/mars_test_$$.yaml"
    yaml_write "$test_file"

    # Parse it back
    yaml_parse "$test_file"

    assert_eq "roundtrip-test" "$YAML_WORKSPACE_NAME" || { rm "$test_file"; return 1; }
    assert_eq "test,demo" "${YAML_REPO_TAGS[0]}" || { rm "$test_file"; return 1; }

    rm "$test_file"
    test_pass
}

test_add_repo() {
    test_start "yaml_add_repo"

    # Reset
    YAML_REPO_COUNT=0
    YAML_REPO_URLS=()
    YAML_REPO_PATHS=()
    YAML_REPO_TAGS=()

    yaml_add_repo "git@github.com:org/newrepo.git" "" "newtag"

    assert_eq "1" "$YAML_REPO_COUNT" || return 1
    assert_eq "newrepo" "${YAML_REPO_PATHS[0]}" || return 1
    assert_eq "newtag" "${YAML_REPO_TAGS[0]}" || return 1

    test_pass
}

# --- Run tests ---

printf "\n=== YAML Parser Tests ===\n\n"

test_path_from_url
test_parse_simple
test_get_repos_filter
test_write_yaml
test_add_repo

printf "\n=== Results ===\n"
printf "Passed: %d/%d\n" "$TESTS_PASSED" "$TESTS_RUN"

if [[ $TESTS_FAILED -gt 0 ]]; then
    printf "Failed: %d\n" "$TESTS_FAILED"
    exit 1
fi

exit 0
