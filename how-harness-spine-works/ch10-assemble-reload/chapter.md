# Chapter 10 Why Assemble and Hot-Swap Instead of Writing It Once?

Every previous chapter could have been one file: host functions, a log, a loop. That file would be easy to paste and impossible to vary. Production wants a minimal echo profile, a full HTTP profile, a home overlay that turns approval off, and a way to replace the LLM adapter without dropping the session. The naive design is flags: `if config.useHttp [load http]`. The failure is combinatorics, and a worse failure at runtime: swapping the adapter by assignment leaves the loop holding a stale service object from before the fiber epoch changed.

harness-spine assembles. `boot-spine` in [`boot.reb`](../../boot.reb) is the code path: register root plugins, `create-agent-handle` for `"default"`. [`boot-yaml.reb`](../../boot-yaml.reb) `boot-spine-from-config` composes an entry list and mounts it with the same plugin objects. [`cordis.yml`](../../cordis.yml) lists host, session, approval, llm, agents — not tools. Isolate plugins still come from `create-agent-handle`. The lab dumps that list, then runs the same echo string through a code boot and a YAML boot. Both reply `"yaml-parity"`. Assembly is not a second spine. It is a second way to name the first.

## Layers, then a swap that keeps the ledger

[`profile.reb`](../../profile.reb) stacks patches: bundle → profile `cordis.patch.reb` → home (`HARNESS_HOME` or repo `cordis.patch.reb`) → CLI `--patch`. `profiles/minimal` is the YAML equivalent of the root file; `profiles/full` matches `examples/full-chain.yml`. You do not need to memorize the patch language to believe the order. Architecture's table is the spec; `r3 -s boot-yaml.reb --profile minimal --dump-config` is the printer.

Homomorphic reload is the runtime half of assembly. `reload-plugin` in cordis-port's loader does the fiber swap. `reload-spine-plugin` in `boot.reb` first `quiesce-agent` on every live handle (`cancel-turn` if a session is live), reloads the root plugin, then `refresh-agent-refs` because isolate fibers that depended on `llm` may have been rebuilt, and `carry-inbox` so volatile queues are not dropped. The lab's first turn echoes `"hello cordis"`. After `reload-spine-plugin` of [`examples/fixtures/llm-upper.reb`](../../examples/fixtures/llm-upper.reb), the same session's second turn is `"HELLO CORDIS"`. Derived history still contains both the original echo and the uppercase line. The notebook did not reset. The guest changed.

A missing file does not half-apply. The lab's rollback path returns a loader error map and the next turn is still uppercase (`"STILL ALIVE"`). Failed reload keeps the previous plugin. That is the same honesty cancel had: do not leave the machine in a shape you cannot name.

`reload-agent-plugin` is the isolate-scoped cousin: swap a tool plugin under one agent, leave root `sessions` / `llm` and sibling agents alone. `examples/reload-llm.reb` is the narrative version of this lab; `test/reload-turn-test.reb` covers live-turn quiesce.

The cost of assembly is indirection. A bug that is "bash isn't registered" is usually "you looked at YAML instead of `create-agent-handle`," not a missing line in `cordis.yml`. The cost of reload is that anything which cached a service object across the swap is wrong — which is why handles are refreshed on purpose. The alternative, restarting the process, is always available and always drops in-memory sessions unless `store-dir` is set. Reload exists for the case where the log *must* survive the new guest.

You now have the whole spine: a door, a ledger, gates, a one-shot ask, a guest, a clerk who rereads, private rooms, a stop protocol, and an assembly that can change the guest without burning the ledger. The conceptual companion [`harness-for-everyone`](../../harness-for-everyone/README.md) tells that story without labs. The kernel companion [`how-cordis-port-works`](../../../cordis-port/how-cordis-port-works/README.md) is why `waterfall`, `isolate`, and `reload-plugin` exist as verbs. This book was the product those verbs were waiting for.

---

## Experiments

```bash
cd ch10-assemble-reload/code
bash run.sh
```

Expected output (key lines):

```text
DUMP-HAS-HOST: #(true)
DUMP-HAS-SESSION: #(true)
CODE-ECHO: yaml-parity
YAML-ECHO: yaml-parity
BEFORE-RELOAD: hello cordis
RELOAD: #(true)
AFTER-RELOAD: HELLO CORDIS
HIST user: hello cordis
HIST assistant: hello cordis
HIST user: hello cordis
HIST assistant: HELLO CORDIS
ROLLBACK: {[LoaderError] reload: file not found: %examples/fixtures/no-such-adapter.reb}
STILL-UPPER: STILL ALIVE
LAB-OK
```

### Try this

1. Run `r3 -s boot-yaml.reb --dump-config` and `r3 -s boot-yaml.reb --profile minimal --dump-config` from the repo root. The entry names should match. Then `--profile full` and look for the extra intercept / llm config the full profile adds.
2. In the demo, `reload-spine-plugin` a second time with the *same* uppercase fixture after the first swap. The third turn should still be uppercase; reload is not a toggle.
3. After a successful swap, print `same? spine/llm spine/default-agent/driver/llm`. If they diverge, you have found a stale handle — `refresh-agent-refs` is supposed to prevent that on the driver; a binding you copied into a local word before reload will still be stale. That is the cached-object cost.

### Against the source

| Path | Symbol |
|------|--------|
| `boot.reb` | `boot-spine`, `reload-spine-plugin`, `reload-agent-plugin`, `quiesce-agent`, `refresh-agent-refs` |
| `boot-yaml.reb` | `boot-spine-from-config`, `compose-spine-entries`, `make-spine-plugin-map` |
| `profile.reb` | `compose-profile-entries` |
| `cordis.yml` | root entry list |
| `examples/fixtures/llm-upper.reb` | uppercase `llm` plugin |

Isolate plugins (tools / shell / agent-loop) remain absent from the root YAML on purpose.
