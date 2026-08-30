# Chapter 04 Why Isn't a Tool Just a Function Call?

A tool looks like a function: name, arguments, result. The naive spine would keep a map of functions and `do registry[name](args)`. That is how plugins start, and it is how they leak. There is no moment where a policy can refuse the call without the function existing. There is no moment where a sandbox can rewrite stdout after the function ran. There is no event that observers can subscribe to without wrapping every function by hand. The first "just this once" `if name = 'bash [check ...]` becomes a second interpreter.

harness-spine treats a tool as a public act with witnesses. [`tools/api.reb`](../../tools/api.reb) `execute` does not start by running the body. It builds an `exec` map (`name`, `args`), then runs three waterfalls, then emits `tools-result`. The inner of each waterfall is a default that either allows, runs `spec/run/call`, or passes the body result through. Listeners prepend or wrap those inners the same way Cordis wraps any other waterfall.

## Four stages, one frozen emit

`tools-pre-execute` is the refuse gate. The default inner returns `#[kind: 'allow]`. A listener can return `kind: 'deny` (or `ok: false`). `pre-denied?` then builds a synthetic error result, emits `tools-result`, and returns without touching the body. The lab's ping counter stays at zero. That is the whole point of a gate that runs *before* `run/call`.

If pre-execute does not deny, the spec's own `approval` field can still raise `kind: 'ask`. Chapter 05 is that seam. This chapter only needs to know that ask is not a third way to run the body; it is a detour that must resolve to allow-once or become another deny.

`tools-execute` is the only stage whose default inner calls `spec-ref/run/call`. A listener that prepends here can skip the body the same way pre-execute does, which `test/tools-test.reb` covers as "exec-stage deny." The product intent is still: side effects happen in this inner, or they happen through host because the body called host. They do not happen in pre or post.

`tools-post-execute` receives `[exec body-out]`. The default inner returns `arg-block/2` — the body result. A listener can rewrite `stdout` / `text` after the fact. The lab's ping still ran once; the text became `"rewritten"`. Post is for policy and redaction, not for secretly doing the work.

Then `emit-result` appends to an in-memory `result-log` and `events/emit`s `tools-result` with a scope carrier from `make-scope-target`. Observers see a finished map. They cannot un-run the body. Chapter 08 will show that the carrier is why agent A's listener does not see agent B's ping.

`shell-plugin` is the existence proof that bash is not special to the loop. It injects `tools` and `host`, registers a spec named `'bash`, and the spec's `call` is `host-ref/run-command`. The lab's `echo through-host` therefore travels execute → bash spec → host → a result map. The loop, when it wants a tool, will call `tools/execute/meta` with a session id and a cancel check. It never calls host, and it never calls bash.

The cost of a waterfall is that "hello world" now has four names, and a listener that forgets to call `nw/call` can swallow the inner. The alternative — a single `before/after` middleware list owned by tools — would work until you wanted the same intercept machinery the rest of Cordis uses. Tools reuse `ctx/events/waterfall` on purpose. The incomplete piece to name: `settle/cancel` on each stage means a thenable body can be abandoned, but the body itself must cooperate; a runaway `call/wait` inside a spec is still a host problem, not a waterfall problem.

## Wrap-up

Picture an airport lane, not a function table. Pre-execute is the document check that can send you home without the plane moving. Execute is the only place engines start. Post-execute is customs inspecting the bag you already carried. `tools-result` is the loudspeaker announcing what happened, including the trips that never left the desk. The usual mistake is to register a function and "add logging later." Self-check: if a pre-execute listener returns `kind: 'deny`, does `spec/run/call` run, and is `tools-result` still emitted?

This chapter adds the acting layer. Permission — asking a human, once — is a guest of that layer, not a second tool runner.

---

## Experiments

```bash
cd ch04-tools-waterfall/code
bash run.sh
```

Expected output (key lines):

```text
PING: pong calls=1
UNKNOWN-OK: #(false)
UNKNOWN-ERR: unknown-tool
PRE-DENY: pre-denied calls=0
POST-REWRITE: rewritten calls=1
RESULT-EMITTED: #(true)
BASH-STDOUT: through-host
LAB-OK
```

### Try this

1. Change the pre-deny listener to return `kind: 'allow` and rerun. `PRE-DENY` should show `pong` (or you will need to print `select d 'text`) and `calls=1`. Deny is a value, not a missing listener.
2. Prepend a `tools-execute` listener that returns `make map! [ok: false error: "exec-denied"]` without calling the inner. `ping-calls` should stay 0. That is the exec-stage deny in `test/tools-test.reb`.
3. Execute `'bash` with a missing `command` key. The spec in `shell/api.reb` should return `ok: false` / `error: "missing command"` without calling host.

### Against the source

| Path | Symbol |
|------|--------|
| `tools/api.reb` | `execute`, `pre-denied?`, `emit-result`, `register` |
| `shell/api.reb` | `make-bash-spec`, `shell-plugin` |
| `scope/api.reb` | `make-scope-target` (carrier on emit) |

Unknown tools still emit `tools-result`. There is no silent `none`.
