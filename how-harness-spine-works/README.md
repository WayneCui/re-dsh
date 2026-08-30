# How Harness-Spine Works

A ten-chapter executable book for [harness-spine](../): a minimal agent runtime on the Cordis Rebol port. Each chapter answers one reader question, runs a lab against the real tree, and points back at source symbols.

This is the source-traced edition. If you want the same spine as prose without Rebol labs, start at [Harness for Everyone](../harness-for-everyone/README.md). If you want the kernel (`Context`, fiber epochs, waterfall, isolate), start at [How the Cordis Rebol Port Works](../../cordis-port/how-cordis-port-works/README.md).

```bash
cd ch01-echo-turn/code && bash run.sh
```

From the book root:

```bash
./verify-all.sh
```

The continuous preface and map live in [HOW_HARNESS_SPINE_WORKS.md](./HOW_HARNESS_SPINE_WORKS.md).

Source under study: `../` (**Rebol 3**). Teaching language matches the source. Labs are not a Python or TypeScript rewrite.

```text
cordis-port kernel
  -> host -> session -> tools (+ shell) -> approval
  -> llm -> agent-loop -> scope/agent
  -> boot / yaml / reload
```

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

## How to read

Read in order the first time: Chapter 01 boots the whole machine so later layers have a turn to hang on. If you are already comfortable with echo-turn and want the counterintuitive core, skip to 03, 04, 07, 08, and 09. Chapter 10 is assembly; it will feel empty if you have not seen isolate and reload's reason to exist.

## Environment

- `r3` on `PATH` (this tree is exercised with Rebol/Core 3.21).
- Labs must run via `chNN-*/code/run.sh` (CWD becomes the harness-spine root). Running `r3 -s demo.reb` from the `code/` directory will fail to open `%boot.reb`.
- Optional: `bash test/run-all.sh` in the parent repo is the product's own suite; it is stricter than these teaching slices. Chapter 07 and `test/session-fork-test.reb` both follow `can-admit-turn?`: a lone user-message is `no-input`.

## Conventions

- Do not edit `../boot.reb` or module `api.reb` files to make a lab pass. Change `demo.reb`.
- Expected output in each chapter is copied from a real `run.sh` on this tree. Rebol prints logic as `#(true)` / `#(false)` and `none` as `_`.
- Isolate plugins (`tools`, `shell`, `agent-loop`) are installed by `create-agent-handle`, not by root `cordis.yml`.

Lookup tables: [appendix/quick-reference.md](./appendix/quick-reference.md).
