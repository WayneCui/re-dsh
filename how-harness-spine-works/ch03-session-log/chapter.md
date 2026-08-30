# Chapter 03 Why Is Memory a Log, Not a Chat?

After one echo turn you already saw the split: seven event types in the log, two messages in the view. It is tempting to treat that as bookkeeping — "the framework stores extra metadata." It is not metadata. The spine's memory *is* the event log. The conversation the model sees is a function of that log, computed over again every step. If you keep a parallel `messages` array, you now have two histories, and they will disagree the first time a stream retries, a turn cancels, or a fork branches.

The naive design is the OpenAI-shaped array: `[{role: user, content: ...}, {role: assistant, ...}]`. Append on every turn, send the array to the model, maybe persist it as JSON. That design fails as soon as the assistant answer arrives in pieces. Do you append one message per chunk, or buffer? If you buffer and crash, the chunks are gone. If you append chunks as messages, the next request looks like the model talked six times. Tool calls make it worse: the array has to invent a schema for `tool` rows, and nothing stops a caller from mutating yesterday's content in place.

Therefore the spine stores events, not messages. [`session/api.reb`](../../session/api.reb) `append-event` validates the type and payload, snapshots the payload with `snapshot-json-map` from [`session/json.reb`](../../session/json.reb), assigns a dense `index`, emits `session-event`, and optionally writes a file. The snapshot is the first thing the lab proves. You hand `append-event` a live map, then smash `text` to `"after"`. The stored payload is still `"before"`. History is not a pointer into the caller's heap.

## A view that can be thrown away

`derive-messages` walks the log and produces the model-visible array. User and assistant messages become `role` / `content` rows. Consecutive `assistant-chunk` events concatenate into one assistant message. If an `assistant-message` follows, the chunk buffer is discarded — the final message wins. `tool-call` projects as an assistant row with `kind: 'tool-call`; `tool-result` projects as `role: 'tool`. Turn bookkeeping (`turn-start`, `step-end`, approval events) does not appear. That is why the echo turn's view is two rows while the log is seven.

Because the view is derived, the driver never has to keep a shadow copy. Chapter 07 will show `run-turn-core` calling `derive-messages` at the start of every step. If that sounds wasteful, compare it to the cost of a forked history. `fork` copies the prefix into a new session id, sets `forked-from`, and then the two logs append independently. The lab's parent stays at two messages; the child grows a third. There is no "shared array with a copy-on-write flag" to get wrong.

When `store-dir` is set, [`session/store.reb`](../../session/store.reb) writes `mold/all` of the events block to `<id>.events.reb` after every append. `open` on a fresh boot reloads that file, validates it, and restores `derive-messages`. The lab shuts the first spine down, boots a second, and reads `"persist me | ok"` back. Default boot has no backend: `open` errors, which is honest. Persistence is a config, not a hidden global.

The cost of a log is verbosity and a closed event vocabulary. `validate-payload` will reject an unknown type and a user message whose `text` is not a string. You cannot sneak a function or a cyclic object into history; `json-map?` refuses it. That is the point. The alternative — "store whatever the adapter returned" — is how a session file becomes unreplayable. Resume policy lives in the loop, not here: `can-admit-turn?` treats a log that ends on `user` as `no-input`, so a bare user-message is not enough to call the model again. The log rules in this chapter stay stable either way.

If you remember one picture from this chapter, remember a ledger. The teller window (`derive-messages`) can be reprinted any time. Nobody is allowed to edit a closed row. Fork is opening a second ledger that starts with a photocopy of the first.

## Wrap-up

Think of the session as a bound notebook, not a chat bubble. Each `append-event` is a numbered line that has already been photocopied (`snapshot-json-map`); the caller's pen can keep moving and the notebook will not. `derive-messages` is the clerk who reads the notebook aloud to the guest model — folding chunks, preferring the final assistant line, skipping turn furniture. The usual mistake is to treat the clerk's transcript as the notebook. Self-check: after two `assistant-chunk` events and one `assistant-message`, how many assistant rows does the clerk produce, and which text do they contain?

This chapter adds the memory layer on top of host. It does not yet decide who is allowed to act. That is tools.

---

## Experiments

```bash
cd ch03-session-log/code
bash run.sh
```

Expected output (key lines):

```text
FROZEN: before
FOLDED: hello
MESSAGE-WINS: hello-final
PARENT-MSGS: 2
CHILD-MSGS: 3
FORKED-FROM: s3
PERSIST-ID: s1
MEMORY-EMPTY: #(true)
OPENED-ID: s1
REOPENED: persist me | ok
LAB-OK
```

`FORKED-FROM: s3` is not a magic id. The demo creates two sessions before the parent, so the parent is `s3`.

### Try this

1. After appending `"before"`, mutate a nested map inside the payload (an `args` map on a `tool-call`) instead of `text`. Confirm the stored nested map is still the snapshot. `snapshot-json-map` copies maps and blocks recursively.
2. Comment out the `assistant-message` append and rerun. `MESSAGE-WINS` should disappear; `FOLDED` remains `hello`. That is the chunk-only path in `derive-messages`.
3. Point `store-dir` at a new folder, skip `open`, and `read` the `.events.reb` file with a text editor. You should see a Rebol block of maps, not a chat JSON array.

### Against the source

| Path | Symbol |
|------|--------|
| `session/api.reb` | `append-event`, `derive-messages`, `fork`, `open`, `validate-payload` |
| `session/json.reb` | `snapshot-json-map`, `json-map?` |
| `session/store.reb` | `make-file-session-backend`, `save-session`, `load-session` |

The teaching slice omits `create-from-log` replay and `session-end-seed`. Those live in `test/session-test.reb`.
