## 1. Adapter Foundation

- [x] 1.1 實作 Data API collection handles pagination 並對應設計 Page through Data API list and search responses centrally：`lib/joplin_data_api.sh` 提供共用 pagination helper，folder list、note search、tag search 都能跨頁收集完整 `items` 後再判斷 missing/unique/duplicate；以 `test/run-data-api-tests.sh` 驗證 later-page folder、cross-page duplicate folder、cross-page daily note duplicate 與 later-page tag lookup。
- [x] 1.2 實作 Notebook settings resolve to folder IDs 並對應設計 Resolve notebook titles with hierarchy-aware diagnostics：ID-first 成功時直接使用設定 ID，title fallback 以完整 folder map 判斷唯一性，重名或多層 hierarchy ambiguity 會列出 candidate path/id 並拒絕寫入；以 `test/run-data-api-tests.sh` 驗證 invalid ID、unique title、missing title、same-title different parent folders 與 duplicate candidate diagnostics。
- [x] 1.3 實作 Data API errors are surfaced consistently 並對應設計 Standardize diagnostics without leaking secrets：normal mode 對 missing dependency、missing token、unavailable API、HTTP error、timeout、invalid JSON、invalid response shape 顯示可操作下一步，debug mode 顯示 bounded status/path/snippet/port/candidate 資訊且 redacts token；以 `test/run-data-api-tests.sh` 驗證錯誤分類與 debug output 不包含 `JOPLIN_API_TOKEN` 值。

## 2. Doctor and Preflight Commands

- [x] 2.1 實作 Base mode doctor validates Data API readiness 並對應設計 Add a dedicated base mode doctor and shared preflight contract：新增 `bin/joplin-workflow-doctor`，以同一份 config 檢查 `curl`、`jq`、clipboard command、token、base URL/port probing、`/ping`、authenticated request 與 daily/post/weekly notebook resolution，成功時不寫入資料，失敗時 exit non-zero；以 command fixture 測試驗證 doctor happy path、missing `jq`、missing token、Data API unavailable 與 ambiguous notebook。
- [x] 2.2 實作 Initialization configures target notebooks explicitly 並對應設計 Add an explicit initialization notebook setup choice：初始化流程提供「使用現有 notebooks」與「依預設建立新的空 notebooks」兩條路徑，前者只解析並寫入 `NOTEBOOK_*_ID`，後者只在使用者明確選擇後建立 daily/post/weekly 空 folders 並寫入 IDs；以 `test/run-command-tests.sh` 驗證 existing path 無 POST、create-default path 只建立 folders、同名 folder conflict 不建立 duplicate、partial failure 回報 created IDs 且保留 unrelated config。
- [x] 2.3 實作 Base commands support non-mutating preflight 並對應設計 Keep dry-run strictly non-mutating：`learn --dry-run`、`weekly --dry-run`、`til --dry-run` 驗證 clipboard、Data API 與 target resolution，顯示 intended note action/notebook id，且不呼叫 note/tag/folder create/update/delete API；以 `test/run-command-tests.sh` 的 fake curl log 驗證 dry-run happy path 沒有 POST、PUT、DELETE。
- [x] 2.4 補強 Daily note lookup is scoped to the daily folder 的 dry-run 與 pagination 行為：`til --dry-run` 在唯一既有 daily note 時報告 append，在無命中時報告 create，在同 folder 多筆命中時失敗且不更新資料；以 `test/run-command-tests.sh` 驗證 append/create/duplicate 三條 dry-run 路徑與 zero write calls。

## 3. Documentation and Configuration

- [x] 3.1 實作 Documentation matches implemented base mode 的 troubleshooting 入口並對應設計 Align troubleshooting and configuration docs with base mode：新增 `docs/troubleshooting.md`，以 doctor 為第一步，覆蓋 token、Web Clipper service、port probing、`curl`、`jq`、clipboard、notebook ID/title、duplicate hierarchy、初始化 notebook setup choice、dry-run 與 debug diagnostics；以內容檢查驗證每個 base mode failure category 都有對應處理步驟且沒有 Joplin CLI fallback 作為 base prerequisite。
- [x] 3.2 對齊 README、`docs/installation.md`、`docs/usage.md`、`docs/customization.md`、`docs/workflows.md` 與 `config/joplin-workflow.conf.example`：文件描述 doctor、初始化時使用現有 notebooks 或建立預設空 notebooks、`--dry-run`、ID-first notebook 設定、title fallback ambiguity、Data API token/port/curl/jq/clipboard prerequisites 與 Desktop-managed sync，不新增 AI provider 或 AI agent runtime 設定；以內容 review 或 grep 檢查驗證相關段落存在且 Joplin CLI 不再被列為 default workflow 必要依賴。
- [x] 3.3 更新 `install.sh` 的 base mode guidance：安裝流程提示使用者設定 Data API token 後執行 `joplin-workflow-doctor`，並在初始化時讓使用者選擇使用現有 notebooks 或依預設建立空 notebooks，且缺少 `joplin` command 不會阻止 base mode guidance；以 mocked PATH 或 install dry-run 測試驗證 notebook setup choice 與 doctor guidance 出現且 CLI fallback 不被當成必要條件。

## 4. Verification

- [x] 4.1 執行完整 artifact 與實作前驗證：`spectra analyze harden-data-api-base-mode-gaps --json` 無 Critical/Warning，`spectra validate harden-data-api-base-mode-gaps` 通過，並記錄本 change 不包含 AI provider、AI generation、AI agent 或 Joplin CLI fallback 實作任務；以 CLI output 作為 apply 前交接證據。
- [x] 4.2 實作完成後執行最小 repo-defined checks：跑 `test/run-data-api-tests.sh`、`test/run-command-tests.sh` 與 `spectra validate harden-data-api-base-mode-gaps`，確認 doctor、初始化 notebook setup choice、pagination、dry-run、diagnostics、docs 對齊與 non-mutating contract 都通過；以測試輸出與 Spectra validation 通過作為完成條件。
