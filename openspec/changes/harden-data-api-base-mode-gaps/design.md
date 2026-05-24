## Context

`align-data-api-base-mode` 已將三個核心命令遷移到 Joplin Desktop Data API，並新增 `lib/joplin_data_api.sh`、Data API 設定範例與 fixture tests。現況仍有幾個 base mode gap：folder resolution 與 note search 只讀單頁 `limit=100`；duplicate notebook 訊息只列 id/title，沒有 hierarchy path；使用者沒有獨立 doctor/smoke command 可在寫入前檢查 token、port、`/ping`、`curl`、`jq`、clipboard 與 target notebook；dry-run/preflight 尚未成為明確能力；`docs/troubleshooting.md` 在 config context 中被列為使用者文件但目前不存在。

這次不是重新遷移 CLI 到 Data API，而是硬化已封存規格的落差。Data API 仍是 base write path，Joplin CLI 仍不是 default dependency。`bin/learn`、`bin/til`、`bin/weekly` 的既有 clipboard、template、date 行為應維持；macOS `date -v` 與 Linux `date -d` 的週範圍差異不在本次重寫範圍，但 doctor 可診斷 clipboard command。初始化流程需要補上 notebook setup choice：使用者可選擇使用現有 notebook 並解析 ID，或依預設名稱建立新的空 notebook。AI generation mode 與 AI agent mode 只維持文件邊界，不新增 provider、model、prompt、cache、log 或 agent confirmation runtime。

## Goals / Non-Goals

**Goals:**

- 提供獨立 base mode doctor/smoke check，讓使用者在寫入前確認工具依賴、Data API reachability、token-authenticated request、clipboard command 與三個 target notebook resolution。
- 將 Data API pagination 抽成共用 helper，讓 folders、notes search 與 tags search 能跨頁取得完整候選集合。
- 讓 notebook/folder resolution 在 ID-first、title fallback、重名、多層 hierarchy、missing title 與 invalid ID 情境下有一致且可診斷的結果。
- 讓初始化流程在 Data API base mode 下提供 notebook setup choice：使用現有 daily/post/weekly notebooks，或建立預設空 notebooks 並將解析出的 IDs 寫入本機設定。
- 定義 non-mutating preflight/dry-run：可讀取設定、clipboard、Data API、folder/note candidates，但不得 create/update notes、tags 或 folders。
- 統一 normal/debug diagnostics，debug 可協助定位 base URL、port probing、request path、HTTP status、bounded response snippet 與 resolution candidates，但不得洩漏 token。
- 對齊 README、installation、usage、customization、workflows、troubleshooting 與 config example，讓使用者文件反映 openspec/config.yaml 的 base mode 前提。

**Non-Goals:**

- 不新增 AI provider、AI generation command、AI agent orchestration、語意標題生成或自動確認流程。
- 不實作或啟用 Joplin CLI fallback；doctor 也不檢查 `joplin` command 作為 base prerequisite。
- 不在一般寫入、doctor 或 dry-run/preflight 中自動建立缺少的 notebook/folder；title fallback 找不到時只提示建立或設定 ID。初始化流程在使用者明確選擇建立預設空 notebooks 時例外。
- 不改寫三個核心命令的筆記模板、主要參數、tag 語意或 Desktop-managed sync 語意。
- 不在文件中宣稱 dry-run 會驗證真實 note create/update payload 被 Joplin 接受；dry-run 只驗證不會變更資料的前置條件。

## Decisions

### Add a dedicated base mode doctor and shared preflight contract

新增 `bin/joplin-workflow-doctor` 作為使用者與安裝後診斷入口。doctor 載入同一份 `~/.config/joplin-workflow/config`，檢查 `JOPLIN_WRITE_ADAPTER=data_api`、`curl`、`jq`、clipboard command 可執行性、Data API token 是否存在、explicit base URL 或 port probing、`/ping`、token-authenticated minimal request，以及 daily/post/weekly notebook resolution。輸出使用 pass/fail/warn 的段落，最後用 exit code 表示是否可安全執行 base commands。

`lib/joplin_data_api.sh` 提供共用 `joplin_preflight_base_mode` 類型的 helper，doctor 與三個命令都走相同檢查。三個命令可支援 `--dry-run`：執行配置、clipboard 與 target notebook preflight，顯示將寫入的 notebook title/id 與 note title，但不呼叫 create/update/tag APIs。

Alternative considered: 只把檢查放進 `install.sh`。安裝檢查無法涵蓋使用者之後改 token、改 port、改 notebook 或 Joplin Desktop 關閉的狀態，因此需要可重複執行的 doctor。

### Page through Data API list and search responses centrally

新增共用 pagination helper，例如 `joplin_api_collect_pages` 或等價函式，接收 path、fields、limit 與 result selector，依 Joplin Data API 回應中的 `has_more` 或後續 page number 持續讀取。folder list、note search、tag search 不再各自硬寫第一頁 `limit=100`。

Pagination helper 必須保留 timeout、HTTP error、invalid JSON 與 debug diagnostics 的既有處理，並在 debug mode 顯示每次請求的 method/path/page/status，而不是完整 URL token。若 Data API 回應缺少 expected `items` array，應回報 invalid response shape。

Alternative considered: 將 limit 調大。Joplin Data API 仍可能分頁，而且大量筆記/標籤會超過單頁；調大 limit 不能形成可驗收 contract。

### Resolve notebook titles with hierarchy-aware diagnostics

ID-first 規則維持不變：`NOTEBOOK_DAILY_ID`、`NOTEBOOK_POST_ID`、`NOTEBOOK_WEEKLY_ID` 有值時先以 `/folders/:id` 驗證，成功就使用該 folder ID。若 ID 不存在，拒絕寫入並指出是哪個設定值錯誤。

Title fallback 改用完整 folder list 建立 id、title、parent_id 的 map。唯一 title match 時使用該 id；多筆同名 title 時拒絕寫入，normal mode 顯示每筆 candidate 的 title path 與 id，要求設定對應 `NOTEBOOK_*_ID`；debug mode 額外顯示 parent_id 與 candidate count。多層 hierarchy 不改變 title fallback 的唯一性規則：即使 path 不同，只要 title 重名就不得猜測目標。

Alternative considered: 支援 `Parent/Child` path 設定。這會引入新的設定語法與 escaping 問題；本次先保留 title fallback 並要求重名時使用 ID，較貼近現有 config example。

### Add an explicit initialization notebook setup choice

初始化流程應在 Data API readiness 通過後詢問使用者要使用現有 notebooks 還是建立預設空 notebooks。選擇使用現有 notebooks 時，流程要求使用者提供或確認 daily/post/weekly 的 title 或 ID，執行與一般 resolution 相同的 ID-first/title fallback 規則，成功後把 `NOTEBOOK_DAILY_ID`、`NOTEBOOK_POST_ID`、`NOTEBOOK_WEEKLY_ID` 寫入本機設定。選擇建立預設空 notebooks 時，流程以 `NOTEBOOK_DAILY`、`NOTEBOOK_POST`、`NOTEBOOK_WEEKLY` 的 configured/default titles 建立空 folder；建立前仍必須檢查是否已有同名 folder，避免重複建立，成功後同樣寫入 IDs。

這個建立能力只屬於初始化 setup，不能被 doctor、dry-run 或一般 `learn`、`til`、`weekly` 寫入路徑隱式觸發。若初始化建立到一半失敗，流程需回報已建立的 folder title/id 與失敗項目，並提示重新執行 doctor 或手動修正 config；不得假裝整體初始化成功。

Alternative considered: 缺少 notebook 時在第一次 `learn`、`til` 或 `weekly` 自動建立。此方式會讓一般寫入命令產生隱式結構變更，也會和 dry-run/non-mutating contract 衝突。

### Keep dry-run strictly non-mutating

Dry-run/preflight 不得呼叫 Data API 的 POST、PUT、DELETE，也不得建立 tag 或 folder。`learn --dry-run` 與 `weekly --dry-run` 可顯示會建立的 note title、target notebook title/id、tag 字串與 Desktop sync reminder 狀態。`til --dry-run` 可額外查詢今日 note 是否已存在於 target folder，並顯示將 append 或 create，但不得讀取或更新 note body 以外的變更操作；若查詢結果 duplicate，dry-run 應同樣失敗。

Alternative considered: 使用 temporary note 建立後刪除作為 smoke test。這會修改使用者 Joplin 資料，刪除失敗時會留下雜訊，和 base mode preflight 目標衝突。

### Standardize diagnostics without leaking secrets

Normal mode 錯誤訊息用固定分類：missing dependency、missing token、Data API unavailable、token rejected、timeout、invalid JSON、invalid response shape、folder ID not found、folder title not found、duplicate folder title、duplicate daily note、clipboard unavailable/empty。每個分類要有一個下一步，例如啟用 Web Clipper、設定 `JOPLIN_API_TOKEN`、安裝 `jq`、設定 `NOTEBOOK_*_ID`。

Debug mode 可輸出 bounded diagnostics：request method/path、HTTP status、response first 300 bytes、resolved base URL、probed ports、candidate count、candidate ids/paths。Debug output 必須遮蔽 token query parameter 與 token-like values。

Alternative considered: 直接印 curl 完整命令。這會洩漏 token，且一般使用者不需要完整 URL。

### Align troubleshooting and configuration docs with base mode

新增 `docs/troubleshooting.md`，以 doctor 為第一診斷步驟，覆蓋 token、Web Clipper service、port probing、`jq`、curl、clipboard、notebook ID/title、duplicate hierarchy、dry-run 和 debug mode。README、installation、usage、customization、workflows 應連到 troubleshooting，並且把 `bin/joplin-workflow-doctor`、`--dry-run`、ID-first notebook 設定和 Data API base prerequisites 說清楚。`config/joplin-workflow.conf.example` 應加入 doctor/dry-run 相關註解，但不新增 AI runtime 設定，也不放真實 token。

Alternative considered: 只在 README 加 FAQ。base mode 失敗情境較多，散落 FAQ 不利於安裝與使用文件互相引用。

## Implementation Contract

Behavior:

- Running `joplin-workflow-doctor` checks base mode prerequisites without creating or updating Joplin data. It reports `curl`, `jq`, clipboard command, token presence, Data API reachability, `/ping`, authenticated request, and daily/post/weekly notebook resolution. It exits non-zero when a required base prerequisite fails.
- The initialization flow lets the user choose one of two notebook setup paths: use existing daily/post/weekly notebooks and persist their IDs, or create empty notebooks using the configured/default notebook titles and persist the created IDs. It never makes that choice silently.
- Running `learn --dry-run "Title"`, `weekly --dry-run "Title"`, or `til --dry-run ["Concept"]` performs non-mutating preflight and target resolution. The commands show the intended target notebook title/id and note action, then exit without note create/update/tag API calls.
- Folder resolution fetches all folder pages before matching titles. ID settings still win over title settings. Duplicate title matches across any hierarchy fail with candidate paths and ids. Missing title and invalid ID fail before note writes.
- Daily note lookup and tag lookup use paginated search results before deciding not-found, duplicate, or unique match.
- Normal errors are concise and action-oriented. Debug errors include bounded technical context and never print Data API tokens.

Interface / data shape:

- New executable: `bin/joplin-workflow-doctor`.
- Initialization entrypoint may live in `install.sh`, a setup flag on the doctor command, or a small dedicated setup command, but the user-facing behavior must expose the same two choices and update only the local config plus selected/created folders.
- Existing executables add optional `--dry-run` before the existing positional title/concept argument.
- Shared helper changes stay in `lib/joplin_data_api.sh`; command scripts call helper functions instead of direct curl.
- No new required external dependencies beyond existing base mode `curl` and `jq`.
- Config example keeps Data API settings in the base workflow section and may document `DEBUG=true`, `CLIPBOARD_CMD`, `NOTEBOOK_*_ID`, `JOPLIN_API_BASE_URL`, port range and timeout as doctor-relevant settings.

Failure modes:

- Missing `curl` or `jq`: doctor and commands fail before Data API calls and tell the user which command to install.
- Missing token: fail before probing authenticated endpoints and point to local config or environment.
- `/ping` unavailable after explicit base URL or port range probing: fail with Joplin Desktop/Web Clipper guidance.
- Authenticated request returns authorization failure: fail with token correction guidance.
- Paginated request returns invalid JSON or missing expected fields: fail with invalid response guidance; debug includes status/snippet.
- Duplicate folder title: fail and list candidates; implementation must not choose the first match.
- Initialization create-default path finds an existing configured/default folder title before creation: it must ask the user to use the existing folder or choose a different setup path rather than creating a duplicate.
- Initialization create-default path partially fails: report created folder IDs and failed targets, and leave enough local config state for rerun/manual correction without losing token or unrelated settings.
- Dry-run detects duplicate daily note: fail the same way a real `til` write would fail.

Acceptance criteria:

- `test/run-data-api-tests.sh` covers explicit base URL, port probing, missing token, unavailable API, invalid JSON, multi-page folder resolution, duplicate hierarchy diagnostics, invalid ID, title fallback, note search pagination and tag search pagination.
- `test/run-command-tests.sh` or equivalent command tests cover `joplin-workflow-doctor` success/failure paths, initialization notebook setup choice for existing-vs-create-default notebooks, config ID persistence, and `--dry-run` on `learn`, `til`, and `weekly` with fixtures proving no POST/PUT tag/note write calls occurred outside initialization.
- Documentation review confirms README, installation, usage, customization, workflows, troubleshooting and config example describe Data API doctor/dry-run behavior and do not describe Joplin CLI fallback as base mode.
- `spectra validate harden-data-api-base-mode-gaps` passes before apply begins and after implementation artifacts are updated.

Scope boundaries:

- In scope: Data API helper hardening, doctor executable, initialization notebook setup choice, dry-run/preflight behavior for the three commands, tests, config example and user docs.
- Out of scope: AI runtime, Joplin CLI fallback, automatic folder creation, full cross-platform clipboard abstraction, web/cloud rewrite, changing note templates.

## Risks / Trade-offs

- [Risk] More helper logic in Bash can become hard to read. Mitigation: keep pagination, diagnostics, resolution and preflight as named helper functions with fixture tests for each behavior.
- [Risk] Doctor may be mistaken for proof that a future write must succeed. Mitigation: document that doctor validates current prerequisites and target resolution, while writes can still fail if Joplin state changes later.
- [Risk] Initialization could create duplicate notebooks if defaults already exist. Mitigation: create-default setup must check all folder pages first and require user confirmation or a different path when same-title folders already exist.
- [Risk] Listing hierarchy paths for duplicate notebooks may require building parent chains from incomplete data. Mitigation: fetch all folders before path construction and fall back to title plus id when parent information is missing.
- [Risk] Dry-run for `til` may need to query existing note candidates, which can be slower on large notebooks. Mitigation: use paginated search by title first, then filter by parent_id, instead of scanning all notes.
- [Risk] Debug diagnostics could leak token through URLs. Mitigation: centralize debug formatting and sanitize token query parameters before printing.

## Migration Plan

1. Add helper-level pagination, hierarchy path and sanitized diagnostics behind existing function names where possible.
2. Add doctor executable, initialization notebook setup choice and command dry-run support using shared preflight helpers.
3. Expand fixture tests before changing docs so behavior is pinned.
4. Update docs and config example after command behavior is test-covered.
5. Rollback by removing doctor/dry-run/setup entrypoints and reverting helper pagination to single-page behavior; user-created empty notebooks can remain in Joplin Desktop because they contain no generated notes.

## Open Questions

- Should `install.sh` run doctor automatically after copying config when `JOPLIN_API_TOKEN` is already present, or should it only tell the user to run doctor manually? Default implementation should avoid automatic network checks during install unless a clear non-interactive flag exists.
