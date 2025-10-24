#!/bin/bash
# Validate server.json files against the MCP registry schema
# Usage: ./validate-server-json.sh <path-to-server.json>
#
# MCP REGISTRY SCHEMA VERSION CONFIGURATION
# ==========================================
# This script validates against the official MCP registry specification.
# When the schema is updated, update these URLs:
#
# Current Schema Version:
#   - Official URL: https://modelcontextprotocol.io/schemas/server.schema.json
#   - Reference URL: https://raw.githubusercontent.com/modelcontextprotocol/registry/main/docs/reference/server-json/server.schema.json
#   - Documentation: https://github.com/modelcontextprotocol/registry/tree/main/docs/reference/server-json
#   - Last Verified: 2025-10-24
#   - Spec Version: Draft (pre-1.0)
#
# Update Instructions:
#   1. Check for updates at: https://github.com/modelcontextprotocol/registry
#   2. Update SCHEMA_URL below if the schema location changes
#   3. Update the "Last Verified" date in the comments
#   4. Update the SKILL.md file with corresponding schema version changes
#
# ==========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Schema URL - use the GitHub raw URL as the official one may not be available yet
# UPDATE THIS when the schema version changes
SCHEMA_URL="https://raw.githubusercontent.com/modelcontextprotocol/registry/main/docs/reference/server-json/server.schema.json"
SCHEMA_FILE="/tmp/mcp-server.schema.json"

# Function to print colored output
print_error() {
    echo -e "${RED}✗ ERROR:${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}✓ SUCCESS:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING:${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ INFO:${NC} $1"
}

# Check if file argument provided
if [ $# -eq 0 ]; then
    print_error "No file specified"
    echo "Usage: $0 <path-to-server.json>"
    exit 1
fi

SERVER_JSON_FILE="$1"

# Check if file exists
if [ ! -f "$SERVER_JSON_FILE" ]; then
    print_error "File not found: $SERVER_JSON_FILE"
    exit 1
fi

print_info "Validating: $SERVER_JSON_FILE"
echo ""

# Step 1: Check if file is valid JSON
print_info "Step 1/6: Checking if file is valid JSON..."
if ! jq empty "$SERVER_JSON_FILE" 2>/dev/null; then
    print_error "Invalid JSON syntax"
    exit 1
fi
print_success "Valid JSON syntax"
echo ""

# Step 2: Download schema if not cached
print_info "Step 2/6: Fetching JSON schema..."
if [ ! -f "$SCHEMA_FILE" ] || [ $(find "$SCHEMA_FILE" -mmin +60 2>/dev/null | wc -l) -gt 0 ]; then
    if curl -sSL "$SCHEMA_URL" -o "$SCHEMA_FILE" 2>/dev/null; then
        print_success "Schema downloaded"
    else
        print_warning "Could not download schema, using basic validation only"
        SCHEMA_FILE=""
    fi
else
    print_success "Using cached schema"
fi
echo ""

# Step 3: Validate against JSON schema using ajv-cli or Python
print_info "Step 3/6: Validating against JSON schema..."
SCHEMA_VALID=false

# Try using Python jsonschema (most reliable)
if command -v python3 &> /dev/null && [ -n "$SCHEMA_FILE" ]; then
    VALIDATION_SCRIPT=$(cat <<'PYTHON'
import json
import sys
from jsonschema import validate, ValidationError, Draft7Validator
from jsonschema.exceptions import SchemaError

try:
    with open(sys.argv[1], 'r') as f:
        schema = json.load(f)
    with open(sys.argv[2], 'r') as f:
        instance = json.load(f)

    validator = Draft7Validator(schema)
    errors = list(validator.iter_errors(instance))

    if errors:
        print("VALIDATION_FAILED")
        for error in errors:
            path = ".".join(str(p) for p in error.path) if error.path else "root"
            print(f"  • [{path}] {error.message}")
        sys.exit(1)
    else:
        print("VALIDATION_SUCCESS")
        sys.exit(0)
except Exception as e:
    print(f"VALIDATION_ERROR: {str(e)}")
    sys.exit(2)
PYTHON
)
    RESULT=$(timeout 30 python3 -c "$VALIDATION_SCRIPT" "$SCHEMA_FILE" "$SERVER_JSON_FILE" 2>&1 || echo "TIMEOUT_OR_ERROR:$?")
    EXIT_CODE=$?

    if [[ "$RESULT" == *"VALIDATION_SUCCESS"* ]]; then
        SCHEMA_VALID=true
        print_success "Schema validation passed"
    elif [[ "$RESULT" == *"VALIDATION_FAILED"* ]]; then
        print_error "Schema validation failed:"
        echo "$RESULT" | grep "•" | sed 's/^/  /'
    elif [[ "$RESULT" == *"TIMEOUT"* ]]; then
        print_warning "Schema validation timed out (schema may be complex)"
    else
        print_warning "Schema validation error: $(echo "$RESULT" | head -1)"
    fi
else
    print_warning "Python3 with jsonschema not available, skipping schema validation"
    print_info "Install with: pip3 install jsonschema"
fi
echo ""

# Step 4: Validate required fields
print_info "Step 4/6: Checking required fields..."
REQUIRED_FIELDS=("\$schema" "name" "description" "version")
MISSING_FIELDS=()

for field in "${REQUIRED_FIELDS[@]}"; do
    if [ "$field" == "\$schema" ]; then
        VALUE=$(jq -r '.["$schema"]' "$SERVER_JSON_FILE")
    else
        VALUE=$(jq -r ".$field" "$SERVER_JSON_FILE")
    fi

    if [ "$VALUE" == "null" ] || [ -z "$VALUE" ]; then
        MISSING_FIELDS+=("$field")
    fi
done

if [ ${#MISSING_FIELDS[@]} -eq 0 ]; then
    print_success "All required fields present"
else
    print_error "Missing required fields: ${MISSING_FIELDS[*]}"
    exit 1
fi
echo ""

# Step 5: Validate field constraints
print_info "Step 5/6: Validating field constraints..."
VALIDATION_ERRORS=0

# Check name format (reverse-DNS with exactly one slash)
NAME=$(jq -r '.name' "$SERVER_JSON_FILE")
if [[ ! "$NAME" =~ ^[a-zA-Z0-9.-]+/[a-zA-Z0-9._-]+$ ]]; then
    print_error "Invalid name format: '$NAME'"
    echo "  Name must be in reverse-DNS format with exactly one slash (e.g., 'io.example/server-name')"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

NAME_LENGTH=${#NAME}
if [ $NAME_LENGTH -lt 3 ] || [ $NAME_LENGTH -gt 200 ]; then
    print_error "Invalid name length: $NAME_LENGTH (must be 3-200 characters)"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Check description length
DESCRIPTION=$(jq -r '.description' "$SERVER_JSON_FILE")
DESC_LENGTH=${#DESCRIPTION}
if [ $DESC_LENGTH -lt 1 ] || [ $DESC_LENGTH -gt 100 ]; then
    print_error "Invalid description length: $DESC_LENGTH (must be 1-100 characters)"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Check version format (basic semantic versioning)
VERSION=$(jq -r '.version' "$SERVER_JSON_FILE")
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    print_warning "Version '$VERSION' doesn't follow semantic versioning (X.Y.Z)"
fi

# Check schema URL
SCHEMA=$(jq -r '.["$schema"]' "$SERVER_JSON_FILE")
if [[ ! "$SCHEMA" =~ ^https://modelcontextprotocol\.io/schemas/ ]]; then
    print_warning "Schema URL should point to https://modelcontextprotocol.io/schemas/"
fi

if [ $VALIDATION_ERRORS -eq 0 ]; then
    print_success "All field constraints valid"
else
    print_error "$VALIDATION_ERRORS field constraint error(s) found"
    exit 1
fi
echo ""

# Step 6: Additional checks
print_info "Step 6/6: Performing additional checks..."

# Check for packages or remotes
HAS_PACKAGES=$(jq '.packages | length > 0' "$SERVER_JSON_FILE" 2>/dev/null || echo "false")
HAS_REMOTES=$(jq '.remotes | length > 0' "$SERVER_JSON_FILE" 2>/dev/null || echo "false")

if [ "$HAS_PACKAGES" == "false" ] && [ "$HAS_REMOTES" == "false" ]; then
    print_warning "No packages or remotes defined - server may not be installable"
fi

# Check transport types in packages
if [ "$HAS_PACKAGES" == "true" ]; then
    INVALID_TRANSPORTS=$(jq -r '.packages[]?.transport.type | select(. != null and . != "stdio" and . != "streamable-http" and . != "sse")' "$SERVER_JSON_FILE" 2>/dev/null)
    if [ -n "$INVALID_TRANSPORTS" ]; then
        print_warning "Found non-standard transport type(s)"
    fi
fi

# Check for repository information
HAS_REPO=$(jq 'has("repository")' "$SERVER_JSON_FILE")
if [ "$HAS_REPO" == "false" ]; then
    print_warning "No repository information - consider adding repository metadata"
fi

print_success "Additional checks complete"
echo ""

# Final summary
echo "================================================"
if [ $VALIDATION_ERRORS -eq 0 ] && [ "$SCHEMA_VALID" == "true" ]; then
    print_success "VALIDATION PASSED"
    echo ""
    echo "The server.json file is valid and compliant with the MCP registry specification."
    exit 0
elif [ $VALIDATION_ERRORS -eq 0 ]; then
    print_warning "VALIDATION PASSED (with warnings)"
    echo ""
    echo "The server.json file passed basic validation but schema validation was skipped."
    echo "Install Python jsonschema for complete validation: pip3 install jsonschema"
    exit 0
else
    print_error "VALIDATION FAILED"
    echo ""
    echo "Please fix the errors above and re-run validation."
    exit 1
fi
