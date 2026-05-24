# desktop-data-api-base-mode Specification

## Purpose

Define the default Joplin Desktop Data API write path for the core workflow commands, including connection setup, notebook resolution, note writes, sync messaging, and documentation alignment.

## Requirements

### Requirement: Data API is the base write adapter

The workflow commands SHALL use Joplin Desktop Data API as the default write adapter. The commands MUST NOT require the Joplin CLI command when `JOPLIN_WRITE_ADAPTER` is `data_api` or unset.

#### Scenario: learn creates a note through Data API

- **WHEN** the user runs `learn "Understanding React Hooks"` with non-empty clipboard content and a resolvable post notebook
- **THEN** the system SHALL create a Joplin note through Data API with title `Understanding React Hooks`, the configured post folder as `parent_id`, and the learning article body template

#### Scenario: til appends through Data API

- **WHEN** the user runs `til "Promise.all behavior"` with non-empty clipboard content and today's note already exists in the configured daily folder
- **THEN** the system SHALL read the existing note body through Data API and update that note body with one appended TIL block

#### Scenario: weekly creates a note through Data API

- **WHEN** the user runs `weekly "W07 Learning Summary"` with non-empty clipboard content and a resolvable weekly notebook
- **THEN** the system SHALL create a Joplin note through Data API with the weekly review body template and the computed Monday-to-Sunday date range

#### Scenario: Joplin CLI is absent in Data API mode

- **WHEN** `JOPLIN_WRITE_ADAPTER` is `data_api` and the `joplin` command is absent from PATH
- **THEN** the workflow commands SHALL still run their Data API happy path when all Data API prerequisites are valid


<!-- @trace
source: align-data-api-base-mode
updated: 2026-05-24
code:
  - docs/usage.md
  - docs/workflows.md
  - bin/weekly
  - config/joplin-workflow.conf.example
  - bin/til
  - docs/customization.md
  - test/run-data-api-tests.sh
  - install.sh
  - bin/learn
  - test/data-api-fixtures.sh
  - lib/joplin_data_api.sh
  - test/run-command-tests.sh
  - docs/installation.md
  - docs/spec-ai-auto-generation.md
  - docs/spec-v0.1.0.md
  - README.md
-->

---
### Requirement: Data API endpoint and token validation

The system SHALL initialize the Data API connection before any note write. It MUST support an explicit `JOPLIN_API_BASE_URL`, port probing from `JOPLIN_API_PORT_START` to `JOPLIN_API_PORT_END` when no base URL is configured, `JOPLIN_API_TOKEN`, and `JOPLIN_API_TIMEOUT`.

#### Scenario: Explicit base URL is healthy

- **WHEN** `JOPLIN_API_BASE_URL` is configured and its `/ping` endpoint responds successfully within `JOPLIN_API_TIMEOUT`
- **THEN** the system SHALL use that base URL for subsequent Data API requests

#### Scenario: Port probing finds the Data API

- **WHEN** `JOPLIN_API_BASE_URL` is empty and `/ping` succeeds on a port within the configured probe range
- **THEN** the system SHALL use the discovered localhost base URL for subsequent Data API requests

#### Scenario: Data API is unavailable

- **WHEN** no explicit base URL passes health check and no probed port responds successfully
- **THEN** the system SHALL refuse to write and show an actionable message that tells the user to open Joplin Desktop and enable the Web Clipper service

#### Scenario: Token is missing or invalid

- **WHEN** `JOPLIN_API_TOKEN` is missing or a Data API request returns an authorization failure
- **THEN** the system SHALL refuse to write and show an actionable message that tells the user to configure the Joplin Data API token in local configuration or environment

#### Scenario: Request times out

- **WHEN** a Data API request exceeds `JOPLIN_API_TIMEOUT`
- **THEN** the system SHALL stop the command without creating or updating notes and show a timeout message


<!-- @trace
source: align-data-api-base-mode
updated: 2026-05-24
code:
  - docs/usage.md
  - docs/workflows.md
  - bin/weekly
  - config/joplin-workflow.conf.example
  - bin/til
  - docs/customization.md
  - test/run-data-api-tests.sh
  - install.sh
  - bin/learn
  - test/data-api-fixtures.sh
  - lib/joplin_data_api.sh
  - test/run-command-tests.sh
  - docs/installation.md
  - docs/spec-ai-auto-generation.md
  - docs/spec-v0.1.0.md
  - README.md
-->

---
### Requirement: Notebook settings resolve to folder IDs

The system SHALL resolve every configured target notebook to a Data API folder ID before creating or updating notes. The system MUST prefer command-specific notebook ID settings over title lookup. Title lookup MUST evaluate all folder pages and MUST provide hierarchy-aware diagnostics when the title is missing or duplicated.

#### Scenario: Notebook ID is configured

- **WHEN** `NOTEBOOK_POST_ID` is configured and Data API confirms that folder exists
- **THEN** `learn` SHALL write the note with that ID as `parent_id`

#### Scenario: Notebook title resolves uniquely

- **WHEN** the command-specific notebook ID is empty and exactly one folder title matches the configured notebook title across all folder pages
- **THEN** the system SHALL use the matching folder ID as `parent_id`

#### Scenario: Notebook title is missing

- **WHEN** the command-specific notebook ID is empty and no folder title matches the configured notebook title across all folder pages
- **THEN** the system SHALL refuse to write and show an actionable message that tells the user to create the notebook in Joplin Desktop or configure the folder ID

#### Scenario: Notebook title is duplicated

- **WHEN** the command-specific notebook ID is empty and more than one folder title matches the configured notebook title across all folder pages or parent notebooks
- **THEN** the system SHALL refuse to write, list candidate folder IDs and paths, and tell the user to configure the command-specific notebook ID

#### Scenario: Notebook ID does not exist

- **WHEN** the command-specific notebook ID is configured and Data API cannot find a folder with that ID
- **THEN** the system SHALL refuse to write and tell the user to correct the configured notebook ID

#### Scenario: Duplicate notebook titles exist in different hierarchy branches

- **WHEN** the command-specific notebook ID is empty and two folders have the same configured title under different parent folders
- **THEN** the system SHALL treat the title as ambiguous, refuse to write, and show the candidate folder paths and IDs


<!-- @trace
source: harden-data-api-base-mode-gaps
updated: 2026-05-24
code:
  - README.md
  - docs/installation.md
  - docs/usage.md
  - docs/customization.md
  - test/run-data-api-tests.sh
  - .agents/skills/spectra-discuss/SKILL.md
  - lib/joplin_data_api.sh
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - bin/weekly
  - .cursorrules
  - test/data-api-fixtures.sh
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .spectra.yaml
  - install.sh
  - bin/joplin-workflow-doctor
  - .agents/skills/spectra-ingest/SKILL.md
  - docs/workflows.md
  - bin/til
  - test/run-command-tests.sh
  - .agents/skills/spectra-commit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - AGENTS.md
  - config/joplin-workflow.conf.example
  - docs/troubleshooting.md
  - bin/learn
  - .agents/skills/spectra-drift/SKILL.md
-->

---
### Requirement: Daily note lookup is scoped to the daily folder

The `til` command SHALL search for today's daily note only within the resolved daily folder. It MUST evaluate all relevant note search pages before deciding whether the daily note is missing, unique, or duplicated. It MUST NOT update a same-titled note from another folder.

#### Scenario: Existing daily note is in target folder

- **WHEN** exactly one note with today's generated title exists in the resolved daily folder across all note search pages
- **THEN** `til` SHALL update that note body through Data API

#### Scenario: Same title exists outside target folder

- **WHEN** a note with today's generated title exists outside the resolved daily folder and no matching note exists inside the resolved daily folder
- **THEN** `til` SHALL create a new daily note inside the resolved daily folder

#### Scenario: Multiple matching notes exist in target folder

- **WHEN** more than one note with today's generated title exists in the resolved daily folder across one or more note search pages
- **THEN** `til` SHALL refuse to update and show an actionable message that asks the user to resolve duplicate daily notes


<!-- @trace
source: harden-data-api-base-mode-gaps
updated: 2026-05-24
code:
  - README.md
  - docs/installation.md
  - docs/usage.md
  - docs/customization.md
  - test/run-data-api-tests.sh
  - .agents/skills/spectra-discuss/SKILL.md
  - lib/joplin_data_api.sh
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - bin/weekly
  - .cursorrules
  - test/data-api-fixtures.sh
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .spectra.yaml
  - install.sh
  - bin/joplin-workflow-doctor
  - .agents/skills/spectra-ingest/SKILL.md
  - docs/workflows.md
  - bin/til
  - test/run-command-tests.sh
  - .agents/skills/spectra-commit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - AGENTS.md
  - config/joplin-workflow.conf.example
  - docs/troubleshooting.md
  - bin/learn
  - .agents/skills/spectra-drift/SKILL.md
-->

---
### Requirement: Data API errors are surfaced consistently

The system SHALL map Data API failures into clear command outcomes. Debug mode SHALL include technical details useful for troubleshooting, while normal mode SHALL provide concise next steps. Debug diagnostics MUST NOT expose Data API tokens.

#### Scenario: HTTP error occurs

- **WHEN** a Data API request returns a non-success HTTP status
- **THEN** the command SHALL stop, avoid reporting success, and show a concise failure message

#### Scenario: JSON parsing fails

- **WHEN** a Data API response cannot be parsed by `jq`
- **THEN** the command SHALL stop, avoid reporting success, and show a message that identifies the Data API response as invalid

#### Scenario: Debug mode is enabled

- **WHEN** `DEBUG` is `true` and a Data API request fails
- **THEN** the command SHALL include status code and a bounded response snippet in diagnostic output

#### Scenario: Debug diagnostics sanitize token values

- **WHEN** `DEBUG` is `true` and a Data API URL or response context contains the configured token
- **THEN** the diagnostic output SHALL redact the token value before printing technical details

#### Scenario: Invalid response shape occurs

- **WHEN** a paginated Data API response is valid JSON but does not contain the expected `items` structure
- **THEN** the command SHALL stop, avoid reporting success, and show a message that identifies the Data API response shape as invalid

#### Scenario: Port probing fails in debug mode

- **WHEN** `DEBUG` is `true` and no probed port responds to `/ping`
- **THEN** the diagnostic output SHALL include the probed port range and failed candidate base URLs without printing token values


<!-- @trace
source: harden-data-api-base-mode-gaps
updated: 2026-05-24
code:
  - README.md
  - docs/installation.md
  - docs/usage.md
  - docs/customization.md
  - test/run-data-api-tests.sh
  - .agents/skills/spectra-discuss/SKILL.md
  - lib/joplin_data_api.sh
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - bin/weekly
  - .cursorrules
  - test/data-api-fixtures.sh
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .spectra.yaml
  - install.sh
  - bin/joplin-workflow-doctor
  - .agents/skills/spectra-ingest/SKILL.md
  - docs/workflows.md
  - bin/til
  - test/run-command-tests.sh
  - .agents/skills/spectra-commit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - AGENTS.md
  - config/joplin-workflow.conf.example
  - docs/troubleshooting.md
  - bin/learn
  - .agents/skills/spectra-drift/SKILL.md
-->

---
### Requirement: Sync messaging reflects Joplin Desktop ownership

The system SHALL treat Data API writes as local Joplin Desktop writes. In Data API base mode, `AUTO_SYNC=true` MUST NOT invoke Joplin CLI sync.

#### Scenario: Write succeeds with AUTO_SYNC true

- **WHEN** a Data API note create or update succeeds and `AUTO_SYNC` is `true`
- **THEN** the command SHALL tell the user that the note was written locally and that cloud sync follows Joplin Desktop sync settings

#### Scenario: Write succeeds with AUTO_SYNC false

- **WHEN** a Data API note create or update succeeds and `AUTO_SYNC` is `false`
- **THEN** the command SHALL report the local write result without claiming cloud sync completed


<!-- @trace
source: align-data-api-base-mode
updated: 2026-05-24
code:
  - docs/usage.md
  - docs/workflows.md
  - bin/weekly
  - config/joplin-workflow.conf.example
  - bin/til
  - docs/customization.md
  - test/run-data-api-tests.sh
  - install.sh
  - bin/learn
  - test/data-api-fixtures.sh
  - lib/joplin_data_api.sh
  - test/run-command-tests.sh
  - docs/installation.md
  - docs/spec-ai-auto-generation.md
  - docs/spec-v0.1.0.md
  - README.md
-->

---
### Requirement: Documentation matches implemented base mode

User-facing documentation and configuration examples SHALL describe Joplin Desktop Data API as the base mode. Documentation MUST NOT describe Joplin CLI as a required dependency for the default workflow. Documentation SHALL include base mode doctor, initialization notebook setup choice, dry-run/preflight, troubleshooting, and hierarchy-aware notebook resolution guidance.

#### Scenario: Installation documentation lists base prerequisites

- **WHEN** a user reads installation guidance for the default workflow
- **THEN** the documentation SHALL list Joplin Desktop, enabled Web Clipper service, Data API token, clipboard support, HTTP client, and `jq` as base prerequisites

#### Scenario: Configuration example separates Data API and AI settings

- **WHEN** a user reads the example configuration
- **THEN** Data API settings SHALL appear in the base workflow section and AI provider settings SHALL NOT appear as active runtime settings for the three core commands

#### Scenario: AI roadmap is not presented as implemented behavior

- **WHEN** a user reads AI-related documentation
- **THEN** the documentation SHALL state that AI generation mode and AI agent mode are future or optional capabilities, separate from the implemented base capture commands

#### Scenario: Troubleshooting starts with doctor

- **WHEN** a user reads troubleshooting guidance for Data API base mode failures
- **THEN** the documentation SHALL direct the user to run the doctor command before manual diagnosis steps

#### Scenario: Dry-run documentation is non-mutating

- **WHEN** a user reads usage or troubleshooting guidance for dry-run mode
- **THEN** the documentation SHALL state that dry-run validates prerequisites and target resolution without creating or updating notes, tags, or folders

#### Scenario: Duplicate notebook documentation recommends IDs

- **WHEN** a user reads customization or troubleshooting guidance for duplicate notebook titles
- **THEN** the documentation SHALL tell the user to configure the matching `NOTEBOOK_*_ID` value instead of relying on title fallback

#### Scenario: Initialization documentation presents both notebook setup choices

- **WHEN** a user reads installation or setup guidance for Data API base mode
- **THEN** the documentation SHALL explain both using existing notebooks and creating default empty notebooks, including that automatic folder creation only occurs after explicit initialization choice


<!-- @trace
source: harden-data-api-base-mode-gaps
updated: 2026-05-24
code:
  - README.md
  - docs/installation.md
  - docs/usage.md
  - docs/customization.md
  - test/run-data-api-tests.sh
  - .agents/skills/spectra-discuss/SKILL.md
  - lib/joplin_data_api.sh
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - bin/weekly
  - .cursorrules
  - test/data-api-fixtures.sh
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .spectra.yaml
  - install.sh
  - bin/joplin-workflow-doctor
  - .agents/skills/spectra-ingest/SKILL.md
  - docs/workflows.md
  - bin/til
  - test/run-command-tests.sh
  - .agents/skills/spectra-commit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - AGENTS.md
  - config/joplin-workflow.conf.example
  - docs/troubleshooting.md
  - bin/learn
  - .agents/skills/spectra-drift/SKILL.md
-->

---
### Requirement: Base mode doctor validates Data API readiness

The system SHALL provide a base mode doctor command that validates Joplin Desktop Data API prerequisites without creating or updating Joplin data. The doctor MUST validate `curl`, `jq`, clipboard command availability, token presence, Data API base URL or port probing, `/ping`, a token-authenticated API request, and target notebook resolution for `learn`, `til`, and `weekly`.

#### Scenario: Doctor passes with healthy base mode

- **WHEN** the user runs the doctor command with `curl`, `jq`, a readable clipboard command, a configured token, a reachable Data API endpoint, and resolvable daily, post, and weekly notebooks
- **THEN** the doctor SHALL report all required checks as passing and exit successfully without creating or updating notes, tags, or folders

#### Scenario: Doctor fails when a required tool is missing

- **WHEN** the user runs the doctor command and `jq` is not available
- **THEN** the doctor SHALL fail before Data API writes and show an actionable message that tells the user to install `jq`

#### Scenario: Doctor fails when token is missing

- **WHEN** the user runs the doctor command and no Data API token is configured
- **THEN** the doctor SHALL fail before authenticated Data API requests and show an actionable message that tells the user to configure the Joplin Data API token in local configuration or environment

#### Scenario: Doctor fails when target notebook is ambiguous

- **WHEN** the user runs the doctor command and a target notebook title matches multiple folders
- **THEN** the doctor SHALL fail, list candidate folder IDs and paths, and tell the user to configure the command-specific notebook ID


<!-- @trace
source: harden-data-api-base-mode-gaps
updated: 2026-05-24
code:
  - README.md
  - docs/installation.md
  - docs/usage.md
  - docs/customization.md
  - test/run-data-api-tests.sh
  - .agents/skills/spectra-discuss/SKILL.md
  - lib/joplin_data_api.sh
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - bin/weekly
  - .cursorrules
  - test/data-api-fixtures.sh
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .spectra.yaml
  - install.sh
  - bin/joplin-workflow-doctor
  - .agents/skills/spectra-ingest/SKILL.md
  - docs/workflows.md
  - bin/til
  - test/run-command-tests.sh
  - .agents/skills/spectra-commit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - AGENTS.md
  - config/joplin-workflow.conf.example
  - docs/troubleshooting.md
  - bin/learn
  - .agents/skills/spectra-drift/SKILL.md
-->

---
### Requirement: Base commands support non-mutating preflight

The `learn`, `til`, and `weekly` commands SHALL support a non-mutating preflight mode for Data API base mode. Preflight mode MUST validate command inputs, clipboard readability, Data API readiness, and target resolution, but MUST NOT create, update, or delete notes, tags, or folders.

#### Scenario: Learn preflight resolves target without writing

- **WHEN** the user runs `learn --dry-run "Understanding React Hooks"` with non-empty clipboard content and a resolvable post notebook
- **THEN** the command SHALL report the intended note title and target notebook ID without creating a note or binding tags

#### Scenario: Weekly preflight resolves target without writing

- **WHEN** the user runs `weekly --dry-run "W07 Learning Summary"` with non-empty clipboard content and a resolvable weekly notebook
- **THEN** the command SHALL report the computed week range and target notebook ID without creating a note or binding tags

#### Scenario: TIL preflight reports append action

- **WHEN** the user runs `til --dry-run "Promise.all behavior"` and exactly one note with today's generated title exists in the resolved daily folder
- **THEN** the command SHALL report that a real run would append to that note without updating the note body or binding tags

#### Scenario: TIL preflight reports create action

- **WHEN** the user runs `til --dry-run "Promise.all behavior"` and no note with today's generated title exists in the resolved daily folder
- **THEN** the command SHALL report that a real run would create a daily note without creating a note or binding tags


<!-- @trace
source: harden-data-api-base-mode-gaps
updated: 2026-05-24
code:
  - README.md
  - docs/installation.md
  - docs/usage.md
  - docs/customization.md
  - test/run-data-api-tests.sh
  - .agents/skills/spectra-discuss/SKILL.md
  - lib/joplin_data_api.sh
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - bin/weekly
  - .cursorrules
  - test/data-api-fixtures.sh
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .spectra.yaml
  - install.sh
  - bin/joplin-workflow-doctor
  - .agents/skills/spectra-ingest/SKILL.md
  - docs/workflows.md
  - bin/til
  - test/run-command-tests.sh
  - .agents/skills/spectra-commit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - AGENTS.md
  - config/joplin-workflow.conf.example
  - docs/troubleshooting.md
  - bin/learn
  - .agents/skills/spectra-drift/SKILL.md
-->

---
### Requirement: Initialization configures target notebooks explicitly

The initialization flow SHALL ask the user to choose between using existing target notebooks and creating new empty target notebooks from configured defaults. The system MUST persist resolved or created folder IDs in local configuration and MUST NOT silently choose or create notebooks outside the selected initialization path.

#### Scenario: User chooses existing notebooks during initialization

- **WHEN** the user selects the existing notebook setup path and daily, post, and weekly target notebooks resolve uniquely through configured IDs or titles
- **THEN** the initialization flow SHALL write the resolved folder IDs to `NOTEBOOK_DAILY_ID`, `NOTEBOOK_POST_ID`, and `NOTEBOOK_WEEKLY_ID` in local configuration without creating folders

#### Scenario: User chooses default empty notebook creation during initialization

- **WHEN** the user selects the create-default setup path and no existing folders conflict with the configured daily, post, and weekly notebook titles
- **THEN** the initialization flow SHALL create empty folders for those configured titles through Data API and write the created folder IDs to local configuration

#### Scenario: Default notebook title already exists during creation setup

- **WHEN** the user selects the create-default setup path and a configured notebook title already exists in Joplin Desktop
- **THEN** the initialization flow SHALL stop before creating a duplicate folder for that title and tell the user to use the existing notebook path or change the configured title

#### Scenario: Initialization creation partially fails

- **WHEN** the create-default setup path creates at least one target folder and then another target folder creation fails
- **THEN** the initialization flow SHALL report the created folder IDs and the failed target, avoid reporting full initialization success, and keep unrelated local configuration values unchanged

#### Scenario: Doctor does not create missing notebooks

- **WHEN** the user runs the doctor command and a configured target notebook is missing
- **THEN** the doctor SHALL fail with setup guidance and SHALL NOT create folders


<!-- @trace
source: harden-data-api-base-mode-gaps
updated: 2026-05-24
code:
  - README.md
  - docs/installation.md
  - docs/usage.md
  - docs/customization.md
  - test/run-data-api-tests.sh
  - .agents/skills/spectra-discuss/SKILL.md
  - lib/joplin_data_api.sh
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - bin/weekly
  - .cursorrules
  - test/data-api-fixtures.sh
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .spectra.yaml
  - install.sh
  - bin/joplin-workflow-doctor
  - .agents/skills/spectra-ingest/SKILL.md
  - docs/workflows.md
  - bin/til
  - test/run-command-tests.sh
  - .agents/skills/spectra-commit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - AGENTS.md
  - config/joplin-workflow.conf.example
  - docs/troubleshooting.md
  - bin/learn
  - .agents/skills/spectra-drift/SKILL.md
-->

---
### Requirement: Data API collection handles pagination

The Data API adapter SHALL collect all pages needed for folder lists, note searches, and tag searches before deciding whether a target is missing, unique, or duplicated. The adapter MUST NOT make resolution decisions from the first page alone when the response indicates additional pages exist.

#### Scenario: Folder title appears on a later page

- **WHEN** the configured notebook title is absent from the first folder page and appears exactly once on a later folder page
- **THEN** the system SHALL resolve that folder title to the matching folder ID

#### Scenario: Duplicate folder title spans pages

- **WHEN** the configured notebook title appears once on the first folder page and once on a later folder page
- **THEN** the system SHALL refuse to write and tell the user to configure the command-specific notebook ID

#### Scenario: Daily note duplicate spans pages

- **WHEN** one matching daily note appears on the first note search page and another matching daily note appears on a later search page in the resolved daily folder
- **THEN** `til` SHALL refuse to update and show an actionable message that asks the user to resolve duplicate daily notes

#### Scenario: Existing tag appears on a later page

- **WHEN** a configured tag title appears on a later tag search page
- **THEN** the system SHALL use the existing tag instead of creating a duplicate tag

<!-- @trace
source: harden-data-api-base-mode-gaps
updated: 2026-05-24
code:
  - README.md
  - docs/installation.md
  - docs/usage.md
  - docs/customization.md
  - test/run-data-api-tests.sh
  - .agents/skills/spectra-discuss/SKILL.md
  - lib/joplin_data_api.sh
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - bin/weekly
  - .cursorrules
  - test/data-api-fixtures.sh
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .spectra.yaml
  - install.sh
  - bin/joplin-workflow-doctor
  - .agents/skills/spectra-ingest/SKILL.md
  - docs/workflows.md
  - bin/til
  - test/run-command-tests.sh
  - .agents/skills/spectra-commit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - AGENTS.md
  - config/joplin-workflow.conf.example
  - docs/troubleshooting.md
  - bin/learn
  - .agents/skills/spectra-drift/SKILL.md
-->