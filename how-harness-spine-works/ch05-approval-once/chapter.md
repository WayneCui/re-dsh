# Chapter 05 Why Ask Once, Fail Closed, and Write Both Sides?

A waterfall that can deny is not the same as a human saying yes. The naive design is a boolean on the tool, or a callback the UI blocks on, with nothing in the session except the tool-result that eventually appears. That design lies in two directions. If the process dies during the prompt, you cannot tell whether the human ever answered. If the same tool runs twice, "the user already said yes" becomes a sticky grant you did not intend. If no UI is listening, a boolean defaults to true in one codebase and false in another, and neither leaves a trace.

harness-spine puts a one-shot seam in front of the body and writes both the question and the answer into the log. [`approval/api.reb`](../../approval/api.reb) `request` requires an open turn (`turn-start` without a later `turn-end`). It mints an id, appends `approval-asked`, then either rejects immediately under policy `'never` or runs the `approval-request` waterfall. The default inner of that waterfall returns `'unavailable`. There is no built-in UI. Missing an answerer is a recorded outcome, not a hang and not an implicit allow.

## Fail closed is a default inner

`decide-outcome` builds a tiny request map and waterfalls `approval-request`. The inner is `'unavailable`. A test or a host UI prepends a listener that returns `'allowed-once` or `'rejected` (or `'cancelled`). `normalize-approval-outcome` maps anything else back to `'unavailable`. Then `request` appends `approval-decided` with that outcome. The lab shows the pairing: three asks, three decisions, including the `never` path that never called an answerer and the `ask` path that did.

Policy lives in the log too. `set-policy` appends `approval-policy` with `'ask` or `'never`. `effective-approval-policy` scans events in reverse for the latest policy row, else the service default (`'ask`). So a session can start permissive and lock down, and a replay can see when that happened. There is no grant store. `'allowed-once` means this call, not this tool for the rest of the week.

`tools/execute` is how the seam is reached in product code. If pre-execute (or the spec's `approval: 'ask`) raises ask, `resolve-approval-ask` looks up the `approval` service, requires a `session-id` in the execute meta map, and calls `approval/request`. Only `'allowed-once` continues to the execute inner. The lab's `ask-ping` tool is denied when no answerer is present (`ok: false`) and runs `"allowed-body"` after a grant listener is attached. The body never saw the denial path.

Requesting approval outside an open turn throws. That looks harsh until you imagine an approval row floating between turns, unmatched to any `run-turn`. The spine would then have a human decision that no driver is obligated to honor. Fail closed includes "not now."

The cost of this seam is that a real product must supply the answerer — a CLI prompt, a chat button, an always-deny in CI. The spine will not pretend to be that product. The alternative, baking `ask` into tools as `input()`, would block the scheduler and skip the log. Outcomes other than the four words in `approval-outcomes` collapse to `'unavailable` on purpose; a typo in a UI hook must not become a grant.

What this chapter does not add is a memory of grants across calls, or a policy richer than ask/never. If you need "always allow bash after the first yes," that is your listener's business, and it should still write something you can replay.

---

## Experiments

```bash
cd ch05-approval-once/code
bash run.sh
```

Expected output (key lines):

```text
NEVER: rejected
NO-ANSWERER: unavailable
GRANTED: allowed-once
ASKED: 3
DECIDED: 3
OUTSIDE-TURN: #(true)
TOOL-DENIED: #(false)
TOOL-GRANTED: allowed-body
LAB-OK
```

### Try this

1. Under `'never`, attach an answerer that returns `'allowed-once` and rerun. `NEVER` should stay `rejected`. Policy `'never` does not call `decide-outcome`.
2. Return the string `"allowed-once"` from the answerer instead of the word. `normalize-approval-outcome` accepts that conversion. Return `"sure"` and you should see `unavailable`.
3. Call `tools/execute` on `ask-ping` *without* a `session-id` in meta. The deny reason should mention that approval ask requires a session.

### Against the source

| Path | Symbol |
|------|--------|
| `approval/api.reb` | `request`, `decide-outcome`, `set-policy`, `effective-approval-policy` |
| `tools/api.reb` | `resolve-approval-ask`, `pre-ask?` |

There is no grant store and no built-in UI. Those absences are the design.
