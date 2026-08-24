REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

; Phase 6.3: reload cooperates with turns.
spine: boot-spine
agent: spine/default-agent
s: spine/sessions/create

; ---- inbox carries over when the agent-loop plugin is reloaded ----
spine/driver/followup "queued before reload"
r: reload-agent-plugin agent "agent-loop" %test/fixtures/loop-plugin-rebuilt.reb
assert equal? true r "loop plugin reload ok"
assert not same? r false "reload returned true"
new-driver: agent/driver
assert equal? 1 length? new-driver/inbox-next-turn "followup carried to new driver"

; The carried followup still drives a turn
out: spine/driver/run-turn s/id none
assert equal? 'text select out 'status "carried followup runs"
assert equal? "queued before reload" select out 'text "carried followup text"

; ---- reload from inside a live turn cancels that turn cooperatively ----
; The ping tool v-reload swaps itself mid-turn; the turn must end cancelled.
self-reloader: make object! [
    name: "self-reloader"
    inject: [tools]
    apply: func [ctx [object!] config /local tools] [
        tools: ctx/reflect/get 'tools true ctx
        tools/register make object! [
            name: 'swap-self
            description: "reloads ping-tool mid-turn"
            run: make object! [
                call: func [args /local m rr] [
                    rr: reload-agent-plugin test-agent "ping-tool" %test/fixtures/ping-tool-v2.reb
                    m: make map! []
                    put m 'ok true
                    put m 'text rejoin ["reload=" mold rr]
                    m
                ]
            ]
        ]
        none
    ]
]
agent/ctx/registry/plugin (do %test/fixtures/ping-tool-v1.reb) none agent/ctx
test-agent: agent
agent/ctx/registry/plugin self-reloader none agent/ctx

c1: make map! []
put c1 'kind 'tool-call
put c1 'name 'swap-self
put c1 'args make map! []
spine/llm/enqueue c1
; No follow-up reply queued: the turn must stop at the post-tool checkpoint,
; leaving the script queue empty for the next turn.

out2: spine/driver/run-turn s/id "swap the tool"
assert equal? 'cancelled select out2 'status "reload mid-turn cancels the turn"

; New plugin is live for the next turn
c2: make map! []
put c2 'kind 'tool-call
put c2 'name 'ping
put c2 'args make map! []
spine/llm/enqueue c2
fin2: make map! []
put fin2 'kind 'text
put fin2 'text "after swap"
spine/llm/enqueue fin2
out3: spine/driver/run-turn s/id "ping after swap"
assert equal? 'text select out3 'status "turn after mid-turn reload ok"
found-v2: false
foreach ev spine/sessions/events-of s/id [
    if equal? select ev 'type 'tool-result [
        if equal? select (select ev 'payload) 'text "pong v2" [found-v2: true]
    ]
]
assert found-v2 "v2 live after mid-turn reload"

; ---- idle reload does not touch cancel state ----
assert none? spine/driver/cancel-turn "idle cancel is a no-op"
r3: reload-agent-plugin agent "ping-tool" %test/fixtures/ping-tool-v1.reb
assert equal? true r3 "idle reload ok"
assert equal? false spine/driver/cancel-requested "no sticky cancel flag"

shutdown-spine spine
finish-tests "reload-turn-test"
