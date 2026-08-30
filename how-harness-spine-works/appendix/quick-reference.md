# Quick reference

> This appendix is for lookup, **not** the reading path. Read the chapters first.

## Chapter wrap-ups (distilled)

| Ch | One-line wrap-up |
|----|------------------|
| 01 | An echo turn is already a protocol: log, view, guest, driver — not a vendor loop. |
| 02 | Host is the only world door; tools and LLM adapters borrow it, they do not open their own. |
| 03 | Memory is a frozen event ledger; `derive-messages` is a clerk's transcript, not the notebook. |
| 04 | A tool is a four-stage public act; only `tools-execute`'s inner (or host) may have side effects. |
| 05 | Approval is one-shot, fail-closed, and writes both asked and decided; no grant store, no UI. |
| 06 | The model is a guest that returns text or tool-call data; enqueue sits in front of echo/script/http. |
| 07 | The loop rereads the log every step; resume does not invent a user row; pre-step may whisper. |
| 08 | Acting rooms are isolated; the front desk (session/llm/host) is shared; siblings do not hear each other. |
| 09 | Cancel is a checkpoint flag plus a cancelled log row; idle cancel must not stick; dispose refuses. |
| 10 | YAML and profiles name the same plugins; reload swaps the guest and refreshes handles; the log stays. |

## Lived analogies (core chapters)

| Ch | Analogy |
|----|---------|
| 03 | Bound notebook vs chat bubble; photocopy on append; clerk reads aloud. |
| 04 | Airport lane: documents, engines, customs, loudspeaker. |
| 07 | Clerk who rereads the notebook every morning; no second drawer copy. |
| 08 | Hotel: shared front desk, private minibar and phone, parent suite can hear. |
| 09 | Raising a hand at a checkpoint, then writing "cancelled" so the next guest is not haunted. |

## Source map

```
../host/api.reb           # ch02
../session/api.reb        # ch03, ch07
../session/json.reb       # ch03
../session/store.reb      # ch03
../tools/api.reb          # ch04, ch05
../shell/api.reb          # ch04
../approval/api.reb       # ch05
../llm/api.reb            # ch06
../llm/http.reb           # ch06
../agent-loop/api.reb     # ch01, ch07, ch09
../scope/api.reb          # ch08
../agent/api.reb          # ch08, ch09
../boot.reb               # ch01, ch10
../boot-yaml.reb          # ch10
../profile.reb            # ch10
../cordis.yml             # ch10
```

## Cordis kernel (not this book)

| Role in the spine | Kernel verb |
|-------------------|-------------|
| Plugin mount | `registry/plugin` |
| Tools/approval/loop intercept | `events/waterfall` |
| Per-agent tools/shell/loop | `extend` isolate-map |
| Delay / stream wait | thenable + scheduler |
| Hot swap | `reload-plugin` (loader) |

See [How the Cordis Rebol Port Works](../../../cordis-port/how-cordis-port-works/README.md).
