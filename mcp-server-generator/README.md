# MCP Server Description Generator Skill

This skill helps you automatically generate compliant `server.json` files for both **installable MCP servers** (from Git repositories) and **hosted/remote MCP services** (accessible via URL endpoints).

## Purpose

The MCP Server Description Generator creates standards-compliant `server.json` files according to the [official MCP registry specification](https://github.com/modelcontextprotocol/registry/tree/main/docs/reference/server-json).

It handles two types of MCP servers:
1. **Installable MCP Servers** - Analyzes Git repositories and generates `packages` field
2. **Hosted/Remote MCP Services** - Analyzes service documentation and generates `remotes` field

## When to Use

Use this skill when you need to:
- Generate a `server.json` file for an MCP server repository
- Create registry entries for hosted/remote MCP services
- Validate that a server.json conforms to the standard
- Extract metadata from an MCP server codebase
- Document MCP services accessible via URL endpoints

## How It Works

The skill supports two workflows:

### Workflow A: Installable MCP Server (Repository-Based)

1. **Prompt for output location** (default: `./mcp-servers/<repo-name>.json`)
2. **Clone the repository** (shallow clone to /tmp)
3. **Verify it's an MCP server** (checks for MCP SDK dependencies)
4. **Identify the package type** (NPM, Python, Docker, etc.)
5. **Extract metadata** from package manifests (package.json, pyproject.toml, etc.)
6. **Analyze the codebase** for:
   - Transport type (stdio, sse, streamable-http)
   - Environment variables
   - Tool definitions
   - Configuration requirements
7. **Generate server.json with `packages` field**
8. **Validate** the output using the validation script
9. **Save the file** to the specified location
10. **Clean up** temporary files

### Workflow B: Hosted/Remote MCP Service

1. **Prompt for output location** (default: `./mcp-servers/<service-name>.json`)
2. **Gather service information** from:
   - Documentation URLs (using WebFetch)
   - PDF files (text extraction)
   - User-provided details
3. **Extract metadata**:
   - Service name and description
   - MCP endpoint URL(s)
   - Transport type (SSE, streamable-http)
   - Organization/vendor information
4. **Determine reverse-DNS naming** from domain
5. **Identify transport configuration** and headers
6. **Generate server.json with `remotes` field**
7. **Validate** the output using the validation script
8. **Save the file** to the specified location

## Usage Examples

### Repository-Based MCP Server

```
Generate a server.json for https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search
```

```
Create a server.json for the MCP server at https://github.com/example/my-mcp-server
and include all optional fields
```

### Hosted/Remote MCP Service

```
Generate a server.json for the CVE MCP Server documented in the ./cve/ folder
```

```
Create a server.json for the hosted MCP service at https://api.example.com/mcp
```

```
I have documentation PDFs for our internal MCP service. Generate a server.json from them.
```

### Analysis Only
```
Analyze https://github.com/example/server and tell me what would go in the server.json
```

## Output

The skill generates:

1. **Complete server.json** file saved to the specified location (default: `./mcp-servers/<repo-name>.json`)
2. **Validation report** from the automated validation script
3. **Explanatory notes** including:
   - Assumptions made during generation
   - Fields that may need manual verification
   - Suggestions for improvement
   - Missing information warnings
   - Validation results and any errors

## Validation

The skill includes an automated validation script ([`scripts/validate-server-json.sh`](scripts/validate-server-json.sh)) that:

- ✓ Checks JSON syntax validity
- ✓ Downloads and validates against the official JSON schema
- ✓ Verifies all required fields are present
- ✓ Validates field constraints (length, format, patterns)
- ✓ Checks reverse-DNS naming format
- ✓ Validates transport types
- ✓ Reports detailed error messages

### Running Validation Manually

```bash
bash .claude/skills/mcp-server-generator/scripts/validate-server-json.sh path/to/server.json
```

### Validation Requirements

The validation script requires:
- `jq` - JSON processor (install: `brew install jq`)
- `python3` with `jsonschema` - For schema validation (install: `pip3 install jsonschema`)

If Python jsonschema is not available, the script will skip schema validation but still perform basic field checks.

## Supported Package Types (Workflow A)

For installable MCP servers from repositories:

- **NPM** - Node.js packages
- **PyPI** - Python packages
- **OCI/Docker** - Container images (environment variables only, no `-e` runtime flags)
- **MCPB** - MCP bundles
- **NuGet** - .NET packages

### Important Note for OCI Packages

For OCI/container packages, the skill correctly generates:
- ✅ `environmentVariables` section for runtime configuration
- ❌ NO `runtimeArguments` with `-e` flags (those are container CLI specifics)

The MCP client/runtime handles passing environment variables to containers appropriately.

## Supported Transports

### For Packages (Workflow A)
- **stdio** - Standard input/output (default for installable packages)
- **sse** - Server-Sent Events (with `url` field for containers)

### For Remotes (Workflow B)
- **sse** - Server-Sent Events (most common for hosted services)
- **streamable-http** - HTTP streaming

## Server.json Schema Compliance

The generated files comply with the official MCP registry specification:
- **Schema**: `https://modelcontextprotocol.io/schemas/server.schema.json`
- **Spec Version**: Draft (pre-1.0) - Last verified: 2025-10-24
- **Required fields**: `$schema`, `name`, `description`, `version`
- **Reverse-DNS naming**: `domain.tld/server-name`
- **Validation**: All fields validated against schema constraints

**Schema Version Tracking**: See [VERSION_TRACKING.md](VERSION_TRACKING.md) for schema version information and update procedures.

## Notes

- The skill makes intelligent assumptions when information is incomplete
- Environment variables are only included if clearly documented
- Repository metadata is automatically populated
- Version numbers are extracted from package manifests
- Cleanup of temporary directories is automatic

## Related Documentation

- [MCP Registry Specification](https://github.com/modelcontextprotocol/registry/tree/main/docs/reference/server-json)
- [MCP Server.json Schema](https://modelcontextprotocol.io/schemas/server.schema.json)
- [Generic Server JSON Format](https://github.com/modelcontextprotocol/registry/blob/main/docs/reference/server-json/generic-server-json.md)
- [Version Tracking](VERSION_TRACKING.md) - Schema version tracking and update procedures

## Maintaining the Skill

When the MCP registry schema is updated:

1. Check [VERSION_TRACKING.md](VERSION_TRACKING.md) for the update checklist
2. Update schema URLs and examples in [SKILL.md](SKILL.md)
3. Update the validation script with new schema URL
4. Test with existing server.json files to ensure compatibility
5. Document changes in VERSION_TRACKING.md

The skill is designed to be easily updated as the MCP specification evolves.
