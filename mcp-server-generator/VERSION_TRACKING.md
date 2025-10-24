# MCP Registry Schema Version Tracking

This document tracks the MCP Registry specification version used by the MCP Server Description Generator skill.

## Current Schema Version

| Property | Value |
|----------|-------|
| **Schema URL** | `https://modelcontextprotocol.io/schemas/server.schema.json` |
| **Reference Schema (GitHub)** | `https://raw.githubusercontent.com/modelcontextprotocol/registry/main/docs/reference/server-json/server.schema.json` |
| **Documentation** | https://github.com/modelcontextprotocol/registry/tree/main/docs/reference/server-json |
| **Spec Version** | Draft (pre-1.0) |
| **Last Verified** | 2025-10-24 |
| **Last Updated** | 2025-10-24 |

## Schema Change History

| Date | Version | Changes | Updated By |
|------|---------|---------|------------|
| 2025-10-24 | Draft (Initial) | Initial skill creation with schema validation | Claude Code |

## Update Checklist

When the MCP Registry schema is updated, follow these steps:

### 1. Check for Updates
- [ ] Visit https://github.com/modelcontextprotocol/registry
- [ ] Check for new releases or schema changes
- [ ] Review CHANGELOG.md in the registry repository
- [ ] Check for schema version announcements

### 2. Update Files

- [ ] **SKILL.md**
  - [ ] Update "Schema Version Configuration" section
  - [ ] Update `$schema` URL in all JSON examples
  - [ ] Update "Last Verified" date
  - [ ] Update "Spec Version" if applicable
  - [ ] Review and update field examples for any new/changed fields

- [ ] **validate-server-json.sh**
  - [ ] Update `SCHEMA_URL` variable
  - [ ] Update "Last Verified" date in header comments
  - [ ] Update "Spec Version" in header comments
  - [ ] Review validation logic for any schema changes

- [ ] **VERSION_TRACKING.md** (this file)
  - [ ] Update "Current Schema Version" table
  - [ ] Add entry to "Schema Change History"
  - [ ] Document any breaking changes

- [ ] **README.md**
  - [ ] Update schema version references if mentioned
  - [ ] Update examples if schema changed

### 3. Test Changes

- [ ] Regenerate an existing server.json to verify compatibility
- [ ] Run validation script on test files
- [ ] Verify all required fields are still correct
- [ ] Check that new optional fields are documented

### 4. Document Changes

- [ ] Update this file with change summary
- [ ] Note any breaking changes
- [ ] Update examples to use new fields if applicable

## Key Files to Update

| File | Location | What to Update |
|------|----------|----------------|
| **SKILL.md** | `.claude/skills/mcp-server-generator/SKILL.md` | Schema URLs, examples, field definitions |
| **validate-server-json.sh** | `.claude/skills/mcp-server-generator/scripts/validate-server-json.sh` | Schema URL, validation logic |
| **VERSION_TRACKING.md** | `.claude/skills/mcp-server-generator/VERSION_TRACKING.md` | Version table, change history |
| **README.md** | `.claude/skills/mcp-server-generator/README.md` | Schema references in docs |

## Monitoring for Updates

### Official Sources
- **Registry Repository**: https://github.com/modelcontextprotocol/registry
  - Watch for new releases
  - Monitor `docs/reference/server-json/` directory
  - Check CHANGELOG.md

- **MCP Specification**: https://spec.modelcontextprotocol.io/
  - Check for registry specification updates
  - Review roadmap for upcoming changes

- **Community Channels**:
  - MCP Discord: Announcements about spec changes
  - GitHub Discussions: Schema-related discussions

## Breaking Changes

Document any breaking changes here when updating:

### [Version] - [Date]
- **Breaking Change**: Description of what changed
- **Migration**: How to update existing server.json files
- **Impact**: Which fields/features are affected

---

## Notes

- The schema is currently in **draft** status (pre-1.0)
- Expect potential breaking changes until v1.0 is released
- Always validate generated files after schema updates
- Keep this document updated with every schema version change
