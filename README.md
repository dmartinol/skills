# Claude Code Skills

A collection of production-ready skills for [Claude Code](https://claude.com/claude-code) to enhance AI-assisted development workflows.

## Available Skills

### [MCP Server Description Generator](./mcp-server-generator/)

Automatically generates compliant `server.json` files for MCP (Model Context Protocol) servers following the [official MCP registry specification](https://github.com/modelcontextprotocol/registry/tree/main/docs/reference/server-json).

**Supports:**
- ✅ **Installable MCP Servers** - From Git repositories (NPM, PyPI, OCI, MCPB, NuGet packages)
- ✅ **Hosted/Remote MCP Services** - Accessible via URL endpoints (SSE, streamable-http)
- ✅ **Automated validation** - Built-in schema validation and compliance checking
- ✅ **Multiple transports** - stdio, SSE, streamable-http
- ✅ **Complex configurations** - Environment variables, package arguments, multiple packages

**Validation Status:** ✅ **Production-Ready**
- Tested against 9 diverse servers from 1,330-server official registry
- 55.6% perfect matches, all differences expected (version drift, schema evolution)
- See [validation report](./mcp-server-generator/validation/REPORT.md)

**Quick Start:**
```bash
# View the skill documentation
cat mcp-server-generator/SKILL.md

# Use the validation script
bash mcp-server-generator/validate-server-json.sh path/to/server.json

# See examples
ls mcp-server-generator/examples/
```

## Using These Skills

### With Claude Code

Skills in this repository are designed to be used with Claude Code. To use them:

1. Copy the skill directory to your project's `.claude/skills/` folder
2. Reference the skill in your Claude Code conversations
3. Claude will automatically load and execute the skill instructions

Example:
```bash
# Copy skill to your project
cp -r mcp-server-generator /your/project/.claude/skills/

# In Claude Code conversation:
"Generate an MCP server.json for https://github.com/example/my-server"
```

### Standalone Usage

Many skills include standalone scripts that can be used independently:

```bash
# MCP Server JSON validation
bash mcp-server-generator/validate-server-json.sh server.json
```

## Repository Structure

```
skills/
├── README.md                          # This file
├── LICENSE                            # Apache 2.0 License
│
└── mcp-server-generator/              # MCP Server Description Generator
    ├── README.md                      # Skill documentation
    ├── SKILL.md                       # Skill instructions for Claude
    ├── VERSION_TRACKING.md            # Schema version management
    ├── validate-server-json.sh        # Validation script
    │
    ├── examples/                      # Example outputs
    │   ├── testing-farm-mcp.json     # Multiple packages (PyPI + OCI)
    │   ├── cve-mcp.json              # Remote/hosted service
    │   └── spotdb.json               # OCI container
    │
    └── validation/                    # Test results
        ├── REPORT.md                  # Validation report
        ├── comparison-results.json    # Detailed comparison data
        ├── processing-results.json    # Test metadata
        └── cases/                     # 9 test cases
            ├── 01-hypertool-mcp/
            ├── 02-mcpcap/
            └── ...
```

## Contributing

Skills are welcome! When adding a new skill:

1. Create a new directory with the skill name
2. Include `README.md` and `SKILL.md`
3. Add validation tests if applicable
4. Update this main README with the skill description

## License

Apache 2.0 - See [LICENSE](LICENSE) file for details.

## Links

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [MCP Registry Specification](https://github.com/modelcontextprotocol/registry)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## Support

For issues or questions:
- Open an issue on this repository
- Check individual skill README files for specific documentation

---

**Built with Claude Code** 🤖
