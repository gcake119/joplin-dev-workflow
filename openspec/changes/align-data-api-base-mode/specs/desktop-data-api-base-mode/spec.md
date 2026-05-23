## ADDED Requirements

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

### Requirement: Notebook settings resolve to folder IDs

The system SHALL resolve every configured target notebook to a Data API folder ID before creating or updating notes. The system MUST prefer command-specific notebook ID settings over title lookup.

#### Scenario: Notebook ID is configured

- **WHEN** `NOTEBOOK_POST_ID` is configured and Data API confirms that folder exists
- **THEN** `learn` SHALL write the note with that ID as `parent_id`

#### Scenario: Notebook title resolves uniquely

- **WHEN** the command-specific notebook ID is empty and exactly one folder title matches the configured notebook title
- **THEN** the system SHALL use the matching folder ID as `parent_id`

#### Scenario: Notebook title is missing

- **WHEN** the command-specific notebook ID is empty and no folder title matches the configured notebook title
- **THEN** the system SHALL refuse to write and show an actionable message that tells the user to create the notebook in Joplin Desktop or configure the folder ID

#### Scenario: Notebook title is duplicated

- **WHEN** the command-specific notebook ID is empty and more than one folder title matches the configured notebook title
- **THEN** the system SHALL refuse to write and tell the user to configure the command-specific notebook ID

#### Scenario: Notebook ID does not exist

- **WHEN** the command-specific notebook ID is configured and Data API cannot find a folder with that ID
- **THEN** the system SHALL refuse to write and tell the user to correct the configured notebook ID

### Requirement: Daily note lookup is scoped to the daily folder

The `til` command SHALL search for today's daily note only within the resolved daily folder. It MUST NOT update a same-titled note from another folder.

#### Scenario: Existing daily note is in target folder

- **WHEN** exactly one note with today's generated title exists in the resolved daily folder
- **THEN** `til` SHALL update that note body through Data API

#### Scenario: Same title exists outside target folder

- **WHEN** a note with today's generated title exists outside the resolved daily folder and no matching note exists inside the resolved daily folder
- **THEN** `til` SHALL create a new daily note inside the resolved daily folder

#### Scenario: Multiple matching notes exist in target folder

- **WHEN** more than one note with today's generated title exists in the resolved daily folder
- **THEN** `til` SHALL refuse to update and show an actionable message that asks the user to resolve duplicate daily notes

### Requirement: Data API errors are surfaced consistently

The system SHALL map Data API failures into clear command outcomes. Debug mode SHALL include technical details useful for troubleshooting, while normal mode SHALL provide concise next steps.

#### Scenario: HTTP error occurs

- **WHEN** a Data API request returns a non-success HTTP status
- **THEN** the command SHALL stop, avoid reporting success, and show a concise failure message

#### Scenario: JSON parsing fails

- **WHEN** a Data API response cannot be parsed by `jq`
- **THEN** the command SHALL stop, avoid reporting success, and show a message that identifies the Data API response as invalid

#### Scenario: Debug mode is enabled

- **WHEN** `DEBUG` is `true` and a Data API request fails
- **THEN** the command SHALL include status code and a bounded response snippet in diagnostic output

### Requirement: Sync messaging reflects Joplin Desktop ownership

The system SHALL treat Data API writes as local Joplin Desktop writes. In Data API base mode, `AUTO_SYNC=true` MUST NOT invoke Joplin CLI sync.

#### Scenario: Write succeeds with AUTO_SYNC true

- **WHEN** a Data API note create or update succeeds and `AUTO_SYNC` is `true`
- **THEN** the command SHALL tell the user that the note was written locally and that cloud sync follows Joplin Desktop sync settings

#### Scenario: Write succeeds with AUTO_SYNC false

- **WHEN** a Data API note create or update succeeds and `AUTO_SYNC` is `false`
- **THEN** the command SHALL report the local write result without claiming cloud sync completed

### Requirement: Documentation matches implemented base mode

User-facing documentation and configuration examples SHALL describe Joplin Desktop Data API as the base mode. Documentation MUST NOT describe Joplin CLI as a required dependency for the default workflow.

#### Scenario: Installation documentation lists base prerequisites

- **WHEN** a user reads installation guidance for the default workflow
- **THEN** the documentation SHALL list Joplin Desktop, enabled Web Clipper service, Data API token, clipboard support, HTTP client, and `jq` as base prerequisites

#### Scenario: Configuration example separates Data API and AI settings

- **WHEN** a user reads the example configuration
- **THEN** Data API settings SHALL appear in the base workflow section and AI provider settings SHALL NOT appear as active runtime settings for the three core commands

#### Scenario: AI roadmap is not presented as implemented behavior

- **WHEN** a user reads AI-related documentation
- **THEN** the documentation SHALL state that AI generation mode and AI agent mode are future or optional capabilities, separate from the implemented base capture commands
