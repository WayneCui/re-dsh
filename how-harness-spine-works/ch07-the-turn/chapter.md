# Chapter 07 Why Does Every Step Reread the Log?

A turn, in the naive picture, is a mutable conversation object plus a while-loop. You append the user string, call the model, maybe run a tool, append again, and stop when the model talks. The live array *is* the state. That is exactly the design Chapter 03 rejected for storage, and it fails again here for control flow. If you cancel halfway, the array has a tool-call without a result. If you resume, you do not know whether to send a new user row. If a plugin wants to rewrite what the model sees, it has to mutate the same array the UI is printing.

[`agent-loop/api.reb`](../../agent-loop/api.reb) `run-turn-core` is a protocol over the log instead. It marks `live-session-id`, writes `turn-start`, claims inbox messages into `user-message` rows, optionally writes the caller's user text, then loops: `step-start`, derive, pre-step waterfall, request waterfall, `llm/stream`, then either tool-call/tool-result or assistant-message, then `step-end`. It stops on text, on `max-steps`, on reject, on cancel, or on a disposed fiber. Every model input is `sessions/derive-messages` (or a waterfall rewrite of a *copy* of that view). There is no `this.messages` field on the loop.

## The loop is a clerk, not a cache

The lab's first turn enqueues a bash `tool-call` and then a text reply. `run-turn` writes the user row, streams the tool-call (data, not execution), logs it, calls `tools/execute/meta` with a cancel-check, logs `tool-result`, steps again, streams text, logs `assistant-message`. Derived roles are `[user assistant tool assistant]` — the same projection Chapter 03 taught, now produced by a live driver. Status is `'text` after two steps. The model never heard a side channel; it will hear the tool result on the next derive.

`resume-turn` is `run-turn-core/resume`: no new user row. It is allowed when `can-admit-turn?` says the derived view already ends in `tool` or `assistant`, or when the inbox claimed a waking `followup` / `steer`. The lab first completes an echo on `"seeded"`, then enqueues `"from-resume"` and resumes. Roles become `[user assistant assistant]`. The user-row count stays 1. That is the whole resume contract: continue from history, do not pretend the human spoke again.

A log that ends on a lone `user-message` returns `status: 'no-input`. `can-admit-turn?` does not treat "there is already a user row" as a reason to call the model. `test/session-fork-test.reb` locks that edge, and covers the happy path only after a completed turn (assistant/tool tail) or with a waking inbox message.

Two waterfalls sit in front of the guest. `agent-pre-step` receives `[session-id step-n proposed-messages]` and may return a rewritten block or `kind: 'reject`. `agent-request` receives a request map with `messages`, `tools`, and `llm`, and may swap the provider. The lab's pre-step listener prefixes user content with `"[prefix] "`. The echo adapter then replies with that prefixed string — so the *assistant* in the log shows the prefix — while `derive-messages` for the original user row stays `"hello from pre-step"`. The clerk can lie to the guest. The notebook does not get a forged human line. (The listener mutates the proposed maps in place; those maps are copies from derive, not the event payloads.)

`followup`, `steer`, and `inject` are the inbox: next-turn versus next-step, waking versus not. They become `user-message` rows only when claimed. This chapter's lab does not drain that queue; `examples/inbox-turn.reb` does. The important coupling is the same: claimed text hits the log before the next derive, so the model sees it the same way it sees a typed user string.

The cost of rereading is real CPU on long sessions, and it forces every feature that wants to "just add a system prompt" to be a waterfall instead of a field on the loop. The alternative, caching the last derive, is how a cancel or a fork silently serves stale tools. `max-steps` (default 8, overridable via `service-resolve-config`) is the other brake: a guest that only returns tool-calls will not run forever.

## Wrap-up

Imagine a clerk who, every morning, reads the bound notebook aloud to a guest and then writes down what the guest said or asked to do. The clerk does not keep a second notebook in a desk drawer. `resume-turn` is "continue tomorrow without inventing a new visitor." `agent-pre-step` is whispering a different wording to the guest while leaving the visitor's original sentence on the page. The usual mistake is to think the loop *has* a conversation. It has a pointer `live-session-id` and a habit of calling `derive-messages`. Self-check: after a tool-call step, where does the next model input's tool result come from — a variable on the loop, or a `tool-result` event already in the session?

This chapter is the spine's motor. The next one explains why that motor is installed in a private room per agent, while the notebook stays at the front desk.

---

## Experiments

```bash
cd ch07-the-turn/code
bash run.sh
```

Expected output (key lines):

```text
TOOL-STATUS: text
TOOL-STEPS: 2
TOOL-TEXT: saw the tool
TOOL-ROLES: [user assistant tool assistant]
RESUME-TEXT: from-resume
RESUME-ROLES: [user assistant assistant]
RESUME-USER-ROWS: 1
PRESTEP-ASSISTANT: [prefix] hello from pre-step
PRESTEP-LOG-USER: hello from pre-step
LAB-OK
```

### Try this

1. After the tool turn, call `resume-turn` *without* enqueueing a new reply. The echo adapter will see the last user content (`"run it"`) and you will get a third assistant row that repeats it. Resume does not invent a user line; it will still ask the guest.
2. Change the pre-step listener to return `make map! [kind: 'reject reason: "nope"]`. The turn status should become `rejected` and a `step-rejected` event should appear. The user row in the log should remain the original string.
3. In `demo.reb`, print `spine/driver/max-steps`, then enqueue nine bash tool-calls and no final text. Status should become `max-steps`.

### Against the source

| Path | Symbol |
|------|--------|
| `agent-loop/api.reb` | `run-turn-core`, `resume-turn`, `can-admit-turn?`, `run-pre-step`, `run-request` |
| `session/api.reb` | `derive-messages` (called every step) |

Inbox claim rules are easier to see in `examples/inbox-turn.reb` than in this slice.
