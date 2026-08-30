# Chapter 09 Why Is Stopping a Protocol, Not an Exception?

Starting a turn is easy to celebrate. Stopping one is where wrappers start lying. The naive stop is `Ctrl-C`, `kill`, or throwing from a callback. The process is gone, or the stack unwound, and the session now contains a `tool-call` with no result, or a stream that looks like the model went silent. The next `derive-messages` will send that incomplete story back to a new model as if it were history.

harness-spine makes cancel a cooperative protocol that still has to leave the notebook consistent. `cancel-turn` on the loop sets `cancel-requested` if `live-session-id` is a string, and returns that id. If the driver is idle, it returns `none` and does **not** leave the flag set. The lab's first two lines are that idle contract: `_` and `#(false)`. A sticky idle flag would cancel the next innocent turn.

## Checkpoints, then a cancelled row

`run-turn-core` stores the live session and clears the flag at start. It checks `turn-cancelled?` (flag or inactive fiber) before the step loop, at step-start, after stream, before execute, and after execute. `settle` on the loop pumps thenables one scheduler item at a time so a delay can be interrupted. Tools `settle/cancel` takes a `cancel-check` object whose `call` is `turn-cancelled?`. LLM `stream` takes the same shape. Host `http-post-stream` kills a curl pid when that object trips. One flag, three layers, no second cancel type.

The lab registers `abort`, whose body calls `driver/cancel-turn` and returns `"abort-body"`. The queued follow-up text is `"should-not-run"`. After `run-turn`, status is `'cancelled`, the flag is cleared, the log has `turn-start`, `tool-call`, `tool-result`, `turn-end`, and **no** `assistant-message`. The tool-result payload has `cancelled: true` and `text: "cancelled"`. Notice the body did run — this path cancels *after* the spec returns, and the loop still refuses to treat that return as a normal result. `cancelled-tool-result` is written instead. A delayed path in `test/loop-cancel-test.reb` cancels during `host/delay` so the body never completes; both paths end with a cancelled tool-result, not a hang.

That write is the honesty. The next derive will show a tool row whose content is `"cancelled"`. A new model can see that the act did not finish. The follow-up enqueue is left unconsumed, which is why the next turn on a fresh session can echo `"next"` normally. Cancel is not a poisoned process.

`agents/dispose` in [`agent/api.reb`](../../agent/api.reb) calls `cancel-turn` before tearing isolate fibers down. After dispose, `agent-active?` is false (`fiber/uid` is gone), and `run-turn` returns `status: 'disposed` without pretending to start. The lab's last line is that refusal.

The cost of cooperative cancel is that a tool which ignores host and spins in Rebol will not notice the flag until it returns. The spine cannot make `call/wait` of an uninterruptible binary into a transaction. What it can do is refuse to *record* a success it did not intend, and refuse to start work on a dead fiber. The alternative, killing the OS process, is honest only if you discard the session; if you keep the log, you still need a cancelled row. Incomplete: there is no distributed two-phase abort across external APIs the tool already committed.

## Wrap-up

Stopping is not yanking the power cord. It is raising a hand at the next checkpoint, then writing "cancelled" into the notebook so the next guest does not inherit a ghost. Idle cancel is a no-op so the hand is not still raised tomorrow morning. Dispose cancels first, then takes the room key away; a later `run-turn` gets `disposed`, not a mysterious missing service. The usual mistake is `throw` from a tool and hoping the session looks like the throw. Self-check: after the abort tool runs, does the log contain the follow-up assistant text that was already in the LLM queue?

This chapter closes the live protocol. Assembly — how the rooms get built, overlaid, and swapped without discarding the notebook — is the last layer.

---

## Experiments

```bash
cd ch09-cancel-protocol/code
bash run.sh
```

Expected output (key lines):

```text
IDLE-CANCEL: _
IDLE-FLAG: #(false)
CANCEL-STATUS: cancelled
FLAG-CLEARED: #(false)
HAS-TURN-START: #(true)
HAS-TOOL-CALL: #(true)
HAS-TOOL-RESULT: #(true)
HAS-ASSISTANT: #(false)
RESULT-CANCELLED: #(true)
RESULT-TEXT: cancelled
NEXT-STATUS: text
DISPOSED: disposed
LAB-OK
```

### Try this

1. Remove `drv/cancel-turn` from the abort tool and rerun. Status should become `'text` and `HAS-ASSISTANT` `#(true)` with `"should-not-run"`. The queue is only skipped because cancel broke the loop.
2. After a cancelled turn, `resume-turn` on the same session. You should get a continuation from the cancelled tool-result (`role: 'tool`), not a blank slate. History includes the abort.
3. Call `cancel-turn` twice while idle. Both should print `_`. The flag must not stick.

### Against the source

| Path | Symbol |
|------|--------|
| `agent-loop/api.reb` | `cancel-turn`, `turn-cancelled?`, `cancelled-tool-result`, `agent-active?` |
| `tools/api.reb` | `settle/cancel` |
| `host/api.reb` | `http-post-stream` `/cancel` |
| `agent/api.reb` | `dispose` (cancel then release) |

`test/loop-cancel-test.reb` also covers cancel during `host/delay`.
