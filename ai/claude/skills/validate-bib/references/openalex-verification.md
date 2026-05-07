# Metadata Verification

> Reference file for `$validate-bib`. Use when missing entries or suspicious metadata are found.

## Preferred: Biblio MCP Tools

**Always prefer MCP tools over the Python client** — they're faster, require no boilerplate, and query multiple sources.

| Tool | Use for |
|------|---------|
| `scholarly_verify_dois` | Batch-verify DOIs across OpenAlex + Scopus + WoS (up to 50 per call) |
| `scholarly_search` | Find a paper by title across all sources — useful when a cited key is missing |
| `openalex_lookup_doi` | Look up full metadata for a single DOI |
| `scholarly_similar_works` | Find related papers when a title search doesn't match exactly |

## Fallback: Direct OpenAlex API

If MCP is not configured, query OpenAlex directly via WebFetch or `curl`:

```bash
# Look up a specific DOI
curl "https://api.openalex.org/works/https://doi.org/10.1016/j.ejor.2024.01.001"

# Search by title to find the correct entry
curl "https://api.openalex.org/works?search=decision%20making%20under%20uncertainty&per-page=5"
```

Optional: if your repository already provides helper scripts, you may use them, but do not require fixed paths.

## When to use:

- A cited key is missing and you want to confirm whether the paper exists
- Year or author formatting looks suspicious and you want to cross-check
- The user asks to enrich `.bib` entries with verified metadata
- Batch DOI verification (use `scholarly_verify_dois` first; fallback to OpenAlex API + DOI resolver)

Do NOT use this by default — only when the report flags issues worth verifying.
