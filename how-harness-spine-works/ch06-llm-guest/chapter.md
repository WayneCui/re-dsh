# Chapter 06 Why Isn't the Model in Charge?

By now the spine can remember and act. The remaining temptation is to let the model own the loop: call the vendor, parse whatever JSON comes back, and treat that object as the next state of the world. That is how a wrapper becomes a remote code interpreter. The vendor times out, the schema drifts, the stream retries, and your session is whatever the last HTTP body happened to be.

harness-spine inverts the relationship. The loop asks an `llm` service for a reply. The service returns a small map: `kind: 'text` with `text`, or `kind: 'tool-call` with `name` and `args`. Adapters may be a queue, a Rebol script, an HTTP line protocol, or the built-in echo. The model does not see host, does not append to the session, and does not execute tools. Architecture's line is the right one: llm does not execute tools and does not own session.

The naive design is "the SDK is the agent." You pass messages in, you get a message out, and if it contains `tool_calls` you run them with the SDK's chosen schema. The failure is ownership. Cancel has to fight the SDK's HTTP client. Tests need network. Swapping providers means swapping the loop. A scripted fixture for a bug report cannot be loaded because the loop imported `openai` at the top of the file.

## A guest with a queue

[`llm/api.reb`](../../llm/api.reb) `resolve-reply` is the guest's front desk. If `queue` is not empty, `take queue` wins. Else a configured `script` path runs via [`llm/script.reb`](../../llm/script.reb). Else `http-url` runs via [`llm/http.reb`](../../llm/http.reb). Else echo `last-user-content`. The lab's first `complete` therefore returns `"hello guest"` without a vendor. The second call, after `enqueue` of `"from-queue"`, returns the queued map even though the messages are unchanged. Tests and later chapters depend on that order: the queue is not a cache of the last echo; it is a scripted adapter that sits in front of every other adapter.

`stream` is the same guest, with a sink. If the HTTP stream path applies (empty queue, no script, `http-url` set), `run-llm-http-stream` posts through host and parses a line protocol: maps with `delta`, optional final `kind`/`text`, or plain non-empty lines as delta text. Otherwise `resolve-reply` runs and `emit-text-chunks` either walks a `chunks` block or sends the whole `text` once. The lab enqueues `chunks: ["hel" "lo"]` and the sink sees both pieces while the returned map still holds `"hello"`.

The driver in Chapter 07 will write each sink call as `assistant-chunk` and then write `assistant-message` from the final map. The lab already runs one turn that way: two chunk events, one message, and `derive-messages` matching a non-chunked turn that returned the same `"hello"`. Streaming is an on-the-wire shape. It is not a second memory.

What the guest is not allowed to do is pick a different session, or call `tools/execute` itself. A `tool-call` reply is data. The loop decides whether that name exists, whether approval applies, and whether cancel has already been requested. HTTP adapters that want a socket still go through host, so a file fixture can stand in for a URL. `service-resolve-config` on the plugin lets YAML intercept merge `script` / `http-url` the same way `max-steps` is merged onto the loop.

The cost of this humility is that "just stream tokens to the UI" is not a one-liner inside the adapter. The adapter must either fill `chunks` or speak the line protocol; the loop owns the log. The alternative, letting the adapter append events, would make every vendor a competing historian. Incomplete: this tree's default adapter is echo, not a production model. `examples/full-chain.reb` and `llm/http.reb` show the HTTP path; this chapter's lab stays on enqueue so you can run it without a key.

The next chapter is the host of this guest: a turn that rereads the log, asks the guest, and only then acts.

---

## Experiments

```bash
cd ch06-llm-guest/code
bash run.sh
```

Expected output (key lines):

```text
ECHO: hello guest
ENQUEUED: from-queue
STREAM-TEXT: hello
STREAM-CHUNKS: ["hel" "lo"]
TURN-ASSISTANT: hello
TURN-TYPES: [turn-start user-message step-start assistant-chunk assistant-chunk assistant-message step-end turn-end]
DERIVE-MATCH: #(true)
LAB-OK
```

### Try this

1. Enqueue a `kind: 'tool-call` map (`name: 'bash`, `args` with `command`) instead of text, then `complete`. You should get that map back unchanged. The guest may propose an act; it does not perform it.
2. Set `chunks` to `["hel" "lo"]` but `text` to `"mismatch"` and stream. The sink still walks `chunks`; the returned `text` is `"mismatch"`. The loop will log chunks from the sink and the final message from `text`. Honesty in adapters matters.
3. Read [`llm/http.reb`](../../llm/http.reb) `parse-llm-stream-line` and feed `host/http-post-stream` a fixture file of delta lines (see `test/fixtures/llm-http-stream.txt`). That is the production path this lab mocks with `enqueue`.

### Against the source

| Path | Symbol |
|------|--------|
| `llm/api.reb` | `resolve-reply`, `complete`, `stream`, `enqueue` |
| `llm/reply.reb` | `last-user-content`, `normalize-llm-reply` |
| `llm/http.reb` | `run-llm-http-stream`, `parse-llm-stream-line` |

Adapters do not call `sessions/append-event`. If you find one that does, it is a bug.
