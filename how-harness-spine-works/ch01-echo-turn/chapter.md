# Chapter 01 What Actually Happens When You Send "hello"?

The shortest honest agent looks like a loop around a model. You send a string, the model answers, and if the answer names a tool you run it and send the result back. A weekend prototype of that loop can look finished. It is not. The first time you want to know *what happened* — not what the UI currently displays — the loop has already thrown the evidence away. The first time you want to stop it, there is no protocol, only a killed process. The first time two agents share a conversation, their tool tables collide.

harness-spine is the opposite bet. An agent is a small machine that can talk, act, remember, and be stopped, and that can reconstruct those four facts from a log. The model is a guest of that machine, not the owner. This chapter does not prove every layer. It boots the whole spine, sends one string, and watches the machine write a turn. The rest of the book takes that turn apart.

The naive design is worth stating, because it is what most wrappers still are:

```text
messages.append(user)
reply = llm(messages)
if reply is tool: run it; append result; repeat
else: print reply
```

That design treats `messages` as both memory and model input. It treats tool execution as a private function call. It treats cancel as `Ctrl-C`. It works until you need any one of those to be inspectable. harness-spine therefore starts from a different primitive: `boot-spine` in [`boot.reb`](../../boot.reb) mounts a root context, hangs shared services on it, then creates a default agent whose *acting* plugins live in an isolate.

## One echo is already a protocol

`boot-spine` does not construct a chatbot object. It builds a Cordis context, attaches a deterministic scheduler, and registers plugins in a fixed order: `host`, `session`, `approval`, `llm`, `agents`. Then `create-agent-handle` in [`scope/api.reb`](../../scope/api.reb) mints a scope key, isolates `tools` / `shell` / `agent-loop` onto a child context, and returns a handle whose `run-turn` is just `driver/run-turn`.

The default LLM adapter is not a network client. `resolve-reply` in [`llm/api.reb`](../../llm/api.reb) first drains an `enqueue` queue; if the queue is empty and no script or HTTP adapter is configured, it echoes `last-user-content`. That is why `"hello from spine"` comes back as assistant text. The echo is a teaching adapter, but it is also a design statement: the spine can complete a turn without a vendor.

`run-turn-core` in [`agent-loop/api.reb`](../../agent-loop/api.reb) then does something the naive loop never does. It writes `turn-start`, writes the user message, derives the model-visible view from the log, streams the reply (the stream sink writes `assistant-chunk` rows), writes a final `assistant-message`, and closes with `turn-end`. After the lab you will see that event list in order. The derived messages are only two rows — user and assistant — because `derive-messages` in [`session/api.reb`](../../session/api.reb) is a view. Chunks collapse; the final message wins.

So the first turn already shows the spine's split: the log is the memory, the view is what the model sees, the driver is a protocol, and the model is whoever `llm/stream` happens to be this process. Later chapters add tools, approval, isolate rooms, cancel, and reload. None of them replace this split. They hang off it.

The cost of starting here is that you meet several names at once — `spine`, `driver`, `sessions`, `derive-messages`. That is deliberate. A book that introduced host, then session, then tools, without ever running a turn would make each piece feel like a library. The spine is not a library. It is a machine whose first job is one honest turn.

What this chapter does not yet explain is *why* host exists, why payloads are frozen, or why tools are a waterfall. Those pressures show up as soon as the echo adapter is no longer enough.

---

## Experiments

```bash
cd ch01-echo-turn/code
bash run.sh
```

Expected output (key lines):

```text
STATUS: text
STEPS: 1
ASSISTANT: hello from spine
MSG 1 user: hello from spine
MSG 2 assistant: hello from spine
--- event types ---
[turn-start user-message step-start assistant-chunk assistant-message step-end turn-end]
LAB-OK
```

### Try this

1. In `demo.reb`, change the user string to `"ping"` and rerun. The assistant text should echo `"ping"`. That is `last-user-content` in [`llm/reply.reb`](../../llm/reply.reb), not a trained model.
2. Before `run-turn`, enqueue a different reply (`kind: 'text`, `text: "not-an-echo"`) via `spine/llm/enqueue`. The assistant should print that string instead. The queue is checked first in `resolve-reply`.
3. After the turn, print `length? spine/sessions/events-of s/id` and compare it to `length? spine/sessions/derive-messages s/id`. The log is longer than the conversation. Chapter 03 is about that gap.

### Against the source

| Path | Symbol |
|------|--------|
| `boot.reb` | `boot-spine`, `create-agent-handle` (via scope) |
| `agent-loop/api.reb` | `run-turn`, `run-turn-core` |
| `llm/api.reb` | `resolve-reply`, `stream` |
| `llm/reply.reb` | `last-user-content` |
| `session/api.reb` | `derive-messages` |

Line numbers are a snapshot of the current tree; symbols are the stable anchors.

The teaching slice is `examples/echo-turn.reb` with labels. It does not reimplement the spine.
