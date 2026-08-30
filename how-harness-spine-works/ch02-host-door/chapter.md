# Chapter 02 Why Must Every Side Effect Go Through One Door?

Once you have an echo turn, the next temptation is to let tools and the model reach the world directly. A bash tool can call `call/wait/shell`. An HTTP adapter can call `curl` in its own function. A delay can `sleep`. Each of those works in isolation. Together they make cancel, tests, and audit impossible: there is no single place that knows which child process is live, and no single place a test can replace with a file.

harness-spine answers that with a boring service named `host`. The name is easy to skip. The constraint is not. Architecture says it plainly: host is the real I/O door — shell, HTTP, streaming HTTP, delay — and it does not interpret tools, write sessions, or parse LLM protocols.

The naive design is "whoever needs I/O performs I/O." A `bash` tool owns `call`. An LLM adapter owns `curl`. The loop owns `sleep` while it waits. The failure is not that those calls are slow. It is that they are unaccountable. `cancel-turn` in the loop can set a flag, but it cannot kill a curl it never started. A test that wants a streamed model reply has to stand up a network. Two plugins that both spawn processes will disagree about cleanup.

Therefore the spine needs one object whose methods are the only allowed exits. [`host/api.reb`](../../host/api.reb) `make-host-service` is that object.

## A door, not a platform

`run-command` wraps `call/wait/shell/output/error` and always returns a map with `ok`, `code`, `stdout`, `stderr`. It does not throw on a non-zero exit; it reports. That is already a policy: tools and tests consume a result, they do not catch a language error for "ls failed."

`http-get` accepts a `url!` *or* a `file!`. The file path is not a convenience for local HTML. It is how the rest of the spine, especially `llm/http.reb`, can replay a response without a socket. `http-post` still shells out to `curl`, writing the body to a tempfile first. `http-post-stream` is the interesting sibling: a `file!` source is drained line by line through `host-emit-lines`; a `url!` source launches `curl -N` in the background, tails the outfile, and honors a cancel object by killing the pid. The loop will later pass that same cancel object down from `turn-cancelled?`.

`delay` and `settle` are I/O in the Cordis sense: they talk to the deterministic scheduler on the runtime scope, or become a thenable that is already resolved. The lab's `delay 5 99` is not sleeping the OS for five milliseconds as a product feature. It is proving that host is also the place async waits go, so the loop can pump the scheduler and still see a cancel flag.

What host refuses to be is a tool interpreter. `shell/api.reb` registers `bash` *on tools*, and `bash` calls `host/run-command`. The loop never calls host. The LLM HTTP adapter calls `host/http-post` / `host/http-post-stream`. Session persistence uses `write` in `session/store.reb` — that is a deliberate exception for the log's own files, not a second world door for tools.

The cost of one door is obvious: every new kind of I/O wants a new host method, and host can become a junk drawer. The spine keeps the list short on purpose. The alternative — an interface per plugin — looks cleaner on a whiteboard and then cannot share a cancel pid. When this chapter's lab runs `echo spine-host` and `http-get` on a fixture file, it is not demonstrating curl. It is demonstrating that the same service returns the same shape of map whether the world was a process or a file.

The door does not remember. That is the next pressure. If host is the only way out, something else has to be the only way to know what was said and done.

---

## Experiments

```bash
cd ch02-host-door/code
bash run.sh
```

Expected output (key lines):

```text
CMD-OK: #(true)
CMD-CODE: 0
CMD-STDOUT: spine-host
GET-OK: #(true)
GET-BODY: host-file-body
DELAY-THENABLE: #(true)
DELAY-SETTLED: 99
LAB-OK
```

### Try this

1. Change `run-command` to `"false"` (the Unix command). `CMD-OK` should become `#(false)` and `CMD-CODE` a non-zero integer. Host reports; it does not throw.
2. Point `http-get` at a missing file. `GET-OK` should be `#(false)` and `GET-BODY` empty; `error` on the result map carries the read failure.
3. Replace `h/settle d` with just `d` in the print. You will see a thenable object instead of `99`. That is why the loop and tools both call `settle` instead of treating delay as a value.

### Against the source

| Path | Symbol |
|------|--------|
| `host/api.reb` | `make-host-service`, `run-command`, `http-get`, `http-post-stream`, `delay`, `settle` |
| `shell/api.reb` | `make-bash-spec` (calls `host-ref/run-command`) |
| `llm/http.reb` | `run-llm-http`, `run-llm-http-stream` |

The teaching slice does not spawn a live HTTP server. Streaming cancel against curl is covered in Chapter 09's protocol, and in `test/host-stream-test.reb`.
