# Customization Guide

Complete guide to customizing Joplin Dev Workflow to fit your needs.

---

## Table of Contents

- [Configuration File](#configuration-file)
- [Notebook Customization](#notebook-customization)
- [Template Customization](#template-customization)
- [Tag Management](#tag-management)
- [Date and Time Formats](#date-and-time-formats)
- [Note Title Patterns](#note-title-patterns)
- [Advanced Configuration](#advanced-configuration)
- [Examples](#examples)

---

## Configuration File

### Location

```
~/.config/joplin-workflow/config
```

### Basic Structure

```bash
# Joplin Desktop Data API
JOPLIN_WRITE_ADAPTER="data_api"
JOPLIN_API_TOKEN=""
JOPLIN_API_BASE_URL=""
JOPLIN_API_PORT_START="41184"
JOPLIN_API_PORT_END="41194"
JOPLIN_API_TIMEOUT="5"

# Notebook mappings
NOTEBOOK_DAILY_ID=""
NOTEBOOK_DAILY="Daily Notes"
NOTEBOOK_POST_ID=""
NOTEBOOK_POST="Blog Posts"
NOTEBOOK_WEEKLY_ID=""
NOTEBOOK_WEEKLY="Weekly Reviews"

# Template tags
TEMPLATE_TAGS_TIL="#til #daily"
TEMPLATE_TAGS_LEARN="#article #draft"
TEMPLATE_TAGS_WEEKLY="#weekly #review"

# Date formats
DATE_FORMAT="%Y-%m-%d"
TIME_FORMAT="%H:%M"
```

### Editing Configuration

```bash
# Use your preferred editor
nano ~/.config/joplin-workflow/config

# Or
code ~/.config/joplin-workflow/config

# Or
vim ~/.config/joplin-workflow/config
```

### Apply Changes

Configuration is read each time you run a command - no restart needed!

```bash
# Test new config immediately
echo "Test" | pbcopy
learn "Test Config"
```

---

## Notebook Customization

### Change Notebook Names

Edit the configuration file to use your existing Joplin notebooks. Folder IDs are preferred because Data API writes require a `parent_id` and titles can be duplicated:

```bash
# Preferred: folder IDs copied from Joplin Desktop/Data API
NOTEBOOK_DAILY_ID="0123456789abcdef0123456789abcdef"
NOTEBOOK_POST_ID="fedcba9876543210fedcba9876543210"
NOTEBOOK_WEEKLY_ID="11112222333344445555666677778888"

# Title fallback when titles are unique
NOTEBOOK_DAILY="Daily Notes"
NOTEBOOK_POST="Blog Posts"
NOTEBOOK_WEEKLY="Weekly Reviews"

# Example: Use Chinese names
NOTEBOOK_DAILY="每日記錄"
NOTEBOOK_POST="技術文章"
NOTEBOOK_WEEKLY="週報"

# Example: Use emoji
NOTEBOOK_DAILY="📅 Daily"
NOTEBOOK_POST="📝 Articles"
NOTEBOOK_WEEKLY="📊 Weekly"

# If two notebooks share the same title, set the matching NOTEBOOK_*_ID.
```

### Create Custom Notebooks

Create custom notebooks in Joplin Desktop, then update the config:

```bash
NOTEBOOK_DAILY="My Learning Journal"
NOTEBOOK_POST="Tech Articles"
NOTEBOOK_WEEKLY="Monthly Reviews"

# Recommended when titles are duplicated or nested
NOTEBOOK_DAILY_ID="..."
NOTEBOOK_POST_ID="..."
NOTEBOOK_WEEKLY_ID="..."
```

### Multiple Profiles

Create different configs for different projects:

```bash
# Work profile
cp ~/.config/joplin-workflow/config ~/.config/joplin-workflow/config.work

# Personal profile
cp ~/.config/joplin-workflow/config ~/.config/joplin-workflow/config.personal

# Switch profiles
ln -sf ~/.config/joplin-workflow/config.work ~/.config/joplin-workflow/config
```

---

## Template Customization

### Understanding Templates

Templates are defined in the script files (`bin/learn`, `bin/til`, `bin/weekly`).

**Current approach**: Edit scripts directly  
**Future version**: External template files (coming soon)

### Modify Script Templates

#### `learn` Template

Edit `bin/learn` to customize the article template:

```bash
# Default template
NOTE_BODY="# ${TITLE}

> 📅 Created: ${CURRENT_DATE} ${CURRENT_TIME}
> 🏷️ Tags: ${TEMPLATE_TAGS_LEARN}

***

${CLIPBOARD_CONTENT}

***

## TODO
- [ ] Add implementation examples
- [ ] Add resource links
"
```

**Customization examples**:

```bash
# Example 1: Academic style
NOTE_BODY="# ${TITLE}

**Author**: Your Name  
**Date**: ${CURRENT_DATE}  
**Tags**: ${TEMPLATE_TAGS_LEARN}

***

## Abstract

${CLIPBOARD_CONTENT}

***

## References

1. [Source 1]()
2. [Source 2]()

## Notes

"

# Example 2: Minimalist
NOTE_BODY="# ${TITLE}

${CLIPBOARD_CONTENT}

***

*Created on ${CURRENT_DATE}*
"

# Example 3: Detailed structure
NOTE_BODY="# ${TITLE}

> 📅 ${CURRENT_DATE} ${CURRENT_TIME}
> 🏷️ ${TEMPLATE_TAGS_LEARN}
> 📂 Category: [To be filled]
> 🔗 Related: [Links to related notes]

***

## Summary

${CLIPBOARD_CONTENT}

***

## Key Takeaways

- 

## Code Examples

\`\`\`javascript
// Example code
\`\`\`

## Resources

- 

## Next Steps

- [ ] 
"
```

#### `til` Template

Edit `bin/til` for daily note format:

```bash
# Default
NEW_TIL_BLOCK="
## [${CURRENT_TIME}] ${CONCEPT}

${CLIPBOARD_CONTENT}
"

# Example 1: With difficulty rating
NEW_TIL_BLOCK="
## [${CURRENT_TIME}] ${CONCEPT}

**Difficulty**: ⭐⭐⭐☆☆

${CLIPBOARD_CONTENT}

**Related**: 
"

# Example 2: With source
NEW_TIL_BLOCK="
## 💡 ${CONCEPT} (${CURRENT_TIME})

${CLIPBOARD_CONTENT}

📚 **Source**: [Link/Book/Course]
"

# Example 3: Structured learning
NEW_TIL_BLOCK="
***

### ${CONCEPT}
**Time**: ${CURRENT_TIME}

**What I Learned**:
${CLIPBOARD_CONTENT}

**How to Use**:


**Example**:
\`\`\`

\`\`\`
"
```

#### `weekly` Template

Edit `bin/weekly` for review structure:

```bash
# Default
NOTE_BODY="# ${TITLE}

> 📅 Week: ${WEEK_START} ~ ${WEEK_END}
> 📝 Created: ${CURRENT_DATE}
> 🏷️ Tags: ${TEMPLATE_TAGS_WEEKLY}

***

${CLIPBOARD_CONTENT}

***

## Weekly Stats
- ⏱️ **Learning Hours**: ___ hours
- 📚 **Completed Courses**: ___
- 💻 **Projects**: ___

## Next Week Plan
- [ ] 

## Reflection
"

# Example 1: Agile sprint format
NOTE_BODY="# ${TITLE}

**Sprint**: Week ${WEEK_NUMBER}  
**Period**: ${WEEK_START} to ${WEEK_END}

***

${CLIPBOARD_CONTENT}

***

## 📊 Metrics
- Story Points: ___
- Velocity: ___
- Blockers: ___

## 🎯 Goals Achieved
- [ ] Goal 1
- [ ] Goal 2

## 🚧 Challenges

## 🎓 Learnings

## ➡️ Next Sprint
"

# Example 2: Bootcamp format
NOTE_BODY="# ${TITLE}

**Bootcamp Week**: ${WEEK_NUMBER}  
**Dates**: ${WEEK_START} - ${WEEK_END}

***

${CLIPBOARD_CONTENT}

***

## 📚 Modules Completed


## 💻 Projects Built


## 🧠 Key Concepts Mastered


## ⏱️ Time Breakdown
- Lectures: ___ hrs
- Coding: ___ hrs
- Projects: ___ hrs

## 🤝 Collaboration


## 📈 Progress Towards Goals


## 🎯 Next Week Focus

"

# Example 3: Simple bullet format
NOTE_BODY="# ${TITLE}

${WEEK_START} → ${WEEK_END}

***

${CLIPBOARD_CONTENT}

***

**Wins** 🎉


**Struggles** 😓


**Lessons** 💡


**Next Steps** ➡️

"
```

---

## Tag Management

### Configure Tags

In `~/.config/joplin-workflow/config`:

```bash
# Default
TEMPLATE_TAGS_TIL="#til #daily"
TEMPLATE_TAGS_LEARN="#article #draft"
TEMPLATE_TAGS_WEEKLY="#weekly #review"
```

### Tag Best Practices

**Use Cases**:

```bash
# By topic
TEMPLATE_TAGS_LEARN="#javascript #frontend #article"

# By status
TEMPLATE_TAGS_LEARN="#draft #needs-review #article"

# By source
TEMPLATE_TAGS_TIL="#til #copilot #daily"

# By difficulty
TEMPLATE_TAGS_LEARN="#advanced #tutorial #article"

# By project
TEMPLATE_TAGS_LEARN="#project-x #documentation #article"
```

**Multi-topic tags**:

```bash
# For bootcamp students
TEMPLATE_TAGS_TIL="#til #bootcamp #day${DAY_NUMBER}"
TEMPLATE_TAGS_LEARN="#article #bootcamp #module${MODULE_NUMBER}"

# For specific courses
TEMPLATE_TAGS_TIL="#til #react-course #daily"
TEMPLATE_TAGS_LEARN="#article #react-course #notes"
```

**Organizational tags**:

```bash
# GTD-style
TEMPLATE_TAGS_LEARN="#to-process #article"
TEMPLATE_TAGS_WEEKLY="#review #archive"

# PARA method
TEMPLATE_TAGS_LEARN="#projects #frontend #article"
TEMPLATE_TAGS_TIL="#areas #learning #til"
```

---

## Date and Time Formats

### Format Syntax

Uses standard `date` command format strings.

**Common formats**:

```bash
# ISO format (default)
DATE_FORMAT="%Y-%m-%d"              # 2026-02-16
TIME_FORMAT="%H:%M"                 # 14:30

# US format
DATE_FORMAT="%m/%d/%Y"              # 02/16/2026
TIME_FORMAT="%I:%M %p"              # 02:30 PM

# European format
DATE_FORMAT="%d.%m.%Y"              # 16.02.2026
TIME_FORMAT="%H:%M"                 # 14:30

# Long format
DATE_FORMAT="%B %d, %Y"             # February 16, 2026
TIME_FORMAT="%I:%M %p"              # 02:30 PM

# Compact format
DATE_FORMAT="%Y%m%d"                # 20260216
TIME_FORMAT="%H%M"                  # 1430

# Weekday included
DATE_FORMAT="%A, %B %d, %Y"         # Monday, February 16, 2026
```

### Format Reference

| Code | Meaning | Example |
|------|---------|---------|
| `%Y` | Year (4 digits) | 2026 |
| `%y` | Year (2 digits) | 26 |
| `%m` | Month (01-12) | 02 |
| `%B` | Month name | February |
| `%b` | Month abbr | Feb |
| `%d` | Day (01-31) | 16 |
| `%A` | Weekday | Monday |
| `%a` | Weekday abbr | Mon |
| `%H` | Hour 24h (00-23) | 14 |
| `%I` | Hour 12h (01-12) | 02 |
| `%M` | Minute (00-59) | 30 |
| `%p` | AM/PM | PM |

**See full reference**: `man date`

---

## Note Title Patterns

### Daily Note Titles

Configure the TIL daily note title format:

```bash
# Default
DAILY_NOTE_TITLE_TEMPLATE="{DATE} Daily Notes"
# Output: 2026-02-16 Daily Notes

# Examples:

# With weekday
DAILY_NOTE_TITLE_TEMPLATE="{DATE} ({WEEKDAY}) Learning Log"
# Output: 2026-02-16 (Monday) Learning Log

# Chinese format
DAILY_NOTE_TITLE_TEMPLATE="{DATE} 學習記錄"
# Output: 2026-02-16 學習記錄

# Numbered days
DAILY_NOTE_TITLE_TEMPLATE="Day {DAY_NUMBER} - {DATE}"
# Output: Day 45 - 2026-02-16

# Minimalist
DAILY_NOTE_TITLE_TEMPLATE="{DATE}"
# Output: 2026-02-16
```

**Note**: Some patterns require script modification. `{DATE}` is automatically replaced.

---

## Advanced Configuration

### Sync Options

```bash
# Show a Joplin Desktop sync reminder after local Data API writes (default: true)
AUTO_SYNC="true"

# Only report the local write result
AUTO_SYNC="false"

# Reserved for legacy/fallback adapters. Data API mode uses JOPLIN_API_TIMEOUT.
SYNC_TIMEOUT="30"
```

### Debug Mode

```bash
# Enable verbose output
DEBUG="true"

# Test with:
learn "Debug Test"
# Should show detailed execution steps
```

### Custom Clipboard Command

Override clipboard detection:

```bash
# Default: auto-detected

# Custom command (if needed)
CLIPBOARD_CMD="xclip -selection clipboard -o"

# Or for Wayland
CLIPBOARD_CMD="wl-paste"

# Or for Windows WSL
CLIPBOARD_CMD="powershell.exe Get-Clipboard"
```

---

## Examples

### Example 1: Academic Research Setup

```bash
# ~/.config/joplin-workflow/config

# Notebooks
NOTEBOOK_DAILY="Research Journal"
NOTEBOOK_POST="Papers & Articles"
NOTEBOOK_WEEKLY="Weekly Lab Notes"

# Tags
TEMPLATE_TAGS_TIL="#research #daily #lab"
TEMPLATE_TAGS_LEARN="#paper #literature-review"
TEMPLATE_TAGS_WEEKLY="#weekly #progress #lab-meeting"

# Dates
DATE_FORMAT="%Y-%m-%d"
TIME_FORMAT="%H:%M"
```

### Example 2: Software Engineering Career

```bash
# Notebooks
NOTEBOOK_DAILY="Daily Standup Notes"
NOTEBOOK_POST="Technical Blog Drafts"
NOTEBOOK_WEEKLY="Sprint Retrospectives"

# Tags
TEMPLATE_TAGS_TIL="#til #work #engineering"
TEMPLATE_TAGS_LEARN="#blog #technical #tutorial"
TEMPLATE_TAGS_WEEKLY="#retrospective #sprint #team"

# Custom
AUTO_SYNC="true"
DEBUG="false"
```

### Example 3: Language Learning

```bash
# Notebooks
NOTEBOOK_DAILY="Daily Vocabulary"
NOTEBOOK_POST="Grammar Lessons"
NOTEBOOK_WEEKLY="Weekly Practice Summary"

# Tags
TEMPLATE_TAGS_TIL="#til #vocabulary #日本語"
TEMPLATE_TAGS_LEARN="#grammar #notes #study"
TEMPLATE_TAGS_WEEKLY="#weekly #practice #progress"

# Dates
DATE_FORMAT="%Y年%m月%d日"
TIME_FORMAT="%H:%M"
```

### Example 4: Freelancer Project Tracking

```bash
# Notebooks
NOTEBOOK_DAILY="Client Work Log"
NOTEBOOK_POST="Project Documentation"
NOTEBOOK_WEEKLY="Weekly Invoicing & Review"

# Tags
TEMPLATE_TAGS_TIL="#client-work #daily #billable"
TEMPLATE_TAGS_LEARN="#documentation #project #deliverable"
TEMPLATE_TAGS_WEEKLY="#invoicing #weekly #review"
```

### Example 5: Bootcamp Student (Current Project)

```bash
# Notebooks
NOTEBOOK_DAILY="每日記錄"
NOTEBOOK_POST="post"
NOTEBOOK_WEEKLY="學習進度規劃"

# Tags
TEMPLATE_TAGS_TIL="#TIL #每日記錄"
TEMPLATE_TAGS_LEARN="#學習筆記 #frontend"
TEMPLATE_TAGS_WEEKLY="#週回顧 #學習規劃"

# Dates
DATE_FORMAT="%Y-%m-%d"
TIME_FORMAT="%H:%M"
```

---

## Testing Configuration

### Verify Config Loading

```bash
# Check if config exists
cat ~/.config/joplin-workflow/config

# Test with dry run (check output)
echo "Test content" | pbcopy
learn --dry-run "Config Test"

# Check Data API and notebook resolution
joplin-workflow-doctor
```

### Backup Configuration

```bash
# Backup current config
cp ~/.config/joplin-workflow/config ~/.config/joplin-workflow/config.backup

# Restore if needed
cp ~/.config/joplin-workflow/config.backup ~/.config/joplin-workflow/config
```

---

## Troubleshooting

### Config Not Loading

```bash
# Check file permissions
ls -l ~/.config/joplin-workflow/config

# Should be readable
chmod 644 ~/.config/joplin-workflow/config
```

### Syntax Errors

```bash
# Test bash syntax
bash -n ~/.config/joplin-workflow/config

# No output = no errors
```

### Wrong Notebook

```bash
# Verify configured targets without writing notes
joplin-workflow-doctor

# Check exact name (case-sensitive)
NOTEBOOK_DAILY="Daily Notes"  # ✅ Correct
NOTEBOOK_DAILY="daily notes"  # ❌ Wrong case

# Prefer IDs when titles are duplicated or nested
NOTEBOOK_DAILY_ID="0123456789abcdef0123456789abcdef"
```

---

## Tested Environment

**Configuration tested on**:
- **OS**: macOS 26.2 (Tahoe)
- **Shell**: zsh 5.9
- **Joplin Desktop**: Web Clipper/Data API enabled

---

## Next Steps

- 🔄 [Learn workflow best practices](workflows.md)
- 📖 [Read usage examples](usage.md)
- 🐛 [Troubleshoot issues](troubleshooting.md)

---

## Contributing

Have a useful configuration example? Share it in [GitHub Discussions](https://github.com/gcake119/joplin-dev-workflow/discussions)!
