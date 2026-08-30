# Harness for Everyone

Most explanations of an agent runtime begin by assuming that you already enjoy reading harness code. This booklet does not make that assumption. It is for the reader who wants to understand what harness-spine is trying to protect: a machine that can talk, act, remember, and be stopped without lying about any of those four.

This is a **prose-only** edition. By request, it does **not** include runnable labs or `verify-all.sh`. The runnable life of the project is the real repo: `examples/` and `test/run-all.sh` in [..](file:///Users/wayne/2-learning/agent-projects/harness-spine). For the kernel this spine hangs on, the gentler companion is [Cordis for Everyone](file:///Users/wayne/2-learning/agent-projects/cordis/cordis-for-everyone/CORDIS_FOR_EVERYONE.md).

It is a good fit if you are:

- curious about how an agent stays honest without wanting the API tour first;
- technical-adjacent rather than deeply technical;
- trying to understand the *point* of the spine before deciding whether to read Rebol.

It is not the best first stop if you mainly want:

- a module-by-module reference;
- runnable code slices;
- implementation details before the conceptual picture.

Begin here:

- [HARNESS_FOR_EVERYONE.md](./HARNESS_FOR_EVERYONE.md)
- [appendix/quick-reference.md](./appendix/quick-reference.md)

Source under study: `../` (Rebol 3), especially `host/`, `session/`, `tools/`, `approval/`, `llm/`, `agent-loop/`, `scope/`, `agent/`, `boot.reb`, `boot-yaml.reb`, and `profile.reb`. The kernel is `../../cordis-port`.

```text
the human spine
   -> an agent is not a loop around a model
   -> the real world needs one door
   -> memory is a log, conversation is a view
   -> a tool is a public act with witnesses
   -> permission fails closed and only once
   -> the model is a guest
   -> a turn rereads the log
   -> acting rooms stay private
   -> stopping is a protocol
   -> assembly and reload must honor history
```

## Contents

- [Chapter 01 Why Isn't an Agent Just a Loop Around a Model?](./HARNESS_FOR_EVERYONE.md#chapter-01-why-isnt-an-agent-just-a-loop-around-a-model)
- [Chapter 02 Why Keep the Real World Behind One Door?](./HARNESS_FOR_EVERYONE.md#chapter-02-why-keep-the-real-world-behind-one-door)
- [Chapter 03 Why Is Memory a Log, Not a Chat?](./HARNESS_FOR_EVERYONE.md#chapter-03-why-is-memory-a-log-not-a-chat)
- [Chapter 04 Why Must Every Tool Pass Through Gates?](./HARNESS_FOR_EVERYONE.md#chapter-04-why-must-every-tool-pass-through-gates)
- [Chapter 05 Why Ask Before Acting?](./HARNESS_FOR_EVERYONE.md#chapter-05-why-ask-before-acting)
- [Chapter 06 Why Isn't the Model in Charge?](./HARNESS_FOR_EVERYONE.md#chapter-06-why-isnt-the-model-in-charge)
- [Chapter 07 Why Is a Turn a Conversation With Itself?](./HARNESS_FOR_EVERYONE.md#chapter-07-why-is-a-turn-a-conversation-with-itself)
- [Chapter 08 Why Give Each Agent Its Own Room?](./HARNESS_FOR_EVERYONE.md#chapter-08-why-give-each-agent-its-own-room)
- [Chapter 09 Why Does Stopping Matter as Much as Starting?](./HARNESS_FOR_EVERYONE.md#chapter-09-why-does-stopping-matter-as-much-as-starting)
- [Chapter 10 Why Assemble the Spine Instead of Writing It Once?](./HARNESS_FOR_EVERYONE.md#chapter-10-why-assemble-the-spine-instead-of-writing-it-once)

## How to Read

If you mostly care about the big promise, read chapters 1, 3, and 9. If you care about how acting is kept from becoming a private side effect, read chapters 2, 4, and 5 together. If you are trying to understand why an agent is more than a model, chapters 6, 7, and 8 are the quiet center. Chapter 10 is for the reader who already believes the rooms exist and wants to know how they get placed, overlaid, and swapped.

One suggestion helps: do not try to memorize the identifiers on first pass. Let the images do the work first. Harness-spine makes more sense as a sequence of promises than as a pile of services. Read it the way you would read a short essay collection: slowly, and with room for the pattern to emerge.
