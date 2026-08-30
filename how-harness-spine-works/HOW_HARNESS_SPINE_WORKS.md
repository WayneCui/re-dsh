# How Harness-Spine Works

Most agent wrappers are a loop around a vendor SDK. They work until you ask a question the SDK does not answer: what did we actually do, can we stop without lying, and can two agents act without sharing a toolbox? harness-spine is a small Rebol runtime that treats those questions as the product. It hangs on the Cordis port's kernel — plugins, waterfalls, isolate, thenables — and then refuses to let the model own memory, I/O, or tools.

This book follows one dependency spine from a single echo turn to assembly and hot-swap. We do not start at the YAML file or the CLI flags. Those are how rooms get placed. The interesting machine is already running in `boot-spine` after a handful of `registry/plugin` calls: a host door, an append-only session log, a tools waterfall, a one-shot approval seam, an LLM guest, and a loop that rereads the log every step. Isolate rooms and cancel come next because they are how that machine stays honest when there is more than one occupant, or when an occupant must stop.

Two commands to start:

```bash
cd ch01-echo-turn/code && bash run.sh
./verify-all.sh
```

Source: [`../`](../) (**Rebol 3**). Labs `do %boot.reb` against that tree; they are not a fork. `run.sh` always sets CWD to the harness-spine root because `boot.reb` loads `../cordis-port` and sibling modules by relative path. If `r3` is not on `PATH`, `verify-all.sh` skips.

**Convention:** do not modify the original repo while reading. "Against the source" at each chapter end points at real paths. Teaching slices live under `chNN-*/code/` and print `LAB-OK` when they finish.

The conceptual, lab-free companion is [Harness for Everyone](../harness-for-everyone/README.md). The kernel this spine hangs on is explained in [How the Cordis Rebol Port Works](../../cordis-port/how-cordis-port-works/README.md).

```text
cordis-port kernel (ctx, plugin, waterfall, isolate)
  -> host            one I/O door
  -> session         append-only log; conversation is a view
  -> tools           pre / execute / post + tools-result
       -> shell      bash is a registered spec, not a loop primitive
  -> approval        one-shot, fail-closed, both sides in the log
  -> llm             guest: enqueue / script / http / echo
  -> agent-loop      a turn that rereads the log
  -> scope + agent   private acting rooms, shared front desk
  -> boot / yaml / reload
```

A user string enters `driver/run-turn`. The loop writes `turn-start` and a `user-message`, derives the model view, asks `llm/stream`, and writes chunks plus a final assistant row — or a tool-call, which is data until `tools/execute` runs the waterfall and host (if bash) performs the side effect. Approval may sit on that waterfall. Cancel is a flag checked at those same seams, then a `cancelled` tool-result so the log does not contain a ghost. Two agents isolate tools and loop but can share the session. Reload swaps a plugin fiber and refreshes handles so the next turn uses the new guest on the old notebook.

---

## Contents

- [Chapter 01 What Actually Happens When You Send "hello"?](./ch01-echo-turn/chapter.md)
- [Chapter 02 Why Must Every Side Effect Go Through One Door?](./ch02-host-door/chapter.md)
- [Chapter 03 Why Is Memory a Log, Not a Chat?](./ch03-session-log/chapter.md)
- [Chapter 04 Why Isn't a Tool Just a Function Call?](./ch04-tools-waterfall/chapter.md)
- [Chapter 05 Why Ask Once, Fail Closed, and Write Both Sides?](./ch05-approval-once/chapter.md)
- [Chapter 06 Why Isn't the Model in Charge?](./ch06-llm-guest/chapter.md)
- [Chapter 07 Why Does Every Step Reread the Log?](./ch07-the-turn/chapter.md)
- [Chapter 08 Why Give Each Agent Its Own Room?](./ch08-isolate-rooms/chapter.md)
- [Chapter 09 Why Is Stopping a Protocol, Not an Exception?](./ch09-cancel-protocol/chapter.md)
- [Chapter 10 Why Assemble and Hot-Swap Instead of Writing It Once?](./ch10-assemble-reload/chapter.md)

---

## How to read

If you only want the bet the repo is making, read Chapters 01, 03, and 07. That is one turn, the log/view split, and the clerk who refuses to cache a conversation. If you are debugging a tool that "ran twice" or "never ran," read 04 then 05. If two agents stepped on each other, start at 08. If a cancel left a half-written session, start at 09. Chapter 10 is for the reader who already believes the rooms exist and wants YAML, profiles, and `reload-spine-plugin`.

The kernel book is optional on the first pass. You need it when a waterfall listener's `nw/call` looks like superstition, or when reload seems to "not take" because a fiber epoch rebuilt a service object you still hold.

---

## Verify

```bash
./verify-all.sh
# expect: 10/10 OK
```

Requires `r3` (Rebol 3) on `PATH`. Lookup tables live in [appendix/quick-reference.md](./appendix/quick-reference.md). **Do not** start there; the chapters earn those one-liners.
