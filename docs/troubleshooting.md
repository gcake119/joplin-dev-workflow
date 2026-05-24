# Troubleshooting

Use `joplin-workflow-doctor` first. Default doctor mode is non-mutating: it checks local tools, clipboard access, Joplin Desktop Data API reachability, token authentication, and target notebook resolution without creating notes or folders.

```bash
joplin-workflow-doctor
```

For command-specific checks, use dry-run:

```bash
echo "Test content" | pbcopy
learn --dry-run "Test Article"
til --dry-run "Test TIL"
weekly --dry-run "Test Weekly"
```

## Joplin Data API Is Not Responding

Check Joplin Desktop first:

1. Open Joplin Desktop.
2. Enable **Tools > Options > Web Clipper > Enable Web Clipper Service**.
3. Run `joplin-workflow-doctor` again.

If you configured `JOPLIN_API_BASE_URL`, confirm it points to the active Web Clipper service. If it is empty, the workflow probes localhost ports from `JOPLIN_API_PORT_START` through `JOPLIN_API_PORT_END`.

```bash
JOPLIN_API_BASE_URL=""
JOPLIN_API_PORT_START="41184"
JOPLIN_API_PORT_END="41194"
```

## Token Problems

If doctor reports that the token is missing or invalid, copy the authorization token from Joplin Desktop Web Clipper settings into:

```bash
~/.config/joplin-workflow/config
```

Use:

```bash
JOPLIN_API_TOKEN="paste-token-here"
```

Do not commit real tokens. Debug output redacts the configured token before printing response snippets.

## Missing curl or jq

`curl` and `jq` are required in base mode.

```bash
curl --version
jq --version
```

Install examples:

```bash
# macOS
brew install jq

# Debian/Ubuntu
sudo apt install curl jq

# Fedora
sudo dnf install curl jq
```

## Clipboard Issues

Commands read note content from the clipboard. Doctor checks whether clipboard output is readable.

Default lookup order:

- `CLIPBOARD_CMD` from config
- `pbpaste` on macOS
- `xclip -selection clipboard -o` on Linux
- `xsel --clipboard --output` on Linux

Set an explicit command if auto-detection does not match your environment:

```bash
CLIPBOARD_CMD="wl-paste"
```

## Notebook Resolution

The workflow resolves notebooks ID-first:

1. If `NOTEBOOK_*_ID` is set, the Data API verifies that ID.
2. If no ID is set, it searches notebook titles across all paginated folder results.
3. If a title is duplicated, the command fails and prints matching hierarchy paths.

Prefer IDs for nested or duplicated notebooks:

```bash
NOTEBOOK_DAILY_ID="0123456789abcdef0123456789abcdef"
NOTEBOOK_POST_ID="fedcba9876543210fedcba9876543210"
NOTEBOOK_WEEKLY_ID="11112222333344445555666677778888"
```

To configure IDs from existing notebooks:

```bash
joplin-workflow-doctor --setup-existing
```

To create new empty defaults:

```bash
joplin-workflow-doctor --setup-create-defaults
```

`--setup-create-defaults` refuses to create duplicate titled notebooks. If a partial create fails, it reports folders already created and preserves unrelated config entries.

## Dry Run Still Fails

Dry-run still validates prerequisites. It may fail before writing when:

- the clipboard is empty
- the Data API token is missing or invalid
- Joplin Desktop Web Clipper is not reachable
- a configured notebook ID does not exist
- title fallback finds duplicate notebooks
- `til` finds multiple daily notes with the same title in the daily notebook

This is expected. Fix the reported setup issue, then run the same dry-run again.

## Debug Diagnostics

Enable debug output only while diagnosing:

```bash
DEBUG="true"
```

Debug output may include HTTP status and short response snippets. Configured tokens are redacted.

## Command Not Found

Confirm the installed commands are on `PATH`:

```bash
which learn til weekly joplin-workflow-doctor
```

If they are missing, rerun `./install.sh` from the repository root and reload your shell:

```bash
source ~/.zshrc
# or
source ~/.bashrc
```
