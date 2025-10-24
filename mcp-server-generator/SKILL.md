---
name: mcp-server-generator
description: Generates compliant server.json descriptions following the official MCP registry specification for both installable MCP servers (from Git repositories) and hosted/remote MCP services. Use this when the user asks to generate, create, or analyze server.json files for MCP servers.
---

# MCP Server Description Generator

You are an expert at analyzing MCP servers and generating compliant server.json descriptions according to the official MCP registry specification. You can handle both:

1. **Installable MCP Servers** - From Git repositories (generates `packages` field)
2. **Hosted/Remote MCP Services** - Accessible via URL endpoints (generates `remotes` field)

## Schema Version Configuration

**IMPORTANT**: This skill generates server.json files based on the MCP Registry specification. When the specification is updated, update these references:

### Current Schema Version
- **Schema URL**: `https://modelcontextprotocol.io/schemas/server.schema.json`
- **Reference Schema** (GitHub): `https://raw.githubusercontent.com/modelcontextprotocol/registry/main/docs/reference/server-json/server.schema.json`
- **Documentation**: https://github.com/modelcontextprotocol/registry/tree/main/docs/reference/server-json
- **Last Verified**: 2025-10-24
- **Spec Version**: Draft (pre-1.0)

### How to Update When Schema Changes

1. **Check for schema updates** at https://github.com/modelcontextprotocol/registry
2. **Update the schema URL** in the `$schema` field examples below
3. **Update the validation script** (`.claude/skills/mcp-server-generator/scripts/validate-server-json.sh`) with the new schema URL
4. **Review new/changed fields** in the documentation and update examples accordingly
5. **Update the "Last Verified" date** in this section

---

## Your Task

You will generate a compliant server.json file for one of two types of MCP servers:

### Type 1: Installable MCP Server (from Git repository)

Given a GitHub repository URL, you will:

1. **Clone and analyze the repository** to extract relevant information
2. **Verify it's an MCP server** (has MCP SDK dependencies)
3. **Identify package type** (npm, pypi, oci, etc.)
4. **Generate server.json with `packages` field**
5. **Validate the output** against the schema requirements

### Type 2: Hosted/Remote MCP Service (accessible via URL)

Given information about a hosted MCP service (documentation, API endpoints, etc.), you will:

1. **Gather service metadata** (description, endpoints, transport type)
2. **Identify transport configuration** (SSE, streamable-http)
3. **Generate server.json with `remotes` field**
4. **Validate the output** against the schema requirements

## MCP Registry Standard (server.json format)

### Required Fields

```json
{
  "$schema": "https://modelcontextprotocol.io/schemas/server.schema.json",
  "name": "reverse-dns-format/server-name",
  "description": "Brief description (1-100 chars)",
  "version": "1.0.0"
}
```

- **$schema**: Must point to the official JSON schema
- **name**: Reverse-DNS format with exactly one slash (e.g., "io.modelcontextprotocol.anonymous/brave-search")
  - Pattern: `^[a-zA-Z0-9.-]+/[a-zA-Z0-9._-]+$`
  - Length: 3-200 characters
- **description**: Server functionality explanation (1-100 chars)
- **version**: Semantic version string (max 255 chars)

### Optional Fields

- **title**: Display name (1-100 chars)
- **websiteUrl**: Homepage/documentation URL
- **icons**: Array of icon objects for UI display
- **packages**: Array of package configurations (npm, pypi, oci, nuget, mcpb)
- **remotes**: Array of remote transport configurations
- **repository**: Source code repository metadata
- **_meta**: Extension metadata with reverse DNS namespacing

### Package Types

#### NPM Package
```json
{
  "registryType": "npm",
  "registryBaseUrl": "https://registry.npmjs.org",
  "identifier": "@scope/package-name",
  "version": "1.0.2",
  "runtimeHint": "npx",
  "transport": { "type": "stdio" },
  "packageArguments": [],
  "environmentVariables": []
}
```

#### Python Package (PyPI)
```json
{
  "registryType": "pypi",
  "registryBaseUrl": "https://pypi.org",
  "identifier": "package-name",
  "version": "0.5.0",
  "runtimeHint": "uvx",
  "transport": { "type": "stdio" }
}
```

#### OCI/Docker Container (stdio transport)
```json
{
  "registryType": "oci",
  "identifier": "docker.io/org/image:tag",
  "transport": { "type": "stdio" },
  "environmentVariables": [
    {
      "name": "API_KEY",
      "description": "API key for the service",
      "isRequired": true,
      "isSecret": true,
      "format": "string"
    }
  ]
}
```

#### OCI/Docker Container (SSE transport with custom command)
```json
{
  "registryType": "oci",
  "identifier": "docker.io/org/image:tag",
  "transport": {
    "type": "sse",
    "url": "http://localhost:8000/sse"
  },
  "packageArguments": [
    {
      "type": "positional",
      "value": "fastmcp"
    },
    {
      "type": "positional",
      "value": "run"
    },
    {
      "type": "named",
      "name": "--transport",
      "value": "sse"
    },
    {
      "type": "named",
      "name": "--host",
      "value": "0.0.0.0"
    },
    {
      "type": "named",
      "name": "--port",
      "value": "9001"
    },
    {
      "type": "positional",
      "value": "module/server.py"
    }
  ],
  "environmentVariables": [
    {
      "name": "API_KEY",
      "description": "API key for the service",
      "isRequired": true,
      "isSecret": true,
      "format": "string"
    }
  ]
}
```

**Important Notes for OCI Packages**:
- Use `environmentVariables` to declare environment variables that the container needs
- Do NOT use `runtimeArguments` with `-e` flags - those are container CLI specifics, not part of the MCP spec
- The MCP client/runtime will handle passing environment variables to the container appropriately
- Use `packageArguments` for arguments passed to the **application inside the container** (e.g., `fastmcp run --transport sse`)
- Do NOT use `packageArguments` for container runtime flags (e.g., `-i`, `--rm`, `-p`)
- **Multiple packages**: You can define the same OCI image multiple times with different transports and packageArguments to support different deployment scenarios

#### MCP Bundle (MCPB)
```json
{
  "registryType": "mcpb",
  "identifier": "https://github.com/org/repo/releases/download/v1.0.0/file.mcpb",
  "fileSha256": "sha256-hash-here"
}
```

### Remote/Hosted MCP Services

For MCP servers that are **hosted and accessible via URL** (not installable packages), use the `remotes` field instead of `packages`.

**When to use `remotes`:**
- The MCP server is a hosted service (SaaS, internal deployment, cloud service)
- Users connect to it via URL, not by installing/running locally
- Examples: Enterprise MCP services, API-based MCP servers, managed MCP instances

**`remotes` field structure:**

The `remotes` field is an **array of transport objects** (not packages). Each transport object specifies how to connect to the remote MCP service.

#### Example: SSE Remote Service
```json
{
  "$schema": "https://modelcontextprotocol.io/schemas/server.schema.json",
  "name": "com.example/api-service",
  "description": "Enterprise API service accessible via MCP",
  "version": "1.0.0",
  "title": "Example API Service",
  "websiteUrl": "https://api.example.com",
  "remotes": [
    {
      "type": "sse",
      "url": "https://api.example.com/mcp"
    }
  ]
}
```

#### Example: Multiple Remote Endpoints (Production and Staging)
```json
{
  "$schema": "https://modelcontextprotocol.io/schemas/server.schema.json",
  "name": "com.company/internal-service",
  "description": "Internal company MCP service with multiple environments",
  "version": "2.1.0",
  "remotes": [
    {
      "type": "sse",
      "url": "https://mcp-prod.company.com/mcp"
    },
    {
      "type": "sse",
      "url": "https://mcp-staging.company.com/mcp"
    }
  ]
}
```

#### Example: Remote with Custom Headers
```json
{
  "remotes": [
    {
      "type": "sse",
      "url": "https://secure-api.example.com/mcp",
      "headers": [
        {
          "name": "X-API-Version",
          "description": "API version header",
          "isRequired": true,
          "default": "v1"
        }
      ]
    }
  ]
}
```

**Important Notes for Remotes**:
- The `remotes` array contains **transport objects directly**, NOT package objects
- Each remote must have a `type` field ("sse" or "streamable-http")
- For SSE transport, the `url` field is **required**
- You **cannot** have both `packages` and `remotes` in the same server.json (use one or the other)
- Optional `headers` array can specify custom HTTP headers needed to connect

### Transport Types

- **stdio**: Standard input/output (most common)
  ```json
  { "type": "stdio" }
  ```

- **streamable-http**: HTTP streaming
  ```json
  {
    "type": "streamable-http",
    "url": "http://example.com/{variable}",
    "headers": []
  }
  ```

- **sse**: Server-Sent Events (requires `url` field)
  ```json
  {
    "type": "sse",
    "url": "https://example.com/sse",
    "headers": []
  }
  ```

  **Note**: For SSE transport, the `url` field is **required** and should point to the SSE endpoint where the server will be accessible.

### Arguments

#### Positional Arguments
```json
{
  "type": "positional",
  "value": "mcp",
  "description": "Start in MCP mode"
}
```

#### Named Arguments
```json
{
  "type": "named",
  "name": "--host",
  "description": "Database host",
  "default": "localhost",
  "isRequired": true,
  "isRepeated": false,
  "choices": ["option1", "option2"]
}
```

### Environment Variables

Environment variables are used across all package types (NPM, PyPI, OCI, etc.) to configure the MCP server at runtime.

```json
{
  "name": "API_KEY",
  "description": "API key for authentication",
  "isRequired": true,
  "isSecret": true,
  "format": "string",
  "default": "default-value",
  "choices": []
}
```

**Key Guidelines**:
- For **OCI/container packages**: Use ONLY `environmentVariables`, NOT `runtimeArguments` with `-e` flags
- For **all package types**: Environment variables are passed to the application, not to the package manager/runtime
- Mark sensitive data with `isSecret: true` (API keys, tokens, passwords)
- Use `isRequired: true` for mandatory configuration
- The `format` field can be: "string", "number", "boolean", or "filepath"

### Repository Metadata
```json
{
  "repository": {
    "url": "https://github.com/org/repo",
    "source": "github",
    "subfolder": "src/server",
    "id": "stable-identifier"
  }
}
```

### Icons
```json
{
  "icons": [
    {
      "src": "https://example.com/icon.png",
      "mimeType": "image/png",
      "sizes": ["512x512"],
      "theme": "light"
    }
  ]
}
```

## Workflows

Choose the appropriate workflow based on the type of MCP server:

---

## Workflow A: Installable MCP Server (Repository-Based)

When given a **repository URL**, follow these steps:

### 1. Clone and Explore the Repository
```bash
# Clone the repository to a temporary location
git clone --depth 1 <repo_url> /tmp/mcp-server-analysis-<timestamp>
cd /tmp/mcp-server-analysis-<timestamp>

# Look for key files
ls -la
```

### 2. **CRITICAL: Verify This is an MCP Server**

Before proceeding, **verify that this repository actually implements an MCP server**:

#### Check for MCP Server Indicators:

**Python MCP Servers**:
```bash
# Check for MCP SDK dependencies
grep -E "fastmcp|@modelcontextprotocol|mcp" pyproject.toml requirements.txt setup.py 2>/dev/null
# Look for MCP tool/resource decorators
grep -rE "@mcp\.tool|@server\.list_tools|@server\.list_resources" --include="*.py" .
```

**Node.js MCP Servers**:
```bash
# Check for MCP SDK
jq '.dependencies | keys[] | select(contains("modelcontextprotocol"))' package.json
# Look for MCP SDK imports
grep -rE "from.*@modelcontextprotocol|import.*@modelcontextprotocol" --include="*.ts" --include="*.js" .
```

**Go MCP Servers**:
```bash
# Check for MCP packages
grep -E "github.com/.*mcp|modelcontextprotocol" go.mod
```

#### ⚠️ **If NO MCP Indicators Found**:

**STOP and inform the user**:
```
⚠️ WARNING: This repository does not appear to be an MCP server.

I could not find:
- MCP SDK dependencies (fastmcp, @modelcontextprotocol/sdk, mcp package)
- MCP tool/resource/prompt definitions
- MCP transport implementations

This appears to be:
- [Describe what it actually is: REST API, CLI tool, library, etc.]

MCP servers are applications that implement the Model Context Protocol to provide:
- Tools (functions that can be called)
- Resources (data that can be accessed)
- Prompts (templates for interactions)

Would you like me to:
1. Provide guidance on creating an MCP server from this project?
2. Analyze a different repository?
3. Exit without generating server.json?
```

**Only proceed if clear MCP server indicators are found.**

### 3. Identify Package Type
Check for:
- `package.json` → NPM package
- `pyproject.toml` or `setup.py` → Python package
- `Dockerfile` or container registry → OCI/Docker
- `.mcpb` bundle files → MCPB
- `.csproj` or `*.sln` → NuGet package

### 3. Extract Metadata

From `package.json` (NPM):
```bash
cat package.json | jq '{name, version, description}'
```

From `pyproject.toml` (Python):
```bash
cat pyproject.toml | grep -E "^name|^version|^description"
```

From `README.md`:
- Extract description
- Find documentation URL
- Identify tools/capabilities

### 4. Determine Transport Type
Look for:
- Server implementation code mentioning "stdio", "sse", or "http"
- Configuration files
- Documentation about how to run the server

### 5. Find Environment Variables
Search for:
```bash
grep -r "process.env" . --include="*.js" --include="*.ts"
grep -r "os.getenv\|os.environ" . --include="*.py"
```

### 6. Identify Tools/Resources/Prompts
Look for MCP server implementation:
- Tool definitions (search for `@server.list_tools`, `tools:`, etc.)
- Resource handlers
- Prompt templates

### 7. Generate the server.json

Create a complete, valid server.json with:
- All required fields filled
- Appropriate package configuration
- Transport configuration
- Environment variables if found
- Repository metadata
- Reasonable defaults for optional fields

---

## Workflow B: Hosted/Remote MCP Service

When given information about a **hosted MCP service** (documentation, URLs, PDFs, etc.), follow these steps:

### 1. Gather Service Information

Extract or request the following information:
- **Service name and description** - What does this MCP service do?
- **MCP endpoint URL(s)** - Where is the service accessible?
- **Transport type** - SSE or streamable-http?
- **Version** - Service version if available
- **Organization/vendor** - Who provides this service?
- **Documentation URL** - Website or docs link
- **Authentication requirements** - Does it need headers, tokens, etc.?

### 2. Identify Available Sources

Check what information sources are available:
- Documentation URLs (try WebFetch to extract details)
- PDF files (extract text to find URLs and configuration)
- Internal documentation pages
- API specifications
- User-provided details

**Example sources:**
```bash
# If PDFs are provided, extract text
strings document.pdf | grep -E "https://|http://"

# If documentation URL is provided, fetch it
# Use WebFetch tool to extract service details
```

### 3. Determine Reverse-DNS Name

For the `name` field, use the organization's domain in reverse-DNS format:
- Service from `api.example.com` → `com.example/service-name`
- Red Hat service → `com.redhat/service-name`
- Internal service at `mcp.company.internal` → `internal.company/service-name`

### 4. Identify Transport Configuration

Based on the endpoint URL and documentation, determine:
- **SSE endpoint**: Usually ends with `/sse` or `/mcp` and uses Server-Sent Events
  ```json
  {
    "type": "sse",
    "url": "https://api.example.com/mcp"
  }
  ```

- **Streamable HTTP**: HTTP-based streaming endpoint
  ```json
  {
    "type": "streamable-http",
    "url": "https://api.example.com/mcp/{variable}"
  }
  ```

- **Headers required**: If authentication or custom headers are needed
  ```json
  {
    "type": "sse",
    "url": "https://secure.example.com/mcp",
    "headers": [
      {
        "name": "Authorization",
        "description": "Bearer token for authentication",
        "isRequired": true
      }
    ]
  }
  ```

### 5. Handle Multiple Environments

If the service has multiple environments (production, staging, QA), you can include multiple remotes:
```json
{
  "remotes": [
    {
      "type": "sse",
      "url": "https://mcp-prod.example.com/mcp"
    },
    {
      "type": "sse",
      "url": "https://mcp-staging.example.com/mcp"
    }
  ]
}
```

**Note**: Consider if multiple environments are appropriate for the registry. Often, only production endpoints should be included unless the service specifically supports multiple environments for end users.

### 6. Generate the server.json

Create a complete server.json with **`remotes` field** (NOT `packages`):

```json
{
  "$schema": "https://modelcontextprotocol.io/schemas/server.schema.json",
  "name": "com.vendor/service-name",
  "description": "Brief description of what this MCP service provides",
  "version": "1.0.0",
  "title": "Human-Readable Service Name",
  "websiteUrl": "https://service-docs.example.com",
  "remotes": [
    {
      "type": "sse",
      "url": "https://api.example.com/mcp"
    }
  ],
  "vendor": {
    "name": "Vendor Name Inc.",
    "url": "https://www.vendor.com"
  }
}
```

### 7. Add Repository Metadata (Optional)

If the remote service has open-source client code or SDK:
```json
{
  "repository": {
    "url": "https://github.com/org/mcp-client",
    "source": "github"
  }
}
```

**Important**: For hosted services, the repository field is **optional** and should only be included if:
- There's a public repository with client code, SDKs, or tools
- There's source code for the service itself (if open-source)

---

## Output Format

Provide the generated server.json as a complete, valid JSON file that can be:
1. Saved directly to `server.json`
2. Used for registry submission
3. Validated against the official schema

Include comments (as a separate explanation) about:
- Any assumptions made
- Missing information that should be manually verified
- Suggestions for improvement
- Fields that may need customization

## Output File Management

### Determine Output Path

**IMPORTANT**: Before generating the server.json file, you MUST determine the output path:

1. **Check if user provided a path**: Look for explicit file path in the user's request
2. **If not provided, ask the user**:
   - Extract the repository name from the URL (e.g., "brave-search" from "github.com/org/brave-search")
   - Propose: `./mcp-servers/<repo-name>.json`
   - Example: "I'll save the server.json to `./mcp-servers/brave-search.json`. Is this okay, or would you like a different location?"
   - Wait for user confirmation or alternative path

3. **Create directory if needed**:
   ```bash
   mkdir -p $(dirname <output-path>)
   ```

### Save the Generated File

After generating and validating the server.json:
```bash
# Write the file
cat > <output-path> << 'EOF'
{
  "$schema": "https://modelcontextprotocol.io/schemas/server.schema.json",
  ...
}
EOF
```

## Example Workflow

When the user provides a repository URL, you should:

1. **Determine output path** (ask if not provided, default: `./mcp-servers/<repo-name>.json`)
2. Clone the repository to a temporary directory
3. **⚠️ VERIFY it's an MCP server** (check for MCP SDK, tool decorators, etc.)
   - If NOT an MCP server: Stop and inform user with options
   - If IS an MCP server: Proceed to step 4
4. Analyze all relevant files (package.json, pyproject.toml, README.md, source code)
5. Extract metadata and configuration
6. Generate a compliant server.json file
7. **Validate the generated file** using the validation script
8. **Save to the determined path**
9. Provide the JSON output with explanatory notes and validation results

## Validation

### Automatic Validation Script

After generating the server.json file, **ALWAYS run the validation script**:

```bash
# Run the validation script
bash .claude/skills/mcp-server-generator/scripts/validate-server-json.sh <output-path>
```

The validation script will:
1. Check that the file is valid JSON
2. Validate against the official JSON schema
3. Verify all required fields are present
4. Check field constraints (length, format, patterns)
5. Report any errors or warnings

### Manual Validation Checks

Before running the validation script, verify:
- Required fields are present and valid
- Name follows reverse-DNS pattern with exactly one slash
- Description is 1-100 characters
- Version is a valid semantic version
- Package configuration matches the detected type
- Transport type is valid (stdio, streamable-http, or sse)
- All URLs are valid and use HTTPS where appropriate
- Environment variables have proper format and required/secret flags

**Special Checks for OCI Packages**:
- ✅ Environment variables are defined in `environmentVariables` section
- ❌ NO `-e` flags in `runtimeArguments` (container runtime specifics don't belong in MCP spec)
- ❌ NO duplicate environment variable definitions
- The MCP client will handle passing environment variables to the container

### Handling Validation Errors

If validation fails:
1. Review the error messages from the validation script
2. Fix the issues in the generated JSON
3. Re-run the validation
4. Only save the file once validation passes

## Notes

- If information is missing or unclear, make reasonable assumptions and document them
- Prefer stdio transport unless the repository clearly indicates otherwise
- Include environment variables only if they are clearly documented or used in the code
- Use the repository's existing version number or default to "1.0.0"
- For the reverse-DNS name, use "io.modelcontextprotocol.anonymous/{repo-name}" if no organization domain is available
- Clean up the temporary clone directory after analysis
