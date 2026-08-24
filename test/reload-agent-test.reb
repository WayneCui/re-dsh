REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

; Phase 6.2: reload an agent-isolate plugin while root services stay put.
spine: boot-spine
s: spine/sessions/create

; Mount ping-tool v1 on the default agent's isolate ctx
agent: spine/default-agent
agent/ctx/registry/plugin (do %test/fixtures/ping-tool-v1.reb) none agent/ctx

; Drive a turn that uses ping v1
c1: make map! []
put c1 'kind 'tool-call
put c1 'name 'ping
put c1 'args make map! []
spine/llm/enqueue c1
fin1: make map! []
put fin1 'kind 'text
put fin1 'text "v1 done"
spine/llm/enqueue fin1
out1: spine/driver/run-turn s/id "ping please"
assert equal? 'text select out1 'status "v1 turn ends text"
log-before: spine/sessions/events-snapshot s/id
assert not empty? log-before "session has events before reload"

; Root service identity captured before reload
sessions-before: spine/sessions
llm-before: spine/llm

; ---- reload the agent plugin: v1 -> v2 ----
r: reload-agent-plugin agent "ping-tool" %test/fixtures/ping-tool-v2.reb
assert equal? true r "reload-agent-plugin ok"

; Live resources protected: root services are the same objects
assert same? sessions-before spine/sessions "sessions service untouched"
assert same? llm-before spine/llm "llm service untouched"
log-after: spine/sessions/events-snapshot s/id
assert equal? length? log-before length? log-after "session log intact"
assert equal? mold log-before mold log-after "session log identical"

; New behavior live: ping now answers v2
c2: make map! []
put c2 'kind 'tool-call
put c2 'name 'ping
put c2 'args make map! []
spine/llm/enqueue c2
fin2: make map! []
put fin2 'kind 'text
put fin2 'text "v2 done"
spine/llm/enqueue fin2
out2: spine/driver/run-turn s/id "ping again"
assert equal? 'text select out2 'status "v2 turn ends text"
found-v2: false
foreach ev spine/sessions/events-of s/id [
    if equal? select ev 'type 'tool-result [
        if equal? select (select ev 'payload) 'text "pong v2" [found-v2: true]
    ]
]
assert found-v2 "tool result from v2"

; ---- sibling agent unaffected ----
other: spawn-agent spine "other"
other/ctx/registry/plugin (do %test/fixtures/ping-tool-v1.reb) none other/ctx
os: spine/sessions/create
oc: make map! []
put oc 'kind 'tool-call
put oc 'name 'ping
put oc 'args make map! []
spine/llm/enqueue oc
ofin: make map! []
put ofin 'kind 'text
put ofin 'text "other done"
spine/llm/enqueue ofin
oout: other/driver/run-turn os/id "ping from other"
assert equal? 'text select oout 'status "other agent turn ok"
found-v1: false
foreach ev spine/sessions/events-of os/id [
    if equal? select ev 'type 'tool-result [
        if equal? select (select ev 'payload) 'text "pong v1" [found-v1: true]
    ]
]
assert found-v1 "sibling still on v1"

; ---- failed reload keeps old plugin and live resources ----
r2: reload-agent-plugin agent "ping-tool" %test/fixtures/does-not-exist.reb
assert string? r2 "missing file error"
c3: make map! []
put c3 'kind 'tool-call
put c3 'name 'ping
put c3 'args make map! []
spine/llm/enqueue c3
fin3: make map! []
put fin3 'kind 'text
put fin3 'text "still v2"
spine/llm/enqueue fin3
out3: spine/driver/run-turn s/id "ping once more"
assert equal? 'text select out3 'status "turn after failed reload ok"
still-v2: false
foreach ev spine/sessions/events-of s/id [
    if equal? select ev 'type 'tool-result [
        if equal? select (select ev 'payload) 'text "pong v2" [still-v2: true]
    ]
]
assert still-v2 "v2 survives failed reload"

shutdown-spine spine
finish-tests "reload-agent-test"
