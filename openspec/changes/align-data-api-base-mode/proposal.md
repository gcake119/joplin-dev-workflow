## Why

`openspec/config.yaml` 已將 Joplin Desktop Data API 定義為 base write path，但目前實作仍要求 Joplin CLI，三個核心指令都透過 `joplin use`、`joplin mknote`、`joplin set`、`joplin sync` 操作筆記。這會讓目前行為、安裝文件、設定範例與專案定位不一致，也使 notebook title 到 folder ID、Data API token、health check 與 sync 語意缺少可驗收實作。

## What Changes

- 將 `bin/learn`、`bin/til`、`bin/weekly` 的 base write path 改為 Joplin Desktop Data API，不再要求 Joplin CLI 作為基本依賴。
- 新增共用 Bash adapter/helper，集中處理 Data API base URL/port 探測、`/ping` health check、token、timeout、HTTP 錯誤、JSON 解析、folder ID resolution、note create/update 與 tag 綁定。
- 更新設定範例，加入 `JOPLIN_WRITE_ADAPTER=data_api`、`JOPLIN_API_BASE_URL`、`JOPLIN_API_TOKEN`、port range、timeout、notebook ID 與 title fallback 相關設定。
- 重新定義 `AUTO_SYNC`：Data API 寫入本機 Joplin 後，雲端同步主要由 Joplin Desktop 管理；若保留 CLI sync，只能作為明確選用的 legacy/fallback 行為。
- 保留剪貼簿作為低摩擦輸入來源，維持 `learn`、`til`、`weekly` 的使用者命令介面與現有筆記模板輸出。
- 更新 README、安裝文件、使用文件、自訂文件、工作流文件與 `docs/spec-v0.1.0.md`，讓文件描述 Joplin Desktop/Data API base mode，而不是 CLI-only。
- 校正 AI 相關文件：目前三個核心指令不直接串接 AI API；AI generation mode 與 AI agent mode 只作為後續能力邊界，不在本變更中實作 provider 或 agent orchestration。

## Non-Goals

- 不在本變更中實作 AI provider、LLM 標題生成、agent 多步驟 orchestration 或自動確認流程。
- 不改成 web app-first、cloud-first，也不改變 Joplin Desktop 作為主要筆記環境的產品邊界。
- 不提交真實 Joplin Data API token、AI API key 或使用者本機設定。
- 不移除所有 Joplin CLI 相關程式碼；若保留，只能被標示為 legacy/fallback adapter，且不再是 base mode。

## Capabilities

### New Capabilities

- `desktop-data-api-base-mode`: 三個核心 CLI 指令以 Joplin Desktop Data API 作為基本寫入路徑，並定義 Data API 設定、health check、notebook resolution、note create/update、sync 提示與錯誤處理。

### Modified Capabilities

(none)

## Impact

- Affected specs: desktop-data-api-base-mode
- Affected code:
  - Modified: bin/learn, bin/til, bin/weekly, install.sh, config/joplin-workflow.conf.example, README.md, docs/installation.md, docs/usage.md, docs/customization.md, docs/workflows.md, docs/spec-v0.1.0.md, docs/spec-ai-auto-generation.md
  - New: lib/joplin_data_api.sh, test/data-api-fixtures.sh, test/learn-data-api.bats, test/til-data-api.bats, test/weekly-data-api.bats
  - Removed: none
