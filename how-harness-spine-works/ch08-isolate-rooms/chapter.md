# Chapter 08 Why Give Each Agent Its Own Room?

If tools, shell, and the loop were root services, two agents would share one registry and one `cancel-requested` flag. Registering `whoami` on agent A would change what agent B runs. Cancelling A would cancel B. Listening to `tools-result` would mean listening to everyone. The naive design is exactly that: one global toolbox, many conversations. It feels simpler until the second agent exists.

harness-spine splits the world the way Architecture states it: each agent is `isolate 'tools` plus a scope key; session and llm stay on the root. [`scope/api.reb`](../../scope/api.reb) `create-agent-handle` mints an opaque key (`make object! []` with a label), optionally `bind-scope-parent`, then `extend-agent-iso` which puts `tools`, `shell`, and `agent-loop` into the root's `isolate-map` under `agent-<label>`. The child context gets those three plugins. The handle's `tools` and `driver` are looked up on that isolate, not on the root.

## Private acting, shared memory

The lab spawns A and B, registers a `whoami` spec on each with a closed-over id, and executes. A returns `"A"`, B returns `"B"`. That is not namespacing inside one map. It is two `tools` services, each with its own `registry`. `shell` is likewise isolated, so bash on A is not a way to sneak a spec onto B.

Events follow the key, not the process. `execute` emits `tools-result` with `make-scope-target scope-of ctx`. `scope-admits?` walks from the dispatch key up the parent chain; a listener whose `scope-of` is B does not admit A's dispatch. The lab attaches listeners on each isolate ctx: A hears A, B does not, and the reverse. A parent key is the exception that is a feature. The lab mints `parent`, spawns `child` with `/parent`, attaches that key on the *root* ctx, and the root listener hears the child's `tools-result`. Sub-agents can report upward. Siblings cannot peek sideways.

Session is the shared front desk. A and B each `run-turn` on the same session id. Four derived messages: from A, echo, from B, echo. The notebook does not fork just because the speaker changed. If you *want* isolation of memory, you `sessions/create` twice or `fork`. The spine will not invent a second log per isolate; that would make "two agents, one thread" impossible.

[`agent/api.reb`](../../agent/api.reb) wraps handle creation in a live registry with `agent-created` / `agent-disposed`. `dispose` calls `cancel-turn` first, then `release-agent-handle`, which disposes isolate fibers. The default agent from `boot-spine` is registered the same way. `spawn-agent` in `boot.reb` is the short path used by the lab.

The cost of rooms is a harder mental model and a rule you will trip on: root YAML in `cordis.yml` lists host, session, approval, llm, agents — not tools. Tools still appear because `create-agent-handle` installs them. Looking at the YAML and asking "where is bash?" is the wrong layer. The alternative, putting tools on the root and filtering by agent id inside every method, spreads isolate logic across every plugin. Isolate-map keeps the kernel's existing `extend` behavior; scope keys keep event routing from becoming "inspect the payload for an id."

## Wrap-up

Think of a hotel. The front desk (`sessions`, `llm`, `host`) is shared. Each guest gets a room whose minibar (`tools`), kettle (`shell`), and in-room phone (`agent-loop`) are not the neighbor's. The room key is an opaque object, not a string you parse. A suite's parent key can hear the connecting room; the room next door cannot. The usual mistake is "agent equals session." Self-check: two isolates run turns against `s1` — how many session objects exist, and how many `tools` registries?

This chapter adds occupancy. Stopping an occupant without lying about what they were doing is the next protocol.

---

## Experiments

```bash
cd ch08-isolate-rooms/code
bash run.sh
```

Expected output (key lines):

```text
WHO-A: A
WHO-B: B
A-HEARD-A: #(true)
B-HEARD-A: #(false)
B-HEARD-B: #(true)
A-HEARD-B: #(false)
SHARED-MSGS: 4
FIRST-USER: from A
THIRD-USER: from B
PARENT-HEARD-CHILD: #(true)
LAB-OK
```

### Try this

1. Register `whoami` only on A, then `agent-b/tools/execute 'whoami`. You should get `unknown-tool`. Isolation is not a prefix; the spec is absent.
2. Remove `attach-scope-ctx spine/ctx parent-key` and rerun the parent listener. `PARENT-HEARD-CHILD` should become `#(false)` because `scope-of` on the root would no longer match the child's dispatch chain.
3. Print `agent-a/ctx` versus `spine/ctx` and confirm they are not `same?`. Then `reflect/get 'sessions` on both: session still resolves from the parent chain; tools should not.

### Against the source

| Path | Symbol |
|------|--------|
| `scope/api.reb` | `create-agent-handle`, `extend-agent-iso`, `make-scope-target`, `scope-admits?` |
| `agent/api.reb` | `create`, `dispose`, `register` |
| `boot.reb` | `spawn-agent`, `boot-spine` (default handle) |

Agent isolate plugins are not YAML entries. Chapter 10 will show that again from the assembly side.
