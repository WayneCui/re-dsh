# Harness for Everyone

Harness-spine is an agent runtime, but what matters most about it is not technical at first. It is a promise about honesty. A machine that can talk, act, remember, and be stopped should not be allowed to lie about any of those four. The model should not pretend it owns the world. The chat the model sees should not pretend to be the whole record. A tool should not pretend it ran when it was refused. Stopping should not pretend it is already finished.

That is the spine. It hangs on the same kernel that Cordis uses for plugins, fibers, and cleanup — here, the Rebol port in [cordis-port](file:///Users/wayne/2-learning/agent-projects/cordis-port). Cordis asks how many moving parts can share one world without tearing it. Harness-spine asks a narrower, more dangerous question: how can one of those parts be allowed to *act*, and still leave the others a coherent picture of what happened.

This booklet is for the reader who wants that idea before the machinery. We will still point to the real source, because a harness is not interesting as a metaphor alone. But we will read it as a story about doors, records, permission, and stopping rather than as a dictionary of services.

That leaves us with one practical rule for reading: whenever a name starts to feel heavy, translate it back into a human question. `host` is about the real world. `session` is about the record. `tools` is about witnesses. `approval` is about permission. `llm` is about a guest. `agent-loop` is about a turn. `scope` is about which room an event belongs to. Once the questions are clear, the names stop feeling cold.

```text
small promise
   -> do not let the model own the world
   -> do not confuse a conversation with the record of one
   -> do not let a tool run without witnesses
   -> do not treat permission as decoration
   -> do not share rooms by accident
   -> do not pretend stopping is already done
   -> do not assemble by wishful hard-coding
   -> do not reload by trampling the living conversation
```

The technical life of this project lives in runnable examples under `examples/` and in the tests. This edition does something gentler. It asks what kind of agent world harness-spine is trying to create, and why a spine would care so much about being careful.

---

## Chapter 01 Why Isn't an Agent Just a Loop Around a Model?

The easiest way to imagine an agent is as a polite while-loop. Ask the model. If it wants a command, run the command. Paste the output back. Repeat until it says something in English. The image is attractive because it feels like how a person actually works: think, do, look, think again.

The room does not stay polite for long. Soon the "conversation" is a mutable array that someone edited after the fact. A second agent inherits the first agent's shell. Cancel is `kill -9` plus hope. Reload is a restart that forgets why you were here. None of these failures feel like model problems. They feel like the world going out of joint while the model keeps talking as if nothing happened.

Harness-spine answers this at the front door by refusing to be one file. In [ARCHITECTURE.md](file:///Users/wayne/2-learning/agent-projects/harness-spine/ARCHITECTURE.md), the product is a directed chain: `host` for real I/O, `session` for the log, `approval` for permission, `tools` for the witnessed call, `llm` for answers, `agent-loop` for a turn, `agent` for live bodies. [boot.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb) does not invent a new kernel. It mounts those plugins onto a Cordis context and then, only after the shared services exist, creates a default agent handle.

You can see the order in [boot-spine](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L133-L165). The root gets `host`, `session`, `approval`, `llm`, and `agents`. The default agent's tools and loop are not hung on that root. They come later from `create-agent-handle`. That is already a moral choice dressed as boot order: the shared world is assembled first; the acting body is a guest of that world, not its owner.

## Wrap-up

The first thing harness-spine protects is not cleverness. It is the right to give talking, acting, remembering, and stopping different homes. The common misunderstanding is to think the spine is "a chatbot with plugins." It is closer to a set of rooms with one job each, so that no job is allowed to impersonate another.

---

## Chapter 02 Why Keep the Real World Behind One Door?

Once you admit that an agent may act, the next temptation is to let whoever is holding the conversation reach the operating system directly. The loop could call `shell`. The model adapter could `curl`. A tool could sleep by spinning. Each of those shortcuts works in a demo. Each of them makes cancel, testing, and honesty harder, because the real world now has several unofficial doors.

That is why [host/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/host/api.reb) exists. `host` is the I/O exit: `run-command`, `http-get`, `http-post`, `http-post-stream`, `delay`. It does not know what a tool is. It does not write session events. It does not parse model replies. In [run-command](file:///Users/wayne/2-learning/agent-projects/harness-spine/host/api.reb#L96-L113), a string becomes a waited shell call and comes back as `ok`, `code`, `stdout`, and `stderr`. Nothing more.

The `bash` tool is not a friend of the loop. In [shell/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/shell/api.reb#L30-L38), `shell-plugin` injects `tools` and `host`, registers one spec named `bash`, and leaves. If the command string is missing, it does not touch `host` at all. The loop will later call `tools/execute`. It will not spawn a process. That indirection is the point. Side effects are supposed to happen in one place, or not at all.

This costs some warmth. A one-file agent feels closer to the metal. The spine would rather you feel a door closing than discover, after a failed cancel, that a curl process is still writing into a conversation that officially ended.

## Wrap-up

Harness-spine treats the real world as something you exit toward, not something every layer may casually touch. The easy wrong reading is "`host` is just a shell helper." The right reading is stricter: if acting is a privilege, it needs a single door, so that stopping and testing have somewhere to stand.

---

## Chapter 03 Why Is Memory a Log, Not a Chat?

Most chat products train us to think of memory as the array the widget displays. Messages are appended, sometimes edited, sometimes dropped when a token budget gets tight. That is a view. It is a dangerous thing to treat as the ground truth, because a view can be rebuilt to look kind. A log cannot.

In [session/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/session/api.reb), a session is an append-only event log. `append-event` validates the type, snapshots the payload so later mutation cannot rewrite history, commits the row, emits `session-event`, and may flush to disk. The snapshot lives in [json.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/session/json.reb#L57-L63): what is stored is a JSON-safe copy, not a live object you still hold in your hand.

What the model sees is not that log. `derive-messages` is a read-only projection. Consecutive `assistant-chunk` rows fold into one assistant turn. If a final `assistant-message` follows, the chunks lose: the finished sentence is the truth. That rule is written in the open in [derive-messages](file:///Users/wayne/2-learning/agent-projects/harness-spine/session/api.reb#L368-L445). Tool calls and tool results become their own rows. Approval events can sit in the same log without pretending to be chat.

This is why `fork` copies a prefix into a new id and then lets the branches diverge, and why `open` can restore a session from `store-dir` and still produce the same derived messages. The conversation is not a cache inside the loop. It is a record the loop is required to reread. The cost is ceremony. The reward is that nobody gets to gaslight the future by editing the past.

## Wrap-up

Harness-spine keeps a ledger of what happened and only then paints a conversation on top of it. The usual mistake is to think `derive-messages` *is* the memory. It is a view. The memory is the log; the view is what a guest is allowed to see.

---

## Chapter 04 Why Must Every Tool Pass Through Gates?

If a tool is just a function, the honest implementation is to call it. Harness-spine refuses that politeness. A tool call is a public act. It can be denied before it happens, rewritten after it happens, or observed by someone who did not run it. Those are different jobs, so they are not crammed into one callback.

In [tools/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/tools/api.reb), `execute` is a three-layer waterfall and then an emit. `tools-pre-execute` may `allow`, `deny`, or `ask`. Only after that does `tools-execute` run the body. `tools-post-execute` may still rewrite stdout or block the result. Then `tools-result` is emitted so the rest of the system can watch a frozen outcome. Even an unknown name does not vanish. It still emits a deny result. The gap in the registry is not allowed to become a gap in the record.

Registration itself is not a sticky note. `register` attaches a fiber `effect`, so when the owning fiber is disposed the tool name is withdrawn. That is Cordis cleanup showing up in a place that looks like a dictionary. The tools table is a lease, not a global forever.

The cost is that "just run it" is no longer a one-liner. The gain is that policy, execution, and observation can disagree with each other without forging the outcome. A pre-deny never reaches the inner body. A missing tool still leaves a witness.

## Wrap-up

A tool here is not a function you happen to have in scope. It is a public act that must be allowed, performed, and recorded as three separate moments. The common misunderstanding is to hear "waterfall" and think of middleware fashion. In this design the waterfall is how the spine keeps acting from becoming a private side effect.

---

## Chapter 05 Why Ask Before Acting?

Once tools have gates, permission still needs a place to live. Many systems treat that as a UI problem, or as a sticky grant that lasts forever once a human has said yes. Harness-spine is less trusting. Approval is a seam, not a product. It has no built-in human window and no `allow-always` store. Missing answerers fail closed.

In [approval/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/approval/api.reb), `request` will not even run outside an open turn. That sounds fussy until you notice what it prevents: a tool asking for permission against a conversation that is not currently happening. Inside a turn, the service appends `approval-asked`, then either rejects because policy is `never`, or asks the `approval-request` waterfall. The default inner answer is `unavailable`. Afterward it appends `approval-decided`. Both events sit in the session log, so permission is part of history, not a whisper in a sidebar.

Tools reach this seam in two ways. A spec may carry `approval: 'ask`. A `tools-pre-execute` listener may return `{kind: ask}`. In [resolve-approval-ask](file:///Users/wayne/2-learning/agent-projects/harness-spine/tools/api.reb#L50-L79), no approval service, no session id, a rejection, a cancel, or unavailability all become a deny result. Only `allowed-once` lets the body run. The name is doing work: once, not always.

This is one of the places where the spine feels severe. It would rather disappoint a tool than invent a human who said yes.

## Wrap-up

Permission in harness-spine is a one-shot question asked in public, during a living turn, with failure meaning no. The easy wrong reading is "approval is a settings checkbox." The right reading is that acting on the world is supposed to be interruptible, audible, and slightly inconvenient.

---

## Chapter 06 Why Isn't the Model in Charge?

It is easy to build an agent as if the language model were the protagonist. Everything else becomes scenery: a prompt, a toolkit, a transcript the model is "using." Harness-spine inverts that. The model is a guest. It is given messages and tool specs. It returns text or a tool call. It may stream deltas. It does not write the log. It does not execute bash. It does not own the session.

In [llm/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/llm/api.reb), `complete` and `stream` share `resolve-reply`. The adapters are a short, strict ladder: a test queue (`enqueue`) first, then a `script`, then `http-url`, then a humble echo of the last user content. HTTP streaming has its own line protocol of deltas and a final `kind` row, and it can be aborted. When there is no HTTP stream, `stream` still accepts a sink and a cancel object so the rest of the spine does not have to care which adapter is answering.

The loop, not the model, decides what those deltas mean for history. In [agent-loop/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/agent-loop/api.reb#L382-L401), each streamed chunk becomes an `assistant-chunk` row, and only then does a finished `assistant-message` or a `tool-call` land. If you unplug the model, the log remains a log. If you swap the adapter, the guest changes; the house does not.

That is a loss of romance. The gain is that "the model said so" is never allowed to become "therefore it happened."

## Wrap-up

The language model here is an oracle you can interrupt, not a manager with keys to the building. The usual mistake is to treat `llm` as the agent. The agent is the turn, the log, and the doors. `llm` is the voice that gets asked a question at a particular step.

---

## Chapter 07 Why Is a Turn a Conversation With Itself?

A single model call is not an agent. An agent is what happens when an answer may be an action, and the action must be told back to the same conversation, and the next question must not be allowed to remember a private version of events. That loop is easy to fake with a local array. Harness-spine refuses the fake.

In [run-turn-core](file:///Users/wayne/2-learning/agent-projects/harness-spine/agent-loop/api.reb#L286-L451), a turn starts by writing `turn-start`. It may claim inbox messages and write them as durable `user-message` rows. Unless this is a resume, it writes the caller's user text too. Then, step by step, it rebuilds model input with `sessions/derive-messages`. There is no side cache. `agent-pre-step` may rewrite or reject that proposal. `agent-request` may still change the messages, the tool list, or even which `llm` object is used. Only then does `stream` run. A tool call is logged before it is executed; a tool result is logged before the next step. A text reply ends the turn. Too many steps end it as `max-steps`.

`resume-turn` is the same machine without a new user sentence. That matters after a reload, a cancel, or a tool result that was left hanging. The conversation continues from the log, not from whatever the previous process still had in RAM.

The inbox is how the outside world joins without punching a hole. `followup` waits for the next turn. `steer` and `inject` wait for the next step. Claimed text becomes ordinary user messages. The model never receives a secret channel. It only ever sees what the log is willing to project.

## Wrap-up

A turn is the spine talking to itself through the log: write, reread, ask, perhaps act, write again. The common misunderstanding is to think the loop "has" the messages. It does not. It is required to ask the session, every step, what the conversation currently is.

---

## Chapter 08 Why Give Each Agent Its Own Room?

If two agents share one tools table, they share one idea of `bash`, one set of pre-execute policies, and one chance to step on each other's registrations. If they share no events at all, a parent cannot tell when a child has done something. Harness-spine wants both separations: private acting rooms, shared memory and voice, and events that know which room they came from.

That is what [create-agent-handle](file:///Users/wayne/2-learning/agent-projects/harness-spine/scope/api.reb#L132-L168) does. It mints an opaque scope key, optionally binds a parent, then `extend`s the root so that `tools`, `shell`, and `agent-loop` are isolated under a per-agent label. Those three plugins are installed on the isolated context. `sessions` and `llm` stay on the root. The handle is an object whose `run-turn` and inbox methods delegate to the current `driver`, so a later reload can swap the loop without forcing callers to find a new object.

Events use that key as a filter. [make-scope-target](file:///Users/wayne/2-learning/agent-projects/harness-spine/scope/api.reb#L113-L119) carries a `filter` that admits a listener when the dispatch key sits on the listener's ancestor chain. A listener with no scope hears everyone. A child event can bubble to a parent. A sibling cannot eavesdrop by standing nearby. `tools-result` and `session-event` travel this way, which is how a parent room can watch without sharing a toolbox.

The cost is that "the" tools service is no longer a global. A disappearing `bash` may simply belong to another agent. The reward is that acting can be local while remembering and speaking remain common goods.

## Wrap-up

An agent here is a private workshop attached to a shared library and a shared voice. The easy wrong reading is "one process, so one tools table." The right reading is that the things which act should be isolated, and the things which remember and speak may still be shared, as long as events know which workshop they left.

---

## Chapter 09 Why Does Stopping Matter as Much as Starting?

Starting an agent is the part demos enjoy. Stopping is the part that decides whether anyone else can trust the system. If cancel means "we pulled the plug," then the log ends in silence, a curl may keep running, and the next turn has to guess. Harness-spine treats stopping as a protocol, not as a power switch.

`cancel-turn` does not kill the world. In [agent-loop/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/agent-loop/api.reb#L258-L267), it sets `cancel-requested` if a live session exists, and returns `none` when idle so a stale flag cannot haunt the next turn. The loop and the tools `settle` helpers check that flag on scheduler ticks. The LLM `stream` cancel object reads the same question. `host/http-post-stream` checks it per line and per poll, and will `kill` a curl pid. When a tool is caught in the middle, the log still receives a `tool-result` whose text is `cancelled`. The turn ends with `status: cancelled`. The conversation is allowed to know that it was interrupted.

Dispose is stricter about order. In [agent/api.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/agent/api.reb#L59-L70), `dispose` calls `cancel-turn` first, emits `agent-disposed`, removes the handle from the live table, and only then releases the isolate fibers. After that, `run-turn` and `resume-turn` return `status: disposed`. [shutdown-spine](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L23-L36) disposes every live agent before disposing the root fiber. Cleanup is a sequence, not a hope that garbage collection will notice.

This is cooperative, not preemptive. A tool body that never returns to `settle` can still ignore the flag. The spine is honest about that limit. It will not sell you a kill switch it does not have. It will sell you checkpoints, records, and an order of operations.

## Wrap-up

Stopping is part of the truth of a turn. The usual mistake is to think cancel is an implementation detail for impatient users. Here it is a promise: interruption should leave a coherent log, close the real-world door as far as the checkpoints allow, and refuse to keep acting after the body has been told to leave.

---

## Chapter 10 Why Assemble the Spine Instead of Writing It Once?

If the spine is a set of rooms, someone still has to place the furniture. The naive way is to hard-code `boot-spine` and call it the product. That works until you want a smaller machine, a local overlay, or a plugin swap that does not throw away the conversation. Assembly is not packaging. It is how a living system admits that it will be composed more than once.

[boot-spine](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L133-L165) is the code-shaped door: `registry/plugin` in a fixed order, then a default agent. [boot-yaml.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot-yaml.reb) is the file-shaped door. [cordis.yml](file:///Users/wayne/2-learning/agent-projects/harness-spine/cordis.yml) lists the root plugins and says, in a comment, what it will not list: tools, shell, and agent-loop still come from `create-agent-handle`. Profiles go further. In [profile.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/profile.reb#L29-L54), layers stack as bundle, then profile patch, then home (`HARNESS_HOME/cordis.patch.reb` or the repo's `cordis.patch.reb`), then `--patch`. `profiles/minimal` matches the root YAML. `profiles/full` matches the richer example chain. The lived world is the composed entry list, not whichever file you happened to open first.

Reload is assembly happening again while people are still in the building. [reload-spine-plugin](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L103-L131) first asks every live turn to cancel, then swaps a root plugin such as `llm` through Cordis `reload-plugin`, then refreshes every agent handle's `tools` and `driver` and carries the pending inbox across. [reload-agent-plugin](file:///Users/wayne/2-learning/agent-projects/harness-spine/boot.reb#L83-L101) does the same under one isolate, leaving root services and the session log untouched. If the new plugin cannot stand, the old one remains. The demo in [reload-llm.reb](file:///Users/wayne/2-learning/agent-projects/harness-spine/examples/reload-llm.reb) is almost blunt about the point: same session, new guest, history intact, missing file rolls back.

The cost is that "the program" is no longer a single story you can read from `main`. The gain is that configuration, overlay, and hot swap become the same family of act: placing rooms without pretending the conversation started today.

## Wrap-up

The spine is assembled, and therefore it can be assembled again. The easy wrong reading is that YAML is a nicer `boot-spine`, and reload is a developer convenience. The better reading is that both are ways of changing the machine without rewriting the record the machine is supposed to honor.

---

## Closing

If you step back from the symbols, harness-spine is a runtime about restraint in the presence of action. It does not assume that a model should hold the keys, that a chat widget is a sufficient memory, that a function call is a sufficient tool, that permission can be a sticky note, that two agents can share a workshop by accident, or that stopping will somehow take care of itself. That is why it can feel severe. The severity serves a gentler outcome: when something talks, acts, remembers, or stops, the others should not have to guess which story is true.

That is also why the spine rewards slow reading. Under the surface it is not only teaching how to wire an agent. It is teaching what kind of promises are worth making once a program is allowed to touch the world.

If this booklet has done its work, the runtime should now feel a little less like a stack of Rebol services and a little more like a set of social rules for an unstable guest. That is a good place to stop. The examples and tests can take over from here, once the questions are alive.
