## Summary

補強已封存 `desktop-data-api-base-mode` 後留下的 base mode 穩定性與診斷落差，讓 Joplin Desktop Data API 寫入路徑在實際使用前能被安全檢查，並讓 notebook/folder resolution 在大量、多層、重名資料下有明確可驗收行為。

## Motivation

目前 base mode 已改為 Joplin Desktop Data API，但 helper 與文件仍缺少獨立 doctor/smoke check、跨頁 folder/note 查找、hierarchy 診斷、non-mutating preflight 契約，以及集中化 troubleshooting 指引。這會讓使用者在 token、port、clipboard、`jq`、curl 或 notebook 設定出錯時，只能等到真正寫入命令失敗才知道問題，且錯誤訊息不一定足以安全定位目標 notebook。

## Proposed Solution

- 新增 base mode doctor/smoke check 能力，用 non-mutating 路徑檢查 `curl`、`jq`、clipboard command、Data API token、explicit base URL 或 port probing、`/ping`、token-authenticated API request，以及 `learn`、`til`、`weekly` 的 target notebook resolution。
- 補強 Data API adapter 的 list/search pagination，讓 folder resolution、note lookup 與 tag lookup 不只讀第一頁 `limit=100`。
- 強化 folder/notebook resolution 邊界：ID-first 仍優先；title fallback 必須在多層 hierarchy 中列出足以辨識的 path/id 診斷；重名 title 必須拒絕寫入並要求設定對應 `NOTEBOOK_*_ID`；找不到 title 時不得自動建立 notebook。
- 補強初始化 notebook setup：初始化時讓使用者明確選擇使用現有筆記本並解析/寫入對應 ID，或依預設名稱建立新的空 daily/post/weekly 筆記本；非初始化寫入路徑仍不得自動建立 notebook。
- 定義 dry-run 或 non-mutating preflight 為 base mode 能力：可驗證寫入前置條件、解析目標 notebook、檢查 clipboard 是否可讀，但不得 create/update note、tag 或 folder。
- 統一 normal/debug 錯誤訊息：normal mode 給清楚下一步；debug mode 顯示 bounded status、URL/path、port probing 結果、response snippet 與 resolution candidates，不輸出 token。
- 新增並對齊 `docs/troubleshooting.md`，同步更新 README、`docs/usage.md`、`docs/customization.md`、`docs/installation.md` 與 `config/joplin-workflow.conf.example`，讓 base mode 診斷流程貼近 `openspec/config.yaml`。
- 擴充測試 fixtures 與 shell tests，覆蓋 doctor/smoke check、pagination、duplicate hierarchy、ID-first、title fallback、non-mutating preflight、錯誤訊息與 debug 診斷。

## Non-Goals

- 不引入 AI provider、AI generation command、AI agent orchestration、LLM 標題生成、prompt/cache/log runtime 設定或 auto-confirm flow。
- 不實作 Joplin CLI fallback，也不讓 doctor/smoke check 依賴 `joplin` command。
- 不在一般寫入、doctor 或 dry-run/preflight 中自動建立 missing notebook/folder；只有初始化流程在使用者明確選擇建立預設空筆記本時才可建立 folder。
- 不改變三個核心命令的主要使用介面：`learn`、`til`、`weekly` 仍以 clipboard + Data API base write path 為主。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `desktop-data-api-base-mode`: 補強 base mode 的 doctor/smoke check、初始化 notebook setup choice、non-mutating preflight、pagination-safe folder/note resolution、hierarchy/duplicate 診斷、錯誤訊息一致性與文件對齊。

## Impact

- Affected specs: desktop-data-api-base-mode
- Affected code:
  - Modified: lib/joplin_data_api.sh, bin/learn, bin/til, bin/weekly, install.sh, config/joplin-workflow.conf.example, README.md, docs/installation.md, docs/usage.md, docs/customization.md, docs/workflows.md, test/run-data-api-tests.sh, test/run-command-tests.sh, test/data-api-fixtures.sh
  - New: bin/joplin-workflow-doctor, docs/troubleshooting.md
  - Removed: none
