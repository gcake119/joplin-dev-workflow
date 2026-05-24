# Usage Guide

Complete guide to using Joplin Dev Workflow CLI tools effectively.

---

## Table of Contents

- [Quick Reference](#quick-reference)
- [Command Overview](#command-overview)
- [Detailed Usage](#detailed-usage)
  - [learn - Technical Articles](#learn---technical-articles)
  - [til - Daily Learning Log](#til---daily-learning-log)
  - [weekly - Weekly Reviews](#weekly---weekly-reviews)
- [Common Workflows](#common-workflows)
- [Tips & Tricks](#tips--tricks)
- [Best Practices](#best-practices)
- [Advanced Usage](#advanced-usage)

---

## Quick Reference

```bash
# Create learning article
echo "Content" | pbcopy
learn "Article Title"

# Add TIL entry (appends to today's note)
echo "Learning point" | pbcopy
til "Concept Name"

# Create weekly review
echo "Week summary" | pbcopy
weekly "W07 Title"

# Diagnose setup without writing
joplin-workflow-doctor

# Preview a write without creating notes or tags
learn --dry-run "Article Title"
til --dry-run "Concept Name"
weekly --dry-run "W07 Title"
```

---

## Command Overview

| Command | Purpose | Notebook | Behavior |
|---------|---------|----------|----------|
| `learn "Title"` | Technical article drafts | Blog Posts | Creates new note |
| `til "Concept"` | Daily learning entries | Daily Notes | Appends to today's note |
| `weekly "Title"` | Weekly reviews | Weekly Reviews | Creates new note |
| `joplin-workflow-doctor` | Data API and setup checks | Configured targets | No writes by default |

**Common Options**:
- All commands read from clipboard (`pbpaste`)
- All commands write through Joplin Desktop Data API
- `--dry-run` validates clipboard, Data API reachability, and target resolution without note/tag/folder writes
- `AUTO_SYNC=true` shows a Joplin Desktop sync reminder; cloud sync itself is handled by Joplin Desktop
- All commands add metadata and templates

## Setup and Preflight

Use the doctor before the first real write or when behavior changes:

```bash
joplin-workflow-doctor
```

Default doctor mode checks `curl`, `jq`, the clipboard command, token presence, explicit base URL or localhost port probing, `/ping`, an authenticated Data API request, and the configured daily/post/weekly notebooks.

Choose notebook setup explicitly:

```bash
# Use existing notebooks and persist resolved folder IDs. No folders are created.
joplin-workflow-doctor --setup-existing

# Create empty default notebooks and persist IDs. Refuses duplicate titles.
joplin-workflow-doctor --setup-create-defaults
```

Folder IDs are preferred. Title fallback is useful for simple setups, but if the same notebook title appears more than once, the command fails and prints matching hierarchy paths so you can set the correct `NOTEBOOK_*_ID`.

---

## Detailed Usage

### `learn` - Technical Articles

Create technical article drafts in the "Blog Posts" notebook.

#### Syntax

```bash
learn [--dry-run] "Article Title"
```

#### What It Does

1. Reads content from clipboard
2. Resolves "Blog Posts" to a Joplin folder ID
3. Creates note through Joplin Desktop Data API
4. Adds metadata (date, tags)
5. Includes draft checklist template
6. Reminds you that Desktop handles cloud sync

#### Generated Note Structure

```markdown
# Article Title

> 📅 Created: 2026-02-16 14:30
> 🏷️ Tags: #article #draft

***

[Your clipboard content here]

***

## TODO
- [ ] Add implementation examples
- [ ] Add resource links
- [ ] Proofread and format
```

#### Usage Examples

**Example 1: Capture Copilot Chat Response**

```bash
# In VS Code:
# 1. Ask Copilot about React Hooks
# 2. Review and copy the response (Cmd+C)
# 3. In terminal:

learn "React Hooks: useState and useEffect Deep Dive"

# Output:
# ✅ Learning note created!
# 📝 Title: React Hooks: useState and useEffect Deep Dive
# 📁 Notebook: Blog Posts
# 🔗 ID: a1b2c3d4e5f6...
# ⏳ Syncing...
# ✅ Sync complete!
```

**Example 2: From Text File**

```bash
# Prepare content
cat my-notes.md | pbcopy

# Create article
learn "Understanding JavaScript Closures"
```

**Example 5: Dry Run**

```bash
cat my-notes.md | pbcopy
learn --dry-run "Understanding JavaScript Closures"

# Reports the resolved Blog Posts notebook ID and intended note title.
# Does not create notes or tags.
```

**Example 3: Multi-line Content**

```bash
# Copy formatted content
pbcopy << 'EOF'
## Key Concepts

1. **Lexical Scope**: Functions remember their creation environment
2. **Closure Chain**: Nested functions can access outer variables
3. **Memory**: Closures keep variables alive

## Example
```javascript
function outer() {
  const name = 'closure';
  return function inner() {
    console.log(name); // Accesses outer variable
  }
}
```
EOF

learn "JavaScript Closures Explained"
```

**Example 4: From Perplexity AI**

```bash
# In browser:
# 1. Ask Perplexity: "Explain TDD best practices"
# 2. Copy the response
# 3. Run:

learn "TDD Best Practices Guide"
```

#### When to Use `learn`

- ✅ Writing technical blog posts
- ✅ Documenting project architecture
- ✅ Saving AI-generated explanations
- ✅ Creating tutorial drafts
- ✅ Knowledge base articles

---

### `til` - Daily Learning Log

Append Today I Learned entries to a daily note in "Daily Notes" notebook.

#### Syntax

```bash
til [--dry-run] ["Concept Name"]
```

#### What It Does

1. Reads content from clipboard
2. Checks if today's note exists
   - **If exists**: Appends new entry at the end
   - **If not exists**: Creates new daily note
   - **If duplicates exist in the daily folder**: Fails before writing
3. Adds timestamp for each entry
4. Writes through Joplin Desktop Data API and shows Desktop sync status guidance

#### Generated Note Structure

**First TIL of the day** (creates new note):

```markdown
# 2026-02-16 Daily Notes

> 🗓️ Date: 2026-02-16
> 🏷️ Tags: #til #daily

## [14:30] JavaScript Closures

[Your clipboard content]
```

**Subsequent TILs** (appends to existing note):

```markdown
# 2026-02-16 Daily Notes

> 🗓️ Date: 2026-02-16
> 🏷️ Tags: #til #daily

## [14:30] JavaScript Closures

[First TIL content]

## [16:45] Array.reduce() Usage

[Second TIL content]

## [19:20] Git Rebase vs Merge

[Third TIL content]
```

#### Usage Examples

**Example 1: Quick Learning Note**

```bash
echo "Promise.all() fails fast if any promise rejects" | pbcopy
til "Promise.all() Behavior"

# Output:
# 📌 Found today's note, appending...
# ✅ TIL appended!
# 📝 Concept: Promise.all() Behavior
# ⏰ Time: 14:30
```

**Example 2: Multiple Learnings Throughout Day**

```bash
# Morning (creates note)
echo "useCallback prevents unnecessary re-renders" | pbcopy
til "React useCallback Hook"
# Output: ✅ Today's note created!

# Afternoon (appends)
echo "Array.reduce can replace map + filter" | pbcopy
til "Array.reduce() Power"
# Output: 📌 Found today's note, appending...

# Evening (appends again)
echo "CSS Grid 'fr' unit divides available space" | pbcopy
til "CSS Grid fr Unit"
# Output: 📌 Found today's note, appending...
```

**Example 5: Dry Run**

```bash
echo "Promise.all() fails fast if any promise rejects" | pbcopy
til --dry-run "Promise.all() Behavior"

# Reports whether it would append to today's note or create it.
# Does not update notes or create tags.
```

**Example 3: Documenting Debugging Solution**

```bash
pbcopy << 'EOF'
Fixed memory leak in useEffect:
- Problem: Event listener not cleaned up
- Solution: Return cleanup function
- Learning: Always cleanup side effects
EOF

til "useEffect Cleanup Pattern"
```

**Example 4: Code Snippet Learning**

```bash
pbcopy << 'EOF'
```javascript
// Debounce pattern
function debounce(fn, delay) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}
```

Prevents function from firing too frequently.
EOF

til "Debounce Implementation"
```

#### When to Use `til`

- ✅ Quick learning points during coding
- ✅ Bug fixes and solutions
- ✅ New syntax or API discoveries
- ✅ Bootcamp daily lessons
- ✅ Code review learnings
- ✅ Debugging insights

#### TIL Best Practices

1. **Keep it atomic**: One concept per TIL entry
2. **Add context**: Why it matters, when to use
3. **Include examples**: Code snippets help memory
4. **Review weekly**: Use TILs to write weekly reviews

---

### `weekly` - Weekly Reviews

Create structured weekly review notes in "Weekly Reviews" notebook.

#### Syntax

```bash
weekly [--dry-run] "Week Title"
```

#### What It Does

1. Reads summary from clipboard
2. Creates note in "Weekly Reviews" notebook
3. Calculates week date range (Monday-Sunday)
4. Includes statistics template
5. Writes through Joplin Desktop Data API and shows Desktop sync status guidance

#### Generated Note Structure

```markdown
# W07 Frontend Learning Summary

> 📅 Week: 2026-02-10 ~ 2026-02-16
> 📝 Created: 2026-02-16
> 🏷️ Tags: #weekly #review

***

[Your clipboard content - weekly summary]

***

## Weekly Stats
- ⏱️ **Learning Hours**: ___ hours
- 📚 **Completed Courses**: ___
- 💻 **Projects**: ___

## Next Week Plan
- [ ] Planned item 1
- [ ] Planned item 2

## Reflection & Improvements
_(To be filled)_
```

#### Usage Examples

**Example 1: Bootcamp Weekly Summary**

```bash
pbcopy << 'EOF'
## This Week's Focus
Completed TDD fundamentals and JavaScript array methods module.

## Key Achievements
- Mastered Vitest testing framework
- Built CLI tool with pure functions
- Learned reduce(), map(), filter() patterns

## Challenges
- Understanding test doubles (mocks vs stubs)
- Debugging async test timing issues

## Highlights
- Paired with mentor on refactoring project
- Contributed to open source (first PR merged!)
EOF

weekly "W07 TDD & Array Methods Mastery"
```

**Example 2: Self-Directed Learning**

```bash
pbcopy << 'EOF'
## Learning Theme: React Performance

### Completed
- React DevTools Profiler tutorial
- useMemo and useCallback deep dive
- Code splitting with lazy() and Suspense

### Projects
- Optimized blog app (reduced bundle by 40%)
- Created performance testing suite

### Resources
- [React docs on performance](https://react.dev/learn)
- Kent C. Dodds performance course
EOF

weekly "W08 React Performance Optimization"
```

**Example 3: Project-Based Week**

```bash
pbcopy << 'EOF'
## Project: Personal Portfolio Site

### Work Completed
- Designed component architecture
- Implemented responsive navigation
- Set up CI/CD with GitHub Actions
- Added dark mode toggle

### Technical Stack
- React 18, TypeScript
- Tailwind CSS
- Vite, Vitest
- Deployed on Vercel

### Learnings
- CSS Grid for complex layouts
- Accessibility best practices (ARIA labels)
- Performance budget with Lighthouse
EOF

weekly "W09 Portfolio Project Sprint"
```

**Example 4: Using Copilot for Summary**

```bash
# In VS Code:
# Ask Copilot: "Summarize my learning this week based on git commits and notes"
# Copy response

weekly "W10 Full-Stack Development Progress"
```

**Example 5: Dry Run**

```bash
pbcopy < weekly-summary.md
weekly --dry-run "W10 Full-Stack Development Progress"

# Reports the computed week range and resolved Weekly Reviews notebook ID.
# Does not create notes or tags.
```

#### When to Use `weekly`

- ✅ Every Friday/Sunday end of week
- ✅ Bootcamp week completion
- ✅ Project milestone reviews
- ✅ Learning sprint retrospectives
- ✅ Job application portfolio updates

#### Weekly Review Best Practices

1. **Consistent schedule**: Same day/time each week
2. **Review TIL notes**: Scan daily notes for patterns
3. **Quantify progress**: Track hours, projects, concepts
4. **Plan ahead**: Set specific goals for next week
5. **Celebrate wins**: Acknowledge achievements

---

## Common Workflows

### Workflow 1: Daily Learning Cycle

**Morning - Start of Day**
```bash
# Review yesterday's TIL
joplin use "Daily Notes"
joplin ls -l -n 1
joplin cat <yesterday-note-id>
```

**Throughout Day - Capture Learnings**
```bash
# As you learn, immediately capture
echo "New concept" | pbcopy
til "Concept Name"
```

**Evening - Review & Reflect**
```bash
# Check today's accumulated TILs
joplin use "Daily Notes"
joplin cat <today-note-id>
```

---

### Workflow 2: Article Writing Process

**Step 1: Research & Capture**
```bash
# Capture Copilot/Perplexity insights
learn "Initial Research: Topic Name"
```

**Step 2: Edit in Joplin Desktop/VS Code**
- Open note visually
- Expand with your own insights
- Add code examples

**Step 3: Review & Publish**
- Export to blog platform
- Keep Joplin note as archive

---

### Workflow 3: Weekly Review Ritual

**Friday/Sunday - Prepare Summary**

```bash
# 1. Review this week's daily notes
joplin use "Daily Notes"
joplin ls -l | grep "$(date +%Y-%m)"

# 2. Skim through each day
joplin cat <note-id>

# 3. Draft summary (use Copilot to help)
# Ask: "Summarize these learning notes into weekly review"

# 4. Create weekly note
pbcopy < summary.txt
weekly "W07 Summary Title"

# 5. Fill in stats manually in Joplin
```

---

### Workflow 4: Bootcamp Daily Routine

**After Each Lesson**
```bash
# Copy lesson notes or key points
til "Today's Lesson Topic"
```

**After Coding Session**
```bash
# Document bugs fixed or patterns learned
echo "Solution to problem X" | pbcopy
til "Problem Solving: X"
```

**Project Milestone**
```bash
# Write up project learnings
learn "Project X: Architecture & Learnings"
```

---

## Tips & Tricks

### Clipboard Management

**Copy from File**
```bash
cat notes.md | pbcopy
learn "Title"
```

**Copy Multiple Sources**
```bash
# Combine multiple files
cat intro.md body.md conclusion.md | pbcopy
learn "Complete Guide"
```

**Copy Command Output**
```bash
git log --oneline -10 | pbcopy
til "Git Workflow This Week"
```

---

### Keyboard Shortcuts

**macOS**
- `Cmd+C` - Copy selected text
- `Cmd+A` then `Cmd+C` - Copy all in window

**VS Code with Copilot**
- Copy Copilot response → Switch to terminal → Run command
- Use split terminal for quick workflow

---

### Batch Operations

**Create Multiple TILs**
```bash
# Morning batch
til "Concept 1"
til "Concept 2"
til "Concept 3"
# All append to same daily note
```

**Backup Before Experimenting**
Use Joplin Desktop export before large manual reorganizations.

---

### Search & Review

**Find Recent Notes**
Use Joplin Desktop search or the VS Code Joplin extension to review recent notes in the target notebooks.

**Full-Text Search**
Use Joplin Desktop full-text search. The workflow commands write notes locally; search and editing remain in Joplin Desktop or your editor extension.

---

## Best Practices

### Content Capture

✅ **Do**:
- Review AI responses before saving
- Add your own context and examples
- Keep clipboard content focused
- Save immediately after generating content

❌ **Don't**:
- Save raw AI output without review
- Mix multiple unrelated topics in one note
- Forget to capture sources/references

---

### Note Organization

✅ **Do**:
- Use consistent naming conventions
- Add relevant tags
- Review and refactor notes periodically
- Link related notes (in Joplin Desktop)

❌ **Don't**:
- Create duplicate notes
- Use vague titles like "Notes 1"
- Accumulate unprocessed drafts

---

### Daily Habits

**Start of Day**
1. ✅ Review yesterday's TIL
2. ✅ Check weekly goals progress
3. ✅ Plan today's learning focus

**During Work**
1. ✅ Capture learnings immediately
2. ✅ Use TIL for quick notes
3. ✅ Use learn for detailed articles

**End of Day**
1. ✅ Review today's TIL entries
2. ✅ Fill in any missing context
3. ✅ Preview tomorrow's goals

**End of Week**
1. ✅ Create weekly review
2. ✅ Plan next week's learning
3. ✅ Archive completed projects

---

## Advanced Usage

### Integration with Git

**Document Commits**
```bash
# Capture this week's commits as learning log
git log --since="1 week ago" --pretty=format:"%h - %s" | pbcopy
til "This Week's Code Changes"
```

---

### Custom Templates

Edit `~/.config/joplin-workflow/config` for custom templates:

```bash
# Example: Add custom tags
TEMPLATE_TAGS_LEARN="#article #draft #javascript #frontend"
TEMPLATE_TAGS_TIL="#til #daily #bootcamp"
```

See [Customization Guide](customization.md) for details.

---

### Automation Ideas

**Scheduled Weekly Reminder** (macOS)
```bash
# Add to crontab
# Every Friday at 5 PM
0 17 * * 5 osascript -e 'display notification "Time for weekly review!" with title "Joplin Workflow"'
```

---

## Testing Environment

**Tested Configuration**:
- **OS**: macOS 26.2 (Tahoe)
- **Shell**: zsh 5.9
- **Joplin Desktop**: Web Clipper/Data API enabled
- **jq**: 1.7

---

## Next Steps

- ⚙️ [Customize your configuration](customization.md)
- 🔄 [Learn workflow best practices](workflows.md)
- 🐛 [Troubleshoot issues](troubleshooting.md)

---

## Getting Help

- 📖 [Installation Guide](installation.md) - Setup instructions
- 🔧 [Customization Guide](customization.md) - Configuration options
- 💬 [GitHub Discussions](https://github.com/gcake119/joplin-dev-workflow/discussions)
