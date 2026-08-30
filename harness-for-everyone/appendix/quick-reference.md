# Quick Reference

> This appendix is for lookup, not the first reading path.

## One-line chapter models

| Ch | One-line model |
|----|----------------|
| 01 | The spine is separate rooms for talking, acting, remembering, and stopping. |
| 02 | `host` is the only door to the real world; the loop does not spawn processes. |
| 03 | The log is the memory; `derive-messages` is only a view. |
| 04 | A tool is allowed, performed, and recorded as three moments. |
| 05 | Approval is a one-shot public question that fails closed. |
| 06 | `llm` is a guest that answers; it does not write history or run bash. |
| 07 | A turn rereads the log every step; there is no private chat cache. |
| 08 | Each agent gets a private workshop; session and voice stay shared. |
| 09 | Cancel is a protocol with checkpoints and a record, not a power switch. |
| 10 | Assembly and reload change the machine without rewriting the conversation. |

## Cast of Concepts

| Name | Plain-English role |
|------|--------------------|
| `host` | The single door to shell, HTTP, and delay |
| `session` | The append-only log of what happened |
| `derive-messages` | The read-only conversation painted on that log |
| `tools` | The witnessed pre / execute / post call |
| `approval` | The one-shot permission seam |
| `llm` | The guest that returns text or a tool call |
| `agent-loop` | One turn: write, reread, ask, perhaps act, ask again |
| `scope` | The opaque key that says which room an event belongs to |
| `agent` | The live registry of those rooms |
| `boot-spine` | Code-shaped assembly of the shared world plus a default agent |
| `boot-spine-from-config` | File-shaped assembly from YAML or profile layers |
| reload | Supervised plugin swap that may still roll back |

## If You Only Read Three Chapters

| Need | Read |
|------|------|
| Understand the big promise | 01, 03, 09 |
| Understand acting and permission | 02, 04, 05 |
| Understand why the model is not the agent | 06, 07, 08 |

## If You Prefer Human Questions

| Ask this | Read |
|----------|------|
| Why isn't this just a chatbot? | 01, 06, 07 |
| Why so many layers around a shell command? | 02, 04, 05 |
| Why can't it just keep an array of messages? | 03, 07 |
| Why isolate some services and share others? | 08 |
| Why is cancel so ceremonious? | 09 |
| Why YAML, profiles, and reload? | 10 |

## Source map

```text
ARCHITECTURE.md              -> ch01
boot.reb                     -> ch01, ch09, ch10
host/api.reb                 -> ch02
shell/api.reb                -> ch02
session/api.reb              -> ch03
session/json.reb             -> ch03
tools/api.reb                -> ch04, ch05
approval/api.reb             -> ch05
llm/api.reb                  -> ch06
agent-loop/api.reb           -> ch06, ch07, ch09
scope/api.reb                -> ch08
agent/api.reb                -> ch09
boot-yaml.reb                -> ch10
cordis.yml                   -> ch10
profile.reb                  -> ch10
examples/reload-llm.reb      -> ch10
```
