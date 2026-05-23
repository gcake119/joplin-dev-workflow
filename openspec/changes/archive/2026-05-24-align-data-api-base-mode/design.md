## Context

目前 `docs/spec-v0.1.0.md` 與實際 `bin/learn`、`bin/til`、`bin/weekly` 一致：三個指令都以 Joplin CLI 為主要寫入介面，使用 `joplin use` 切換筆記本、`joplin mknote` 建立筆記、`joplin set` 更新 body、`joplin cat` 讀取既有筆記，並以 `joplin sync` 表示自動同步。`install.sh` 也把 Joplin CLI 視為必要依賴。

`openspec/config.yaml` 描述的目標狀態不同：Joplin Desktop 是基本前提，Joplin Data API 是 base write path，Joplin CLI 只能作為 legacy/fallback adapter。這次變更要把 runtime、設定範例、安裝流程與使用者文件一起對齊，避免使用者照文件安裝後走到舊的 CLI-only 行為。

目前腳本實際讀取的設定包含 notebook title、tag template、日期格式、`AUTO_SYNC`、`DEBUG` 與 `DAILY_NOTE_TITLE_TEMPLATE`。`config/joplin-workflow.conf.example` 另有 `SYNC_TIMEOUT`、`CLIPBOARD_CMD`、`EDITOR`，但核心腳本尚未完整使用。Data API 相關設定目前不存在，需新增並讓腳本實際讀取。

## Goals / Non-Goals

**Goals:**

- 讓 `learn`、`til`、`weekly` 在沒有 Joplin CLI 的情況下，以 Joplin Desktop Data API 建立或更新筆記。
- 用單一 Bash helper/adapter 集中處理 Data API 連線、token、HTTP、JSON、folder ID、note 與 tag 操作。
- 讓 notebook 設定支援 ID-first、title fallback 的 resolution，實際寫入 note 時使用 Data API `parent_id`。
- 讓 `AUTO_SYNC` 不再隱含執行 Joplin CLI sync，而是清楚提示 Data API 寫入後由 Joplin Desktop 負責同步狀態。
- 更新安裝、設定與使用文件，使 base mode 以 Joplin Desktop/Web Clipper/Data API token 為前置條件。
- 保持既有 CLI 命令介面、剪貼簿輸入與筆記模板，降低使用者遷移成本。

**Non-Goals:**

- 不實作 AI provider、AI generation command、AI agent orchestration、語意標題生成或模型輸出確認流程。
- 不引入 web app 或 cloud service 作為主要使用入口。
- 不把 Joplin API token 或 AI API key 寫入 repository。
- 不承諾 Joplin CLI fallback 是預設路徑；若保留 fallback，必須由設定明確開啟。

## Decisions

### Centralize Data API access in a Bash adapter

新增 `lib/joplin_data_api.sh` 作為唯一 Data API adapter。三個指令只負責命令參數、剪貼簿、日期計算與筆記 body 組裝，所有 HTTP request、response parsing、error mapping、folder resolution、note create/update、tag binding 都透過 helper function 完成。

Rationale: 目前三個腳本重複處理 Joplin CLI 操作。若直接在每支腳本散落 `curl` 和 `jq`，port 探測、token 錯誤、notebook 重名與 JSON 錯誤會分叉。集中 adapter 可用固定 fixtures 做 shell-level 測試。

Alternative considered: 在三個腳本中各自呼叫 Data API。此方式初期較快，但會讓錯誤訊息與 resolution 規則難以保持一致。

### Prefer configured notebook IDs before title lookup

每個 notebook 設定支援對應 ID 變數：`NOTEBOOK_DAILY_ID`、`NOTEBOOK_POST_ID`、`NOTEBOOK_WEEKLY_ID`。若 ID 存在，adapter 先透過 Data API 驗證 folder 存在並使用該 ID。若 ID 空白，才用 `NOTEBOOK_DAILY`、`NOTEBOOK_POST`、`NOTEBOOK_WEEKLY` title 查找 folder。

Title lookup 必須處理三種結果：找不到時提示使用者在 Joplin Desktop 建立 notebook 或設定 ID；找到一筆時使用該 folder ID；找到多筆相同 title 時拒絕寫入並要求設定明確 ID。多層 notebook hierarchy 不依賴目前 selected notebook，title 只作為查找輸入。

Alternative considered: 沿用 notebook title 並假設唯一。此方式無法符合 Data API 寫入需要 `parent_id` 的 contract，也無法處理重名 notebook。

### Detect Data API endpoint before writing

設定讀取順序為：若 `JOPLIN_API_BASE_URL` 有值，直接對該 base URL 執行 `/ping`；若未設定，從 `JOPLIN_API_PORT_START` 到 `JOPLIN_API_PORT_END` 逐一檢查 localhost port，預設從 `41184` 開始。所有 API request 都加上 `JOPLIN_API_TOKEN`，並使用 `JOPLIN_API_TIMEOUT` 控制連線與回應等待。

Health check 失敗時，使用者訊息要提示開啟 Joplin Desktop、啟用 Web Clipper service、確認 token 與 base URL。token 缺失或無效要和 service 不可用分開提示。

Alternative considered: 要求使用者永遠設定完整 base URL。此方式簡化實作，但不符合 config.yaml 對 port 探測的要求。

### Preserve command output shape while changing write path

`learn` 和 `weekly` 仍建立新 note，`til` 仍搜尋當日 note、存在則追加、不存在則建立。成功輸出仍包含 title/concept、notebook 顯示名稱與 note ID，但 view/edit 提示改成 Joplin Desktop/Data API 語意，例如提示使用者回到 Joplin Desktop 查看，而不是只給 `joplin cat` 或 `joplin edit`。

`weekly` 保留 macOS `date -v` 與 Linux `date -d` 的 week range 計算。剪貼簿仍優先支援 macOS `pbpaste`，Linux/WSL 可透過既有 clipboard 設定延伸；本變更不把剪貼簿抽成跨平台完整 adapter。

Alternative considered: 同時重寫剪貼簿與日期相容層。此範圍會把 Data API 遷移和平台抽象混在一起，不利於驗收。

### Redefine sync as Desktop-managed status

`AUTO_SYNC=true` 在 Data API base mode 中不執行 `joplin sync`。成功寫入後，CLI 顯示「已寫入本機 Joplin，雲端同步依 Joplin Desktop 同步設定處理」這類使用者可理解訊息。若未來需要 CLI fallback sync，需透過 `JOPLIN_WRITE_ADAPTER=cli` 或獨立 legacy setting 明確啟用。

Alternative considered: 寫入 Data API 後仍呼叫 `joplin sync`。此方式會重新引入 Joplin CLI 作為 base mode 依賴，和 config.yaml 衝突。

### Keep AI as documented boundary only

這次只更新文件，使 AI generation mode 與 AI agent mode 被描述為後續能力與邊界：核心三指令不需要 AI provider；agent 寫入前必須 draft-first 或要求確認；AI 設定不得混入 notebook base settings。runtime 不新增 provider/model/prompt/cache/log 設定讀取。

Alternative considered: 同時新增 AI 設定區與空 adapter。此方式會產生未被 runtime 使用的設定，容易把 roadmap 寫成已實作功能。

## Implementation Contract

Behavior:

- `bin/learn "Title"` 從剪貼簿讀取內容，解析 `NOTEBOOK_POST_ID` 或 `NOTEBOOK_POST` 為 folder ID，透過 Data API 建立 title 為 `Title` 的 note，body 保留現有 learning article template。
- `bin/til ["Concept"]` 從剪貼簿讀取內容，未提供 concept 時使用剪貼簿第一行，解析 daily folder ID，在該 folder 內找當日 title；找到一筆則讀取 body 後追加 TIL block，找不到則建立新 daily note。
- `bin/weekly "Week Title"` 依平台計算週一到週日日期範圍，解析 weekly folder ID，透過 Data API 建立週回顧 note，body 保留現有 weekly template。
- 三個指令在 Data API base mode 下不檢查 `joplin` command，也不執行 `joplin sync`。

Interface / data shape:

- `~/.config/joplin-workflow/config` 與 `config/joplin-workflow.conf.example` 新增 Data API 區塊：`JOPLIN_WRITE_ADAPTER=data_api`、`JOPLIN_API_BASE_URL`、`JOPLIN_API_TOKEN`、`JOPLIN_API_PORT_START=41184`、`JOPLIN_API_PORT_END=41194`、`JOPLIN_API_TIMEOUT=5`、`NOTEBOOK_DAILY_ID`、`NOTEBOOK_POST_ID`、`NOTEBOOK_WEEKLY_ID`。
- `lib/joplin_data_api.sh` 暴露 shell functions：`joplin_api_init`、`joplin_api_request`、`joplin_resolve_folder_id`、`joplin_create_note`、`joplin_get_note_body`、`joplin_update_note_body`、`joplin_find_note_by_title_in_folder`、`joplin_apply_tags`。
- Data API note create payload 至少包含 `title`、`body`、`parent_id`。Update payload 更新 `body`。Tag binding 可在 helper 中解析 hashtag 字串為 tag title，建立缺少的 tag 後綁定 note。

Failure modes:

- Data API service 不可用：拒絕寫入，提示開啟 Joplin Desktop 並啟用 Web Clipper service。
- Token 缺失或無效：拒絕寫入，提示在本機 config 或環境變數設定 Joplin Data API token。
- Notebook ID 不存在：拒絕寫入，提示檢查對應 `NOTEBOOK_*_ID`。
- Notebook title 找不到：拒絕寫入，提示在 Joplin Desktop 建立 notebook 或設定 ID。
- Notebook title 重名：拒絕寫入，列出可辨識資訊並要求設定 ID。
- HTTP 錯誤、timeout 或 JSON 解析失敗：拒絕寫入，顯示可操作摘要；debug mode 可輸出 status code 與 response snippet。
- 剪貼簿空白與缺少必要命令參數維持現有錯誤行為。

Acceptance criteria:

- Shell tests 或 fixture-driven smoke tests 覆蓋 Data API health check、token 缺失、folder ID lookup、title lookup not found、title lookup duplicate、note create、daily note append、weekly date range、Data API unavailable 與 invalid JSON。
- 在沒有 `joplin` command 的 test PATH 下，`learn`、`til`、`weekly` 的 Data API happy path 測試仍通過。
- README、安裝文件、使用文件、customization、workflows、spec-v0.1.0 與 AI roadmap 文件不再把 Joplin CLI 描述為 base mode 必要依賴。
- `spectra validate align-data-api-base-mode` 通過，且本變更 artifacts 不含未填 placeholder。

Scope boundaries:

- In scope: 三個核心 Bash 指令、Data API helper、設定範例、安裝腳本、文件與 base-mode 測試。
- Out of scope: AI runtime、agent orchestration、web/cloud product change、完整跨平台 clipboard adapter、Joplin Desktop UI 自動化。

## Risks / Trade-offs

- [Risk] Bash HTTP/JSON handling 容易變成不可讀的字串拼接 → Mitigation: 所有 request/response parsing 集中在 `lib/joplin_data_api.sh`，payload 透過 `jq -n` 組裝。
- [Risk] Joplin Data API search/filter 能力與 CLI list 行為不同，可能造成 `til` 當日筆記查找結果不一致 → Mitigation: 查詢後在 shell 端以 title 與 `parent_id` 精準過濾，重名時拒絕自動更新。
- [Risk] Tag binding 需要額外 API calls，增加失敗面 → Mitigation: note 建立/更新成功是主要結果；tag 綁定失敗需明確提示，不能靜默假裝完成。
- [Risk] 移除 CLI sync 會讓使用者誤以為雲端同步已完成 → Mitigation: 成功訊息與文件明確說明 Desktop sync 負責雲端同步狀態。
- [Risk] 使用者已有 CLI-only workflow → Mitigation: 設計保留明確 opt-in legacy adapter 空間，但文件不再把它當 base mode。
