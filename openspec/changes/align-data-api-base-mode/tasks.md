## 1. Data API Adapter Foundation

- [x] 1.1 實作 Centralize Data API access in a Bash adapter 與 Detect Data API endpoint before writing：新增 `lib/joplin_data_api.sh`，提供 `joplin_api_init`、`joplin_api_request` 與統一錯誤回傳，讓 Data API endpoint and token validation 可在任何寫入前完成；以 fixture-driven shell 測試驗證 explicit base URL、port probing、timeout、service unavailable、token missing/invalid 與 invalid JSON。
- [x] 1.2 實作 Prefer configured notebook IDs before title lookup：在 adapter 中提供 `joplin_resolve_folder_id`，先驗證 `NOTEBOOK_*_ID`，再用 notebook title 查找，並對 missing、duplicate、invalid ID 回傳可操作錯誤；以 shell 測試驗證 Notebook settings resolve to folder IDs 的五種情境。
- [x] 1.3 實作 note 與 tag helper contract：在 adapter 中提供 `joplin_create_note`、`joplin_get_note_body`、`joplin_update_note_body`、`joplin_find_note_by_title_in_folder`、`joplin_apply_tags`，payload 透過 `jq -n` 組裝且 create payload 包含 `title`、`body`、`parent_id`；以 fixture 測試驗證 create、read、update、tag binding 成功與 tag binding 失敗提示。
- [x] 1.4 完成 Data API errors are surfaced consistently：統一 HTTP non-success、timeout、JSON parse failure 與 debug mode response snippet 的使用者訊息，normal mode 不輸出過長技術內容；以錯誤 fixture 測試驗證命令停止且不報告成功。

## 2. Core Command Migration

- [x] 2.1 遷移 `bin/learn` 以滿足 Data API is the base write adapter：`learn "Title"` 在 Data API mode 中不檢查 `joplin` command，解析 post folder ID 後建立 learning article note，並保留既有剪貼簿空白與缺少 title 錯誤；以沒有 `joplin` 的 test PATH 執行 learn happy path 與錯誤路徑測試。
- [x] 2.2 遷移 `bin/til` 並滿足 Daily note lookup is scoped to the daily folder：`til` 在 resolved daily folder 內搜尋今日 note，唯一命中則 append，無命中則建立，同名 note 在其他 folder 不會被更新，多筆命中則拒絕；以 fixture 測試驗證 append、create、outside-folder ignore 與 duplicate refusal。
- [x] 2.3 遷移 `bin/weekly` 並落實 Preserve command output shape while changing write path：`weekly "Week Title"` 保留 macOS `date -v` 與 Linux `date -d` 週範圍計算，透過 Data API 建立 weekly review note，成功輸出包含 title、week range、notebook display name 與 note ID；以 shell 測試驗證 macOS/Linux date 分支和 Data API create payload。
- [x] 2.4 完成 Redefine sync as Desktop-managed status：三個指令在 Data API mode 且 `AUTO_SYNC=true` 時不呼叫 `joplin sync`，成功訊息說明已寫入本機 Joplin 且雲端同步依 Joplin Desktop 設定處理；以 stubbed `joplin` command 測試驗證 sync 未被呼叫，並覆蓋 Sync messaging reflects Joplin Desktop ownership。

## 3. Configuration and Installation

- [x] 3.1 更新 `config/joplin-workflow.conf.example` 的 base workflow 設定，新增 `JOPLIN_WRITE_ADAPTER=data_api`、`JOPLIN_API_BASE_URL`、`JOPLIN_API_TOKEN`、port range、timeout、`NOTEBOOK_DAILY_ID`、`NOTEBOOK_POST_ID`、`NOTEBOOK_WEEKLY_ID`，且不放入真實 secret；以內容檢查驗證 Data API 設定存在、AI provider 設定未被宣告為三個核心指令的 active runtime 設定。
- [x] 3.2 更新 `install.sh` 的預設安裝檢查，讓 Joplin Desktop/Web Clipper/Data API token、clipboard command、HTTP client 與 `jq` 成為 base prerequisites，Joplin CLI 只作為 legacy/fallback 提示；以 dry-run 或 mocked command PATH 驗證缺少 Joplin CLI 不會阻止 base install guidance。

## 4. Documentation Alignment

- [x] 4.1 更新 README、`docs/installation.md` 與 `docs/usage.md`，讓 Documentation matches implemented base mode：預設流程描述 Joplin Desktop Data API、Web Clipper service、token 設定、folder ID resolution 與 Desktop-managed sync，不再宣稱 Joplin CLI 是 default workflow 必要依賴；以內容 review 驗證 base prerequisites 與三個核心命令範例一致。
- [x] 4.2 更新 `docs/customization.md` 與 `docs/workflows.md`，說明 notebook ID 優先、title fallback、重名 notebook 處理、`AUTO_SYNC` 新語意與 Desktop sync 邊界；以內容 review 驗證每個 notebook 設定都有 ID-first 與 duplicate title 指引。
- [x] 4.3 更新 `docs/spec-v0.1.0.md` 與 `docs/spec-ai-auto-generation.md`，把舊的 CLI-only 現況修正為 Data API base mode，並完成 Keep AI as documented boundary only：AI generation mode 與 AI agent mode 被標示為 future/optional，不被描述為三個核心指令已實作行為；以內容 review 驗證 AI roadmap is not presented as implemented behavior。

## 5. Verification

- [x] 5.1 執行完整變更驗證：跑過新增 shell/fixture 測試、針對 `learn`、`til`、`weekly` 執行沒有 `joplin` command 的 Data API happy path 測試、檢查文件內容，最後執行 `spectra validate align-data-api-base-mode`；以測試輸出與 Spectra validation 通過作為完成條件。
