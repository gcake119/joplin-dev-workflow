# Joplin Dev Workflow v0.1.0 系統規格書

## 文件資訊

| 項目 | 內容 |
|------|------|
| 專案名稱 | Joplin Dev Workflow |
| 版本 | 0.1.0 |
| 發布日期 | 2026-02-16 |
| 文件撰寫日期 | 2026-02-18 |
| 狀態 | Released |
| 目標使用者 | 使用 Joplin CLI 的開發者、技術學習者 |
| 授權 | MIT License |

---

## 1. 專案概述

### 1.1 專案目標
為開發者提供**純 CLI 的學習筆記工作流工具**，支援從終端機快速捕捉學習內容到 Joplin，無需打開 GUI 應用程式，實現無縫的學習記錄體驗。

### 1.2 核心價值主張
- **剪貼簿優先**：節省 AI API 配額，從 Copilot Chat/Perplexity 複製內容後直接建立筆記
- **零中斷工作流**：完全在終端機操作，不需切換到桌面應用
- **結構化筆記**：自動添加元數據、標籤、模板
- **多設備同步**：透過 Joplin 原生同步功能（如 Joplin Cloud）

### 1.3 設計哲學
> "Clipboard as Content Bridge"

使用剪貼簿作為內容橋樑，讓使用者：
- 可以在 AI 工具中審閱、編輯回應後再儲存
- 支援任何內容來源（AI、瀏覽器、檔案、終端機輸出）
- 保持工作流簡單通用
- 避免重複呼叫 AI API（節省配額）

### 1.4 使用場景
- **前端 Bootcamp 學員**：學習 JavaScript、TDD 等技術
- **開發者**：記錄程式碼片段、除錯過程、技術洞察
- **技術作家**：整理技術文章草稿
- **自學者**：建立個人知識庫

---

## 2. 系統架構

### 2.1 技術棧

| 層級 | 技術 | 版本 | 用途 |
|------|------|------|------|
| **Shell** | Bash | 4.0+ | 腳本執行環境 |
| **筆記系統** | Joplin CLI | Latest | 筆記 CRUD 操作 |
| **JSON 處理** | jq | 1.6+ | 解析 Joplin API 回應 |
| **剪貼簿** | pbcopy/pbpaste (macOS)<br>xclip (Linux) | - | 讀取/寫入剪貼簿 |
| **系統** | macOS / Linux / WSL | - | 執行平台 |

### 2.2 系統架構圖

```
┌────────────────────────────────────────────────────┐
│  使用者工作環境                                      │
│  ┌──────────────┐  ┌──────────────┐               │
│  │ VS Code      │  │ Perplexity   │               │
│  │ Copilot Chat │  │ AI Chat      │               │
│  └──────┬───────┘  └──────┬───────┘               │
│         │ Copy AI          │ Copy                  │
│         │ Response         │ Answer                │
│         └──────────┬───────┘                       │
│                    ↓                                │
│         ┌──────────────────────┐                   │
│         │   系統剪貼簿          │                   │
│         │   (pbcopy/xclip)     │                   │
│         └──────────┬───────────┘                   │
└────────────────────┼────────────────────────────────┘
                     │ pbpaste
                     ↓
┌────────────────────────────────────────────────────┐
│  Joplin Dev Workflow CLI Tools                     │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │  learn  │  │   til   │  │ weekly  │           │
│  └────┬────┘  └────┬────┘  └────┬────┘           │
│       │            │             │                 │
│       └────────────┼─────────────┘                 │
│                    ↓                                │
│       ┌────────────────────────┐                   │
│       │  Configuration Loader   │                   │
│       │  (~/.config/...)        │                   │
│       └────────────┬───────────┘                   │
│                    ↓                                │
│       ┌────────────────────────┐                   │
│       │  Template Engine        │                   │
│       │  (Date, Tags, Metadata) │                   │
│       └────────────┬───────────┘                   │
└────────────────────┼────────────────────────────────┘
                     │ joplin CLI
                     ↓
┌────────────────────────────────────────────────────┐
│  Joplin System                                      │
│  ┌──────────────────────────────────────────┐     │
│  │  Notebooks                                │     │
│  │  ├─ Daily Notes (TIL)                    │     │
│  │  ├─ Blog Posts (Articles)                │     │
│  │  └─ Weekly Reviews                       │     │
│  └──────────────────────────────────────────┘     │
│                    ↓                                │
│  ┌──────────────────────────────────────────┐     │
│  │  Joplin Sync (Optional)                  │     │
│  │  - Joplin Cloud                          │     │
│  │  - Dropbox / OneDrive                    │     │
│  │  - WebDAV / NextCloud                    │     │
│  └──────────────────────────────────────────┘     │
└────────────────────────────────────────────────────┘
                     ↓
            ┌─────────────────┐
            │  其他設備        │
            │  (已同步)        │
            └─────────────────┘
```

### 2.3 檔案結構

```
joplin-dev-workflow/
├── bin/                        # 可執行腳本
│   ├── learn                   # 建立技術文章草稿
│   ├── til                     # 追加 TIL 條目
│   └── weekly                  # 建立週報模板
├── config/                     # 配置檔案
│   └── joplin-workflow.conf.example
├── docs/                       # 文件
│   ├── installation.md         # 安裝指南
│   ├── usage.md                # 使用指南
│   ├── workflows.md            # 工作流程範例
│   ├── customization.md        # 自訂指南
│   └── spec-v0.1.0.md         # 本規格書
├── examples/                   # 範例
│   └── templates/              # 模板範例
├── tests/                      # 測試（待開發）
├── install.sh                  # 安裝腳本
├── README.md                   # 專案說明
├── CHANGELOG.md                # 版本記錄
└── LICENSE                     # MIT 授權

安裝後的系統檔案：
~/.local/bin/
├── learn -> [project]/bin/learn
├── til -> [project]/bin/til
└── weekly -> [project]/bin/weekly

~/.config/joplin-workflow/
└── config                      # 使用者配置檔
```

---

## 3. 功能規格

### 3.1 核心指令

#### 3.1.1 `learn` - 建立技術文章草稿

**功能描述**：
從剪貼簿讀取內容，在 "Blog Posts" 筆記本中建立新的技術文章草稿。

**指令語法**：
```bash
learn "Article Title"
```

**參數**：
- `Article Title`（必要）：文章標題

**輸入來源**：
- 系統剪貼簿（透過 `pbpaste` 或 `xclip`）

**處理流程**：
1. 檢查依賴（joplin CLI、剪貼簿指令）
2. 載入配置檔（如存在）
3. 讀取剪貼簿內容
4. 驗證剪貼簿非空
5. 切換到目標筆記本（`NOTEBOOK_POST`）
6. 建立筆記並設定標題
7. 構建筆記主體（包含元數據、內容、TODO 清單）
8. 寫入筆記內容
9. 執行同步（如啟用 `AUTO_SYNC`）
10. 顯示成功訊息和筆記資訊

**生成的筆記結構**：
```markdown
# [Article Title]

> 📅 Created: YYYY-MM-DD HH:MM
> 🏷️ Tags: #article #draft

---

[剪貼簿內容]

---

## TODO
- [ ] Add implementation examples
- [ ] Add resource links
- [ ] Proofread and format
```

**配置項目**：
- `NOTEBOOK_POST`：目標筆記本名稱（預設：`Blog Posts`）
- `TEMPLATE_TAGS_LEARN`：自動添加的標籤（預設：`#article #draft`）
- `DATE_FORMAT`：日期格式（預設：`%Y-%m-%d`）
- `TIME_FORMAT`：時間格式（預設：`%H:%M`）
- `AUTO_SYNC`：自動同步開關（預設：`true`）

**錯誤處理**：
- 剪貼簿空白 → 提示使用方法
- Joplin CLI 未安裝 → 提示安裝指令
- 筆記本不存在 → 列出可用筆記本、提示建立指令
- 筆記建立失敗 → 顯示錯誤訊息

**驗收標準**：
- ✅ 正確讀取剪貼簿內容
- ✅ 筆記建立在正確的筆記本
- ✅ 元數據格式正確
- ✅ 支援多行內容
- ✅ 支援 Markdown 格式
- ✅ 同步功能正常

---

#### 3.1.2 `til` - 追加今日學習條目

**功能描述**：
從剪貼簿讀取內容，追加到今日的 TIL 筆記。如果今日筆記不存在則建立新筆記。

**指令語法**：
```bash
til "Concept Name"
```

**參數**：
- `Concept Name`（必要）：學習概念的簡短描述

**輸入來源**：
- 系統剪貼簿

**處理流程**：
1. 檢查依賴
2. 載入配置檔
3. 讀取剪貼簿內容
4. 驗證剪貼簿非空
5. 計算今日筆記標題（使用 `DAILY_NOTE_TITLE_TEMPLATE`）
6. 切換到 Daily Notes 筆記本
7. 搜尋今日筆記
8. **如果筆記存在**：
   - 讀取現有內容
   - 在末尾追加新 TIL 區塊
   - 更新筆記
9. **如果筆記不存在**：
   - 建立新筆記
   - 寫入完整結構（含元數據）
10. 執行同步
11. 顯示成功訊息

**生成的筆記結構（新建）**：
```markdown
# YYYY-MM-DD Daily Notes

> 🗓️ Date: YYYY-MM-DD
> 🏷️ Tags: #til #daily

## [HH:MM] Concept Name

[剪貼簿內容]
```

**追加的 TIL 區塊**：
```markdown

## [HH:MM] Concept Name

[剪貼簿內容]
```

**配置項目**：
- `NOTEBOOK_DAILY`：目標筆記本（預設：`Daily Notes`）
- `TEMPLATE_TAGS_TIL`：標籤（預設：`#til #daily`）
- `DAILY_NOTE_TITLE_TEMPLATE`：筆記標題模板（預設：`{DATE} Daily Notes`）
- `DATE_FORMAT`：日期格式
- `TIME_FORMAT`：時間格式

**特殊功能**：
- **智慧追加**：同一天執行多次 `til`，所有條目都追加到同一筆記
- **時間戳記**：每個 TIL 條目自動加上記錄時間
- **無重複筆記**：不會建立多個同日期筆記

**錯誤處理**：
- 剪貼簿空白 → 提示
- 筆記本不存在 → 提示建立
- 讀取現有筆記失敗 → 錯誤訊息
- 無法取得筆記 ID → 錯誤訊息

**驗收標準**：
- ✅ 新建立的筆記結構正確
- ✅ 追加功能正常（不覆蓋舊內容）
- ✅ 時間戳正確
- ✅ 同一天多次呼叫只產生一個筆記
- ✅ 跨日期正確建立新筆記

---

#### 3.1.3 `weekly` - 建立週報模板

**功能描述**：
從剪貼簿讀取摘要內容，在 "Weekly Reviews" 筆記本建立週報筆記，自動計算本週日期範圍。

**指令語法**：
```bash
weekly "Week Title"
```

**參數**：
- `Week Title`（必要）：週報標題（如 "W07 學習週報"）

**輸入來源**：
- 系統剪貼簿

**處理流程**：
1. 檢查依賴
2. 載入配置檔
3. 讀取剪貼簿內容
4. 驗證剪貼簿非空
5. **計算週日期範圍**：
   - 取得當前星期幾（1=週一，7=週日）
   - 計算本週一日期
   - 計算本週日日期
   - 支援 macOS 和 Linux 的 `date` 指令差異
6. 切換到 Weekly Reviews 筆記本
7. 建立筆記
8. 構建筆記內容（包含週範圍、摘要、統計模板）
9. 寫入內容
10. 執行同步
11. 顯示成功訊息

**生成的筆記結構**：
```markdown
# [Week Title]

> 📅 Week: YYYY-MM-DD ~ YYYY-MM-DD
> 📝 Created: YYYY-MM-DD
> 🏷️ Tags: #weekly #review

---

[剪貼簿內容]

---

## Weekly Stats
- ⏱️ **Learning Hours**: ___ hours
- 📚 **Completed Courses**: ___
- 💻 **Projects**: ___

## Next Week Plan
- [ ] 

## Reflection & Improvements
```

**配置項目**：
- `NOTEBOOK_WEEKLY`：筆記本（預設：`Weekly Reviews`）
- `TEMPLATE_TAGS_WEEKLY`：標籤（預設：`#weekly #review`）
- `WEEK_DATE_FORMAT`：週日期格式（預設：`%Y-%m-%d`）

**日期計算細節**：
```bash
# macOS
WEEK_START=$(date -v-${days_to_monday}d +"%Y-%m-%d")
WEEK_END=$(date -v+$((6 - days_to_monday))d +"%Y-%m-%d")

# Linux
WEEK_START=$(date -d "-${days_to_monday} days" +"%Y-%m-%d")
WEEK_END=$(date -d "+$((6 - days_to_monday)) days" +"%Y-%m-%d")
```

**跨平台相容性**：
- ✅ macOS（使用 `-v` 標記）
- ✅ Linux（使用 `-d` 標記）
- ⚠️ Windows WSL（使用 Linux 邏輯）

**驗收標準**：
- ✅ 週範圍計算正確（週一到週日）
- ✅ 跨平台日期計算正常
- ✅ 模板結構完整
- ✅ 元數據正確

---

### 3.2 共同功能

#### 3.2.1 配置管理

**配置檔案位置**：
```
~/.config/joplin-workflow/config
```

**載入邏輯**：
```bash
CONFIG_FILE="$HOME/.config/joplin-workflow/config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
elif [ "$DEBUG" = "true" ]; then
    echo "⚠️  Config file not found, using defaults: $CONFIG_FILE"
fi
```

**配置項目完整列表**：

| 項目 | 預設值 | 描述 | 使用指令 |
|------|--------|------|---------|
| `NOTEBOOK_DAILY` | `Daily Notes` | TIL 筆記本名稱 | `til` |
| `NOTEBOOK_POST` | `Blog Posts` | 文章筆記本名稱 | `learn` |
| `NOTEBOOK_WEEKLY` | `Weekly Reviews` | 週報筆記本名稱 | `weekly` |
| `TEMPLATE_TAGS_TIL` | `#til #daily` | TIL 標籤 | `til` |
| `TEMPLATE_TAGS_LEARN` | `#article #draft` | 文章標籤 | `learn` |
| `TEMPLATE_TAGS_WEEKLY` | `#weekly #review` | 週報標籤 | `weekly` |
| `DATE_FORMAT` | `%Y-%m-%d` | 日期格式 | 所有 |
| `TIME_FORMAT` | `%H:%M` | 時間格式 | 所有 |
| `WEEK_DATE_FORMAT` | `%Y-%m-%d` | 週日期格式 | `weekly` |
| `DAILY_NOTE_TITLE_TEMPLATE` | `{DATE} Daily Notes` | 每日筆記標題模板 | `til` |
| `AUTO_SYNC` | `true` | 自動同步開關 | 所有 |
| `SYNC_TIMEOUT` | `30` | 同步超時（秒） | 所有 |
| `DEBUG` | `false` | 除錯模式 | 所有 |

**配置範例**：
```bash
# 自訂筆記本名稱
NOTEBOOK_DAILY="學習日誌"
NOTEBOOK_POST="技術文章"
NOTEBOOK_WEEKLY="週報"

# 中文標籤
TEMPLATE_TAGS_TIL="#今日學習 #每日"
TEMPLATE_TAGS_LEARN="#文章 #草稿"
TEMPLATE_TAGS_WEEKLY="#週報 #回顧"

# 自訂日期格式
DATE_FORMAT="%Y年%m月%d日"
DAILY_NOTE_TITLE_TEMPLATE="{DATE} 學習記錄"
```

---

#### 3.2.2 依賴檢查

**檢查函式**：
```bash
check_dependencies() {
    if ! command -v joplin >/dev/null 2>&1; then
        print_error "Joplin CLI is not installed"
        echo "  Install with: npm install -g joplin"
        exit 1
    fi
    
    if ! command -v pbpaste >/dev/null 2>&1; then
        print_error "Clipboard command 'pbpaste' not found"
        echo "  On Linux, install xclip and set up aliases"
        echo "  See: docs/installation.md"
        exit 1
    fi
}
```

**檢查時機**：
- 每個指令執行時都會檢查
- 在解析參數後、執行主要邏輯前

---

#### 3.2.3 幫助訊息

**觸發條件**：
```bash
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    # 顯示幫助訊息
    exit 0
fi
```

**幫助訊息結構**：
- **Usage**：指令語法
- **Examples**：使用範例（2-3 個）
- **Configuration**：相關配置項目
- **See**：參考文件連結

**範例**（`learn` 指令）：
```
Usage: learn "Article Title"

Create a learning article in the configured notebook (default: Blog Posts).
Content is read from clipboard.

Examples:
  echo "Article content" | pbcopy
  learn "Understanding React Hooks"
  
  pbcopy < article.md
  learn "Complete Guide to TDD"

Configuration:
  Edit ~/.config/joplin-workflow/config to customize:
  - NOTEBOOK_POST: Target notebook name
  - TEMPLATE_TAGS_LEARN: Default tags
  - DATE_FORMAT, TIME_FORMAT: Date/time formats

See: docs/usage.md for detailed examples
```

---

#### 3.2.4 自動同步

**同步邏輯**：
```bash
if [ "$AUTO_SYNC" = "true" ]; then
    echo ""
    echo "⏳ Syncing..."
    if joplin sync 2>&1 | grep -q "Completed\|完成"; then
        print_success "Sync complete!"
    else
        echo "⚠️  Sync may have issues (check 'joplin sync' manually)"
    fi
fi
```

**支援語言**：
- 英文：`Completed`
- 中文：`完成`

**同步時機**：
- 筆記建立/更新成功後
- 僅在 `AUTO_SYNC=true` 時執行

---

#### 3.2.5 除錯模式

**啟用方式**：
```bash
DEBUG="true"  # 在配置檔中設定
```

**除錯輸出**：
```bash
debug_log() {
    if [ "$DEBUG" = "true" ]; then
        echo "🐛 DEBUG: $1" >&2
    fi
}

# 使用範例
debug_log "Title: $TITLE"
debug_log "Clipboard content length: ${#CLIPBOARD_CONTENT} characters"
```

**除錯資訊包含**：
- 參數解析結果
- 配置載入狀態
- 剪貼簿內容長度
- 筆記 ID
- 操作步驟追蹤

---

#### 3.2.6 錯誤處理

**錯誤處理模式**：
```bash
set -e  # 遇到錯誤立即退出
```

**常見錯誤與處理**：

| 錯誤情境 | 錯誤碼 | 訊息 | 處理方式 |
|---------|--------|------|---------|
| 未提供參數 | 1 | Usage 訊息 | 顯示使用範例後退出 |
| 剪貼簿空白 | 1 | "Clipboard is empty" | 提示如何複製內容 |
| Joplin CLI 未安裝 | 1 | "Joplin CLI is not installed" | 提示安裝指令 |
| 筆記本不存在 | 1 | "Notebook not found" | 列出可用筆記本 + 建立指令 |
| 筆記建立失敗 | 1 | "Failed to create note" | 顯示錯誤訊息 |
| 無法取得筆記 ID | 1 | "Failed to get note ID" | 錯誤訊息 |
| 同步失敗 | 0 | "Sync may have issues" | 警告但不中斷（非致命） |

**錯誤訊息範例**：
```bash
# 剪貼簿空白
❌ Clipboard is empty

Please copy content first:
  echo "Your content" | pbcopy
  # or copy from editor/browser

# 筆記本不存在
❌ Notebook not found: Daily Notes

Available notebooks:
  Inbox
  Projects

Create notebook with:
  joplin mkbook "Daily Notes"

Or configure different notebook in:
  ~/.config/joplin-workflow/config
```

---

### 3.3 輔助功能

#### 3.3.1 輸出格式化

**輔助函式**：
```bash
print_error() {
    echo "❌ $1" >&2
}

print_success() {
    echo "✅ $1"
}

print_info() {
    echo "💡 $1"
}
```

**使用 Emoji**：
- ✅ 成功
- ❌ 錯誤
- 💡 提示
- 📌 找到筆記
- 📄 建立筆記
- ⏳ 同步中
- 🐛 除錯訊息

---

## 4. 安裝系統

### 4.1 安裝腳本 (`install.sh`)

**功能**：
1. 檢查系統需求
2. 偵測作業系統類型
3. 檢查必要依賴
4. 建立目錄結構
5. 建立指令符號連結
6. 設定配置檔
7. 配置剪貼簿支援（Linux）
8. 更新 Shell 配置

**安裝流程圖**：
```
開始
 ↓
檢測 OS (macOS/Linux/Windows)
 ↓
檢查 Joplin CLI → 未安裝 → 提示安裝 → 退出
 ↓ 已安裝
檢查 jq → 未安裝 → 提示安裝 → 退出
 ↓ 已安裝
檢查剪貼簿工具
 ↓
建立目錄
 - ~/.local/bin
 - ~/.config/joplin-workflow
 ↓
建立符號連結
 - learn → [project]/bin/learn
 - til → [project]/bin/til
 - weekly → [project]/bin/weekly
 ↓
複製配置檔範例 → ~/.config/joplin-workflow/config
 ↓
更新 PATH (如需要)
 - .zshrc 或 .bashrc
 ↓
Linux 特有：配置 xclip alias
 ↓
提示重新載入 Shell
 ↓
完成
```

**支援的 Shell**：
- ✅ zsh（預設 macOS）
- ✅ bash（Linux 預設）

**平台支援**：
- ✅ macOS（完整測試）
- ✅ Linux（支援）
- ⚠️ Windows WSL（實驗性支援）

---

### 4.2 依賴檢查

**必要依賴**：
```bash
check_command "joplin"  # Joplin CLI
check_command "jq"      # JSON processor
```

**可選依賴**：
```bash
# macOS
check_command "pbcopy"
check_command "pbpaste"

# Linux
check_command "xclip"
```

**安裝建議**（安裝腳本會顯示）：
```
macOS:
  brew install node
  npm install -g joplin
  brew install jq

Linux (Ubuntu/Debian):
  sudo apt update
  sudo apt install nodejs npm jq xclip
  npm install -g joplin

Linux (Fedora):
  sudo dnf install nodejs npm jq xclip
  npm install -g joplin
```

---

### 4.3 目錄結構建立

**建立的目錄**：
```bash
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/joplin-workflow"
```

**權限**：
- 目錄：`755` (rwxr-xr-x)
- 配置檔：`644` (rw-r--r--)
- 腳本：`755` (rwxr-xr-x)

---

### 4.4 符號連結建立

**連結建立邏輯**：
```bash
ln -sf "$SCRIPT_DIR/bin/learn" "$INSTALL_DIR/learn"
ln -sf "$SCRIPT_DIR/bin/til" "$INSTALL_DIR/til"
ln -sf "$SCRIPT_DIR/bin/weekly" "$INSTALL_DIR/weekly"
```

**特性**：
- 使用 `-sf` 強制覆蓋（支援重新安裝）
- 使用絕對路徑確保連結正確

---

### 4.5 配置檔設定

**配置檔初始化**：
```bash
if [ ! -f "$CONFIG_DIR/config" ]; then
    cp "$SCRIPT_DIR/config/joplin-workflow.conf.example" "$CONFIG_DIR/config"
    print_success "Created config file: $CONFIG_DIR/config"
else
    print_info "Config file already exists (preserving)"
fi
```

**保護現有配置**：
- 不覆蓋已存在的配置檔
- 升級時保留使用者自訂設定

---

### 4.6 PATH 配置

**自動添加到 PATH**：
```bash
# 偵測 Shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

# 檢查是否已存在
if ! grep -q "$INSTALL_DIR" "$SHELL_CONFIG" 2>/dev/null; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
fi
```

---

### 4.7 剪貼簿配置（Linux）

**xclip alias 設定**：
```bash
# 在 .bashrc 或 .zshrc 中添加
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
```

**目的**：
- 讓 Linux 使用與 macOS 相同的指令
- 保持腳本跨平台一致性

---

## 5. 使用者工作流

### 5.1 典型使用場景

#### 場景 1：從 Copilot Chat 建立技術文章

```bash
# 1. 在 VS Code 中使用 Copilot Chat
# 提問：「解釋 React useCallback 的使用時機」

# 2. 複製 AI 回應（Cmd+C / Ctrl+C）

# 3. 在終端機執行
learn "React useCallback 深入理解"

# 輸出：
# ✅ Learning note created!
# 📝 Title: React useCallback 深入理解
# 📁 Notebook: Blog Posts
# 🔗 ID: abc123...
```

#### 場景 2：每日學習記錄（多個 TIL）

```bash
# 早上學習
echo "Promise.all() 會在任一 promise reject 時立即 reject" | pbcopy
til "Promise.all() 行為"

# 下午學習
echo "Array.reduce() 可以取代 map + filter 的組合" | pbcopy
til "Array.reduce() 進階用法"

# 晚上學習
echo "使用 git rebase -i HEAD~3 可以整理最近 3 個 commits" | pbcopy
til "Git Rebase 互動模式"

# 結果：所有 TIL 都在同一筆記 "2026-02-18 Daily Notes"
```

#### 場景 3：週報生成

```bash
# 1. 在 Perplexity 整理本週學習摘要
# 或手動撰寫摘要

# 2. 複製摘要內容

# 3. 建立週報
weekly "W07 前端開發學習週報"

# 結果：自動計算週範圍（2026-02-10 ~ 2026-02-16）
```

---

### 5.2 推薦工作流

#### 工作流 A：AI 驅動學習

```
學習過程 → Copilot Chat/Perplexity 提問
         ↓
      複製 AI 回應
         ↓
      決定筆記類型
         ↓
  ┌─────┴──────┐
  │            │
快速知識點    完整文章
  │            │
  til "..."    learn "..."
  │            │
  └─────┬──────┘
        ↓
    自動同步到所有設備
```

#### 工作流 B：程式碼片段記錄

```
除錯/實作 → 發現有用的程式碼片段
           ↓
        複製程式碼 + 說明
           ↓
        til "技術名稱"
           ↓
        日後搜尋：joplin search "關鍵字"
```

#### 工作流 C：每週回顧

```
週一到週五：每日使用 til 記錄
             ↓
週六：查看本週所有 Daily Notes
      joplin ls  (在 Daily Notes notebook)
             ↓
   整理重點（手動或用 AI）
             ↓
      weekly "W## 週報"
             ↓
   填寫統計、計畫、反思
```

---

## 6. 測試與品質保證

### 6.1 測試狀態

**v0.1.0 測試範圍**：
- ✅ 手動功能測試（macOS）
- ✅ 基本錯誤處理測試
- ⚠️ 自動化測試：待開發（`tests/` 目錄存在但未實作）

### 6.2 測試環境

| 平台 | 版本 | 測試狀態 | 備註 |
|------|------|---------|------|
| macOS | 14.2 (Tahoe) | ✅ 完整測試 | 主要開發環境 |
| Linux Ubuntu | 22.04 | ⚠️ 基本測試 | 需更多測試 |
| Windows WSL | WSL2 | ⚠️ 實驗性 | 已知可用但未充分測試 |

### 6.3 已知問題

目前沒有已知的嚴重 bug。

### 6.4 未來測試計劃

計劃在後續版本加入：
- 自動化測試套件
- 跨平台 CI/CD
- 邊界情況測試
- 效能測試

---

## 7. 效能規格

### 7.1 執行時間

| 操作 | 典型時間 | 最大可接受時間 |
|------|---------|---------------|
| `learn` 建立筆記 | < 2 秒 | < 5 秒 |
| `til` 追加條目 | < 2 秒 | < 5 秒 |
| `til` 建立新筆記 | < 2 秒 | < 5 秒 |
| `weekly` 建立筆記 | < 2 秒 | < 5 秒 |
| 同步操作 | 視網路速度 | 30 秒（可配置） |

### 7.2 資源使用

- **記憶體**：< 50 MB（Shell 腳本輕量）
- **CPU**：極低（主要是 I/O 操作）
- **網路**：僅同步時使用

### 7.3 擴展性

- **筆記數量**：無限制（依賴 Joplin 效能）
- **筆記大小**：無限制（受剪貼簿大小限制）
- **同時使用者**：單使用者設計

---

## 8. 安全性考量

### 8.1 資料安全

- ✅ 所有資料儲存在本機 Joplin 資料庫
- ✅ 不傳送資料到第三方服務
- ✅ 同步使用 Joplin 內建機制（加密）

### 8.2 權限

- 腳本使用使用者權限執行
- 不需要 sudo
- 僅存取 `.config` 和 `.local` 目錄

### 8.3 隱私

- 不收集使用統計
- 不包含追蹤程式碼
- 開源透明（MIT License）

---

## 9. 相容性

### 9.1 作業系統

| OS | 狀態 | 備註 |
|----|------|------|
| macOS 14+ | ✅ 完整支援 | 主要開發平台 |
| macOS 13- | 🔶 應該可用 | 未測試 |
| Linux (Ubuntu/Debian) | ✅ 支援 | 需安裝 xclip |
| Linux (Fedora/RHEL) | ✅ 支援 | 需安裝 xclip |
| Linux (Arch) | 🔶 應該可用 | 未測試 |
| Windows WSL2 | ⚠️ 實驗性 | 需 xclip |
| Windows Native | ❌ 不支援 | 需 PowerShell 版本 |

### 9.2 Shell

| Shell | 狀態 | 備註 |
|-------|------|------|
| Bash 4.0+ | ✅ 完整支援 | |
| Zsh | ✅ 完整支援 | macOS 預設 |
| Fish | ❌ 不支援 | 語法不相容 |
| PowerShell | ❌ 不支援 | Windows 版本計劃中 |

### 9.3 Joplin 版本

- **Joplin CLI**: Latest (透過 npm)
- **Joplin Desktop**: 任何版本（可選）
- **API 版本**: 使用 Joplin CLI 命令列介面，不直接呼叫 API

---

## 10. 文件

### 10.1 已提供文件

| 文件 | 路徑 | 內容 |
|------|------|------|
| **README** | `README.md` | 專案概述、快速開始 |
| **安裝指南** | `docs/installation.md` | 詳細安裝步驟（483 行） |
| **使用指南** | `docs/usage.md` | 完整使用說明（755 行） |
| **工作流程** | `docs/workflows.md` | 實際工作流程範例 |
| **自訂指南** | `docs/customization.md` | 配置與自訂 |
| **版本記錄** | `CHANGELOG.md` | 版本變更記錄 |
| **授權** | `LICENSE` | MIT License |
| **本規格書** | `docs/spec-v0.1.0.md` | 技術規格（本文件） |

### 10.2 文件特色

- ✅ 完整的範例程式碼
- ✅ 截圖和輸出範例
- ✅ 故障排除章節
- ✅ 多種使用場景
- ✅ 跨平台說明

---

## 11. 限制與已知約束

### 11.1 技術限制

1. **純 CLI 操作**：無 GUI，不適合非技術使用者
2. **依賴 Joplin**：必須安裝 Joplin CLI
3. **剪貼簿依賴**：輸入必須透過剪貼簿
4. **同步依賴 Joplin**：不提供獨立同步機制
5. **單一使用者**：非多使用者協作設計

### 11.2 功能限制

1. **無自動內容生成**：不包含 AI 生成功能（v0.2.0 計劃）
2. **無筆記解析**：不解析現有筆記內容
3. **無範本引擎**：範本嵌入在腳本中
4. **無搜尋功能**：使用 Joplin 原生搜尋
5. **無統計功能**：不提供學習分析

### 11.3 設計約束

1. **筆記本必須預先存在**：腳本不自動建立筆記本
2. **配置檔無驗證**：不驗證配置值有效性
3. **錯誤訊息英文為主**：部分中文支援
4. **無版本檢查**：不檢查 Joplin CLI 版本相容性

---

## 12. 授權與貢獻

### 12.1 授權
- **授權類型**：MIT License
- **商業使用**：✅ 允許
- **修改**：✅ 允許
- **分發**：✅ 允許
- **專利使用**：✅ 允許
- **責任**：❌ 無擔保

### 12.2 開源專案資訊
- **GitHub**：https://github.com/gcake119/joplin-dev-workflow
- **Issue**：接受 bug 回報和功能建議
- **Pull Request**：歡迎貢獻

---

## 13. 版本資訊

### 13.1 版本號命名
遵循 [Semantic Versioning 2.0.0](https://semver.org/)：
- `MAJOR.MINOR.PATCH`
- v0.1.0：初始公開版本

### 13.2 v0.1.0 發布資訊

**發布日期**：2026-02-16

**主要功能**：
- ✅ `learn` 指令：建立技術文章
- ✅ `til` 指令：每日學習記錄
- ✅ `weekly` 指令：週報模板
- ✅ 配置系統
- ✅ 自動同步
- ✅ 安裝腳本
- ✅ 完整文件

**測試狀態**：
- ✅ macOS 14.2 完整測試
- ⚠️ Linux 基本測試
- ⚠️ Windows WSL 實驗性

**已知問題**：
- 無

---

## 14. 後續規劃（非 v0.1.0 範圍）

### 14.1 計劃功能（v0.2.0+）

參見 `CHANGELOG.md` 中的 `[Unreleased]` 區段：

- 🔮 自動掃描 git commits 生成技術筆記
- 🔮 解析現有筆記生成結構化文件
- 🔮 範本系統
- 🔮 學習分析儀表板
- 🔮 VS Code 深度整合
- 🔮 Windows 原生支援（PowerShell）
- 🔮 自動化測試套件
- 🔮 套件管理器分發（Homebrew、apt）
- 🔮 **AI 自動化筆記生成**（v0.2.0 主要功能）

### 14.2 AI 功能規劃（v0.2.0）

已有獨立規格書：`docs/spec-ai-auto-generation.md`

- `learn-auto`：從今日 TIL 自動生成學習文章
- `weekly-auto`：從本週 TIL 自動生成週報
- 使用本地 Ollama + Codestral 模型
- 保持向後相容

---

## 15. 附錄

### 15.1 術語表

| 術語 | 定義 |
|------|------|
| **TIL** | Today I Learned - 今日學習記錄 |
| **Joplin** | 開源筆記應用程式 |
| **Joplin CLI** | Joplin 的命令列介面 |
| **Notebook** | Joplin 中的筆記本（資料夾） |
| **Clipboard** | 系統剪貼簿 |
| **Sync** | 同步（跨設備） |
| **pbcopy/pbpaste** | macOS 剪貼簿指令 |
| **xclip** | Linux 剪貼簿工具 |
| **Shell** | 命令列介面（Bash/Zsh） |

### 15.2 參考資源

**官方文件**：
- Joplin：https://joplinapp.org
- Joplin CLI：https://joplinapp.org/terminal/
- Bash Guide：https://www.gnu.org/software/bash/manual/

**專案資源**：
- GitHub Repo：https://github.com/gcake119/joplin-dev-workflow
- Issue Tracker：https://github.com/gcake119/joplin-dev-workflow/issues

### 15.3 配置範例

**完整配置檔範例**：
```bash
# ~/.config/joplin-workflow/config

# 筆記本配置
NOTEBOOK_DAILY="Daily Notes"
NOTEBOOK_POST="Blog Posts"
NOTEBOOK_WEEKLY="Weekly Reviews"

# 標籤配置
TEMPLATE_TAGS_TIL="#til #daily"
TEMPLATE_TAGS_LEARN="#article #draft"
TEMPLATE_TAGS_WEEKLY="#weekly #review"

# 日期格式
DATE_FORMAT="%Y-%m-%d"
TIME_FORMAT="%H:%M"
WEEK_DATE_FORMAT="%Y-%m-%d"

# TIL 筆記標題
DAILY_NOTE_TITLE_TEMPLATE="{DATE} Daily Notes"

# 自動同步
AUTO_SYNC="true"
SYNC_TIMEOUT="30"

# 除錯模式
DEBUG="false"
```

### 15.4 使用統計（目標使用者）

**目標使用者畫像**：
- 開發者、技術學習者
- 使用 VS Code + Terminal 工作
- 習慣命令列操作
- 使用 AI 工具學習（Copilot、Perplexity）
- 需要跨設備同步筆記

**預期使用頻率**：
- `til`：每日 3-10 次
- `learn`：每週 1-3 次
- `weekly`：每週 1 次

---

## 16. 變更記錄

| 版本 | 日期 | 作者 | 變更說明 |
|------|------|------|---------|
| 1.0 | 2026-02-18 | System | 根據 v0.1.0 實際實作撰寫初始規格書 |

---

**文件狀態**：✅ Complete - v0.1.0 Released

**維護者**：gcake119

**最後更新**：2026-02-18
