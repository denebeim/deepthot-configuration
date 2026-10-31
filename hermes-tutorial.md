# Tutorial: Using the hermes.local.deepthot.org Agent

> A practical guide to the Hermes Agent instance running on the deepthot network
> **VM 314 · 192.168.42.132 · hermes.local.deepthot.org · Ubuntu 24.04 · 8 cores / 16 GB RAM**

---

## 0. What Is This?

`hermes.local.deepthot.org` is a Nous Research **Hermes Agent** instance provisioned on a Proxmox VM (VMID 314) hosted by `heartogold` (192.168.42.3). It's an open-source AI coding/agent framework — like Claude Code, Codex, or OpenHands — with persistent memory, agent-created skills, Docker integration, and a multi-platform messaging gateway.

The VM was provisioned by `hermes.yaml` (Ansible) with these key characteristics:

| Property | Value |
|---|---|
| **Hostname** | hermes.local.deepthot.org |
| **IP** | 192.168.42.132 (on the deepthot LAN) |
| **VM specs** | 8 cores, 16 GB RAM, 40 GB disk |
| **OS** | Ubuntu 24.04 LTS (jammy) |
| **Primary user** | `ansible` |
| **Auth** | FreeIPA / IPA client joined to `local.deepthot.org` |
| **Docker** | `ansible` user is in the `docker` group |
| **Install method** | Official installer: `scripts/install.sh --non-interactive` |

### Installed Hermes paths

```
/home/ansible/.local/bin/hermes             ← launcher binary
/home/ansible/.local/share/hermes-agent      ← install directory (git checkout)
/home/ansible/.hermes/                      ← Hermes home (config + state)
  ├── config.yaml                           ← settings (Ansible-managed)
  ├── .env                                  ← API keys (Ansible-managed, chmod 600)
  ├── skills/                               ← installed + auto-created skills
  ├── memory/                               ← persistent memory store
  ├── state.db                              ← SQLite session store
  ├── sessions/                             ← session transcripts
  ├── logs/                                 ← gateway + error logs
  └── auth.json                             ← OAuth tokens / credential pools
```

### Default configuration (`config.yaml`)

```yaml
model:
  default: "anthropic/claude-opus-4.6"
  provider: auto                    # rotates across configured API keys

terminal:
  backend: local

gateway:
  trust_env: true
  signal_interrupt_grace_timeout: 1

tool_loop_guardrails:
  max_iterations: 50

memory:
  enabled: true

skills:
  auto_create: true
```

**API keys** are loaded from `.env` (Ansible vault-encrypted in the playbook). Providers configured: **OpenRouter** (primary) and **Anthropic** (fallback). The `auto` provider profile rotates across pooled credentials automatically.

---

## 1. Connecting to the VM

### SSH (from the deepthot LAN)

```bash
ssh ansible@192.168.42.132
# or, if your DNS resolves it:
ssh ansible@hermes.local.deepthot.org
```

If you're on a **WireGuard** tunnel (`deepthot` interface), the VM is reachable directly. See `deployments/wg-easy/` in the ansible repo for WireGuard setup.

### Confirm the install

```bash
hermes --version
# Hermes Agent v0.22.5 (2026.9.24) · stable

hermes status
# Shows: model, provider, gateway status, platforms, jobs

hermes doctor
# Checks dependencies, config integrity, and API key health
```

### PATH setup (already done by Ansible)

The Ansible playbook adds `/home/ansible/.local/bin` to both `/etc/profile.d/hermes.sh` and `~/.bashrc`, so `hermes` is on PATH for all new shells. No manual PATH edit needed.

---

## 2. Starting Your First Chat

### Interactive chat (default)

```bash
hermes
# or: hermes chat
```

This launches the classic REPL. For the modern Ink TUI (mouse-friendly, rich overlays):

```bash
hermes --tui
```

### One-shot query (no interactive session)

```bash
hermes chat -q "Explain the difference between WAL and DELETE journal mode in SQLite"

# Quiet mode (just the answer, no banner/tool previews):
hermes chat -q -Q "Summarize the key chapters of Domain-Driven Design"

# Attach an image:
hermes chat -q --image /path/to/chart.png "What does this chart show?"

# Override the model for this invocation:
hermes chat -q -m "anthropic/claude-sonnet-4.6" "Rewrite this in haiku form: ..."

# Use a different provider:
hermes chat -q -m "google/gemini-2.5-flash" --provider gemini "Hello"
```

### Quick setup check

```bash
hermes doctor          # health check of deps + config + API keys
hermes model            # interactive model/provider picker
hermes setup            # full setup wizard (model, TTS, terminal, gateway, tools, agent)
```

---

## 3. Sessions

Hermes persists every conversation. You never lose context.

```bash
# Resume most recent session (from the CLI you're already in):
hermes --continue

# Resume by session ID or title:
hermes --resume 20260225_143052_a1b2c3
hermes --resume "My API Design Notes"

# List sessions:
hermes sessions list
hermes sessions browse    # interactive browser (fzf-style)

# Rename a session:
hermes sessions rename <ID> "New Title"

# Export a session transcript:
hermes sessions export /tmp/my-session.json

# Prune old sessions (keep last N):
hermes sessions prune

# Session statistics:
hermes sessions stats
```

**In-chat:** `/sessions` (browse + resume), `/new` (fresh session), `/clear` (clear screen + new session), `/title <name>` (name the current session).

---

## 4. Models & Providers

### Changing the default model

```bash
hermes model              # interactive picker (~250+ models across 35+ providers)
hermes config set model.default "anthropic/claude-sonnet-4.6"
```

**Built-in aliases** (resolve against the active provider): `/model opus`, `/model sonnet`, `/model haiku`, `/model gpt5`, `/model gemini`, `/model grok`, `/model deepseek`, `/model llama`, `/model qwen`, etc.

### User-defined model aliases

Edit `config.yaml` (use the safe config command, not hand-editing):

```bash
hermes config set model.aliases.fav "openrouter/anthropic/claude-sonnet-4.6"
hermes config set model.aliases.local-qwen.model "qwen3.5:397b"
hermes config set model.aliases.local-qwen.provider "custom"
hermes config set model.aliases.local-qwen.base_url "https://ollama.com/v1"
```

Then in chat: `/model fav` or `/model local-qwen`.

### Fallback provider chain

If the primary model fails, Hermes automatically tries fallback providers:

```bash
hermes fallback add anthropic          # add Anthropic as a fallback
hermes fallback list                   # show the chain
hermes fallback remove openai          # remove one
```

### Credential pools

```bash
hermes auth                         # interactive credential manager
hermes auth add openrouter          # add an OpenRouter key to the pool
hermes auth list                    # list all stored credentials
hermes auth status                  # health check
```

Multiple keys per provider form a **pool that rotates automatically**, skipping exhausted ones.

### Local models

The VM has Docker and 16 GB RAM — enough to run smaller local models. See `references/providers-and-models.md` for setup. You can configure `ollama`, `lmstudio`, or `vllm` as a custom provider via `hermes setup`.

---

## 5. Skills

Skills are reusable procedures that Hermes saves from conversations and loads into future sessions. On this VM, **auto-creation is enabled** in config.

### Browsing & managing skills

```bash
# List installed skills (categorized):
hermes skills list
hermes skills browse                 # interactive browser

# Search the skills hub:
hermes skills search "git"
hermes skills search "terraform"

# Inspect a skill before installing:
hermes skills inspect autonomous-ai-agents/hermes-agent

# Install a skill by hub ID or direct URL:
hermes skills install autonomous-ai-agents/hermes-agent
hermes skills install https://github.com/org/.hermes-skills/foo/SKILL.md

# Enable/disable a skill per profile:
hermes skills config

# Check for updates / uninstall:
hermes skills check
hermes skills update
hermes skills uninstall <id>

# Create a skill from a directory or URL:
hermes skills publish /path/to/dir

# Add a GitHub repo as a skill source:
hermes skills tap add https://github.com/org/repo
```

### Skill bundles

```bash
hermes bundles                         # list bundles (/<name> loads several skills)
hermes chat -q "/security + /coding"   # load the 'security' and 'coding' bundles
```

### Prestige: turn a conversation into a reusable skill

```bash
# In chat, at the end of a successful task:
/learn this session as a reusable skill
# or: /learn this folder
# or: /learn https://example.com/some-guide
```

### The Curator

The Curator background-maintains agent-created skills (tracks usage, archives stale ones, makes backups).

```bash
hermes curator status                  # overview
hermes curator usage                   # per-skill usage tracking
hermes curator run                     # run a maintenance sweep now
hermes curator archive <id>            # archive (never delete)
hermes curator pin <id>                # exempt from auto-archive
hermes curator list-archived           # list archived skills
hermes curator restore <id>            # restore an archived skill
hermes curator prune                   # remove empty archives (backups retained)
hermes curator backup <id>             # create a tar.gz backup snapshot
```

In-chat: `/curator` mirrors the CLI.

---

## 6. Memory

Memory persists across sessions, models, and platforms. On this VM it's enabled.

### How it works

- **`MEMORY.md`** (or `~/.hermes/memory/`): facts Hermes learns about you — preferences, environment details, standing conventions. Auto-written across sessions.
- **`USER.md`**: your profile — who you are, your role, your working style. Written once, consulted always.
- **Session search**: `/session_search` finds anything from past conversations.

### Managing memory

```bash
hermes memory setup                    # configure memory provider (local DB by default)
hermes memory status                   # check if enabled + which provider
hermes memory reset                    # wipe all memory (destructive!)

# In chat:
/memory pending                        # review pending memory writes
/memory approve                        # approve all pending
/memory reject                         # reject all pending
```

### Reviewing your profile

```bash
hermes status --full                   # shows memory + profile + everything
```

---

## 7. Tools & Toolsets

Hermes has fine-grained toolsets you can enable/disable per session.

### List & toggle toolsets

```bash
hermes tools                           # interactive curses UI
hermes tools list                      # list all
hermes tools enable web                # enable the web toolset
hermes tools disable browser           # disable browser automation
```

### Available toolsets (key ones)

| Toolset | What it provides |
|---|---|
| `terminal` | Shell commands and process management (SSH to the VM from here) |
| `file` | File read/write/search/patch |
| `web` / `search` | Web search + extraction |
| `browser` | Browser automation (headless Chromium) |
| `code_execution` | Sandboxed Python execution |
| `coding` | Code-editing helpers (LSP-backed, linting) |
| `vision` | Image analysis |
| `image_gen` | Image generation (DALL-E, etc.) |
| `skills` | Skill browsing and management |
| `memory` | Persistent cross-session memory |
| `session_search` | Search past conversations |
| `delegation` | Subagent task delegation |
| `cronjob` | Scheduled task management |
| `clarify` | Ask clarifying questions |
| `todo` | In-session task planning |
| `kanban` | Multi-agent work-queue tools |

### Tool changes

Tool toggling takes effect on **`/reset`** (a new session) — never mid-conversation, to preserve prompt caching.

### Security: command approval

By default (`approvals.mode: smart`), Hermes asks an auxiliary LLM to assess shell commands flagged as destructive (`rm -rf`, `git reset --hard`, etc.).

```bash
# In config:
hermes config set approvals.mode smart    # recommended (default)
hermes config set approvals.mode manual   # always prompt
hermes config set approvals.mode off      # skip all prompts (equivalent to --yolo)

# Per-invocation bypass:
hermes --yolo chat -q "destructive command here"

# Reset the "Always allow" state:
hermes config set command_allowlist '[]'
rm -f ~/.hermes/shell-hooks-allowlist.json

# Secret redaction (on by default):
hermes config set security.redact_secrets true     # keep enabled globally
# NOTE: requires restart to take effect
```

---

## 8. Slach Commands (In-Session)

Hermes supports slash commands for everything. The full registry is live — **`/help`** in chat is always authoritative.

### Session management

```
/new  [name]       Fresh session
/clear             Clear screen + new session (CLI)
/retry             Resend last message
/undo [N]          Back up N turns and re-prompt
/title [name]      Name the current session
/compress          Compress context (saves tokens)
/stop              Kill background processes
/sessions          Browse and resume previous sessions
/resume [name]     Resume a named session
/branch [name]     Branch the session
/handoff <platform> Hand a live session off to a messaging platform
/status            Session, model, token, and context info
```

### Configuration

```
/config              Show config (CLI)
/model [name]        Switch model (session-scoped; --global to persist)
/personality [name]  Set a personality
/reasoning [level]   Reasoning effort: none|low|high|max|ultra
/fast                Priority/fast processing tier
/verbose             Cycle tool progress display
/voice [on|off|tts]  Voice mode (STT/TTS)
/yolo                Toggle approval bypass
/skin [name]         Change theme
/pet [toggle|list]   Pet mascot control
```

### Tools & Skills

```
/tools [list|enable|disable]   Manage tools
/toolsets                     List toolsets
/skills                       Search/install/manage skills
/bundles                      List skill bundles
/learn <source>               Turn a conversation/folder/URL into a reusable skill
/memory                       Review pending memory writes
/cron                         Manage scheduled tasks
/suggestions                   Review suggested automations
/blueprint [name]             Set up an automation from a blueprint
/curator                      Skill lifecycle management
/moa <prompt>                 Run through the Mixture-of-Agents preset
/reload                       Reload .env into the running session
/reload-mcp                   Reload MCP servers
/reload-skills                Re-scan skills directory
/browser [connect|status]     CDP connection to live browser
/plugins                      List plugins
```

### Info & diagnostics

```
/help                Show all commands
/usage [reset]       Token usage and rate limits
/insights [days]     Usage analytics
/whoami              Your access level (admin/user)
/profile             Active profile info
/journey             Learned skills + memories timeline
/subscription        Nous plan info
/version             Show version
/debug               Upload debug report
```

### Exit

```
/quit  (/exit) [--delete]   Exit CLI; --delete also removes session history
```

---

## 9. MCP Servers

MCP (Model Context Protocol) servers extend Hermes with custom tools.

```bash
# Add an MCP server:
hermes mcp add filesystem --command "npx" --arg "@modelcontextprotocol/server-filesystem" --arg "/home/ansible"

# Or from the URL form:
hermes mcp add github --url "https://github.com/modelcontextprotocol/servers"

# Manage:
hermes mcp list
hermes mcp remove <name>
hermes mcp test <name>
hermes mcp configure <name>         # toggle tool selection

# Curated catalog:
hermes mcp catalog
hermes mcp install <name>

# Reload after changes:
hermes mcp-serve                      # run Hermes as an MCP server
# or in chat: /reload-mcp
```

**Full MCP details**: see `references/native-mcp.md`.

---

## 10. The Messaging Gateway (Optional)

By default on this VM, the **gateway is disabled** (`hermes_gateway_enabled: false` in the Ansible defaults). The gateway is what connects Hermes to Telegram, Discord, Slack, WhatsApp, Matrix, and 15+ other platforms.

### Enabling the gateway

```bash
# Enable the systemd service:
sudo systemctl enable --now hermes-gateway

# Or via the CLI (manages the service for you):
hermes gateway start

# Check status:
hermes gateway status
systemctl status hermes-gateway
```

The gateway listens on **port 8080** (all interfaces) by default and reloads config from `.env` automatically (`/reload` in chat or SIGHUP).

### Connecting a messaging platform

```bash
hermes gateway setup                # interactive platform setup wizard
```

This walks you through connecting to Telegram (via a bot token), Discord, Slack, WhatsApp, etc. Each platform appears in the Bots tab at `hermes dashboard`.

### Bots

Bots let you turn Hermes profiles into named, role-specific assistants:

```bash
hermes setup                          # or use the Bots tab in the dashboard
```

Each bot has its own:
- Model + provider
- Memory (isolated or shared)
- Skills (custom per bot)
- Avatar / personality
- Group chats (bots can message each other)

---

## 11. Cron & Scheduled Tasks

The `cronjob` tool and `hermes cron` CLI manage durable scheduled tasks that survive process restarts.

### Creating a scheduled job

```bash
# Interactive creation:
hermes cron create "30m"              # every 30 minutes
hermes cron create "0 9 * * *"        # every day at 9 AM
hermes cron create "every monday 9am" # cron-like or natural language

# The cron wizard prompts for: prompt, model, skills, script, workdir, delivery
```

### Managing jobs

```bash
hermes cron list                     # list all scheduled jobs
hermes cron edit <id>                # modify a job
hermes cron pause <id>               # pause a job
hermes cron resume <id>              # resume a job
hermes cron run <id>                 # run now (manual trigger)
hermes cron remove <id>              # delete a job
hermes cron status                   # show job status
```

### Schedule formats

```
"30m"              → every 30 minutes
"every 2h"         → every 2 hours
"0 9 * * *"        → 5-field cron (9 AM daily)
"2026-01-15T09:00:00Z" → ISO timestamp (one-time)
"every monday 9am" → natural language
```

### Job options

- `skills`: preload specific skills for the cron run
- `model`/`provider`: override the model
- `script`: pre-run data collection script
- `no_agent=True`: the script output IS the result (no LLM)
- `context_from`: chain job B's input from job A's output
- `workdir`: run in a specific directory (loads its `AGENTS.md`/`CLAUDE.md`)

**In-chat:** `/cron` mirrors the CLI.

---

## 12. Docker Integration

The `ansible` user is in the `docker` group, so Hermes can manage containers directly.

### Using Docker as a terminal backend

Edit `config.yaml`:

```bash
hermes config set terminal.backend docker
```

Now Hermes runs all terminal commands inside a Docker container instead of the host. See `references/configuration.md` for Docker backend setup.

### Docker management

With the terminal backend set to `docker`, Hermes will:
- Spin up an ephemeral container per session
- Mount your working directory
- Execute all shell commands inside the container

This provides isolation and prevents side effects on the host.

### Container images

```bash
# If using the hermes-s6 or other container images:
docker images
docker run -it --rm deepthot/hermes:latest
```

---

## 13. Profiles

Profiles let you run multiple independent Hermes instances with isolated configs, sessions, skills, and memory.

### Managing profiles

```bash
hermes profile list                    # list all profiles
hermes profile create work             # create a new profile
hermes profile create clone-of-main --clone  # clone current profile
hermes profile use work                # switch to a profile
hermes profile delete work             # delete a profile
hermes profile rename old new          # rename
hermes profile export work             # export as a .tar.gz
hermes profile import /path/to/file    # import

# When a profile is active, paths resolve to ~/.hermes/profiles/<name>/
```

### Using a profile

```bash
hermes --profile work                  # run with a specific profile
hermes -p work chat -q "task"          # one-shot with a profile
```

---

## 14. Subagents & Multi-Agent Coordination

### One-Shot (fire-and-forget)

```bash
# Quick parallel subtasks:
hermes chat -q "Research GRPO papers and write summary to ~/research/grpo.md"
hermes chat -q "Set up CI/CD for ~/myapp" --worktree
```

### Interactive PTY Mode (via tmux)

Hermes uses `prompt_toolkit`, which requires a real terminal. Use tmux for interactive spawning:

```bash
# Start a named Hermes session in tmux:
tmux new-session -d -s agent1 -x 120 -y 40 'hermes'

# Wait for startup, then send a message:
sleep 8 && tmux send-keys -t agent1 'Build a FastAPI auth service' Enter

# Read output:
tmux capture-pane -t agent1 -p

# Send follow-up:
tmux send-keys -t frontend 'Here is the API schema: ...' Enter

# Exit:
tmux send-keys -t agent1 '/exit' Enter && sleep 2 && tmux kill-session -t agent1
```

### Multi-Agent Coordination

```bash
# Agent A: backend
tmux new-session -d -s backend -x 120 -y 40 'hermes -w'
sleep 8 && tmux send-keys -t backend 'Build REST API for user management' Enter

# Agent B: frontend
tmux new-session -d -s frontend -x 120 -y 40 'hermes -w'
sleep 8 && tmux send-keys -t frontend 'Build React dashboard for user management' Enter

# Relay context between them:
tmux capture-pane -t backend -p | tail -30
tmux send-keys -t frontend 'Here is the API schema from the backend agent: ...' Enter
```

### Worktree mode

Use `-w` (`--worktree`) when spawning agents that edit code — it creates an isolated git worktree to prevent conflicts:

```bash
hermes -w chat -q "Refactor the auth module"
```

### Session resume

```bash
# Resume most recent session:
tmux new-session -d -s resumed 'hermes --continue'

# Resume specific session:
tmux new-session -d -s resumed 'hermes --resume 20260225_143052_a1b2c3'
```

---

## 15. Other Surfaces

### Web Dashboard

```bash
hermes dashboard                     # launch the web admin panel
hermes dashboard --stop              # stop it
hermes dashboard --status            # check status
```

The dashboard provides:
- Messaging channel management
- MCP server catalog
- Webhook configuration
- Memory viewer
- Profile builder
- An embedded `hermes --tui` chat

It's secured behind an OAuth/token gate.

### Desktop App

```bash
hermes desktop                       # alias: hermes gui
```

The native Electron app (macOS/Linux/Windows) provides:
- Streaming chat with tool output
- Session list
- Cmd+K palette
- Drag-and-drop file support
- Native notifications
- Per-profile remote-gateway login

Extend it with UI plugins — see `references/desktop-plugins.md`.

### OpenAI-Compatible Proxy

```bash
hermes proxy                         # local OpenAI API backed by your OAuth provider
```

Point any OpenAI-compatible client (Codex CLI, Aider, Cline, scripts) at it — no API key needed.

### ACP (IDE Integration)

```bash
hermes acp                           # run Hermes as an ACP server inside VSCodium, VS Code, Zed, JetBrains
```

The editor spawns `hermes acp` over stdio and renders chat, tool calls, file diffs, and approval prompts natively. See `references/acp.md`.

---

## 16. Project Context Files

Hermes injects project-level instructions from the working directory. The discovery order is **first match wins** — only one is loaded per session:

| File (priority order) | Scope | Use when |
|---|---|---|
| `.hermes.md` / `HERMES.md` | Walks parents up to git root | Hermes-specific hierarchical project rules |
| `AGENTS.md` / `agents.md` | Cwd only | Portable instructions (works with Codex, Claude Code, OpenHands) |
| `CLAUDE.md` / `claude.md` | Cwd only | Claude-style project rules |
| `.cursorrules` / `.cursor/rules/*.mdc` | Cwd only | Migrating from Cursor |

**`SOUL.md`** (in `$HERMES_HOME`) is independent and always loaded — it sets the agent's identity, not project rules.

**Skip for one session:**

```bash
hermes --ignore-rules        # skips all context files + SOUL.md + user config
```

---

## 17. Voice

### Speech-to-Text (STT)

Voice messages from messaging platforms are auto-transcribed. Configure in `config.yaml`:

```yaml
stt:
  enabled: true
  provider: local     # local (faster-whisper, free) | groq | openai | mistral | deepinfra | elevenlabs
```

### Text-to-Speech (TTS)

| Provider | Env var | Free? |
|---|---|---|
| Edge TTS (default) | None | Yes |
| ElevenLabs | `ELEVENLABS_API_KEY` | Free tier |
| OpenAI | `VOICE_TOOLS_OPENAI_KEY` | Paid |
| MiniMax | `MINIMAX_API_KEY` | Paid |
| Gemini | `GOOGLE_API_KEY` | Free tier |
| Piper (local) | None | Free |

```bash
# In chat:
/voice on                   # voice-to-voice mode
/voice off                  # disable voice
/voice tts                  # always use TTS for responses
```

---

## 18. Themes / Skins

Hermes uses **skins** — one YAML file that themes the CLI, TUI, and desktop GUI simultaneously.

```bash
# List available skins:
hermes skin list

# Use a skin:
hermes skin use cyberpunk
hermes config set display.skin "synthwave"    # activates for all surfaces live (~1s)

# Tweak one color of the active skin:
hermes skin set ui_tool "#00FFFF"           # e.g., make the tool-call dot cyan

# Revert:
hermes config set display.skin default
```

To author a custom skin, see `references/themes.md` and `templates/skin.yaml`.

---

## 19. Maintenance

### Updating Hermes

```bash
hermes update                    # check + update to latest stable
hermes update --set-channel main # switch to the main (every-commit) channel
```

### Backups

```bash
# Snapshot current config + state:
hermes snapshot create

# List snapshots:
hermes snapshot list

# The curator also makes tar.gz backups of skills before archiving them.
```

### Log access

```bash
hermes logs -f                  # live gateway + error logs
hermes logs errors              # errors only
# Or directly:
tail -f /home/ansible/.hermes/logs/gateway.log
```

### Emergency pause

```bash
hermes pause                    # stops cron/kanban dispatch + new gateway turns
hermes resume                   # lifts the pause
```

### Troubleshooting

```bash
hermes doctor --fix             # auto-fix common issues
hermes --safe-mode              # disable ALL customizations (isolate problems)
hermes config check             # report config sections missing from older versions
```

For deeper issues: `/debug` in chat uploads a debug report and returns shareable links.

---

## 20. Quick Reference

### Connect

```bash
ssh ansible@192.168.42.132
```

### Start chatting

```bash
hermes                              # interactive REPL
hermes --tui                        # Ink TUI
hermes chat -q "one-shot question"  # non-interactive
```

### Every 5 seconds you'll use

| Command | Purpose |
|---|---|
| `hermes` | Start interactive chat |
| `hermes chat -q "..." -m "claude-sonnet-4.6"` | One-shot with model override |
| `hermes sessions list` | Your conversation history |
| `hermes skills search "git"` | Find a skill |
| `hermes skills install <id>` | Install a skill |
| `hermes tools list` / `hermes tools enable <name>` | Manage tools |
| `hermes doctor` | Health check |
| `hermes status` | Quick overview |
| `/help` (in chat) | Every slash command |

### Every minute you'll use

```bash
hermes --continue                 # resume last session
hermes cron list                  # see scheduled tasks
hermes gateway status             # (if gateway enabled) is Telegram/Discord connected?
```

---

*Generated for the hermes.local.deepthot.org VM (heartogold / VM 314).
See also: https://hermes-agent.nousresearch.com/docs/ — the official documentation, updated on every build.*
