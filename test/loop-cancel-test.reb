REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
driver: spine/driver
sessions: spine/sessions

has-type?: func [types [block!] t [word!]] [
    not none? find types t
]

; ---- idle cancel is a no-op ----
assert none? driver/cancel-turn "idle cancel returns none"
assert equal? false driver/cancel-requested "idle cancel does not sticky-flag"

; ---- tool requests cancel mid-turn ----
cancel-tool: make object! [
    name: 'abort
    description: "cancels the live turn"
    run: make object! [
        drv: driver
        call: func [args /local m] [
            drv/cancel-turn
            m: make map! []
            put m 'ok true
            put m 'text "abort-body"
            m
        ]
    ]
]
spine/tools/register cancel-tool

tc: make map! []
put tc 'kind 'tool-call
put tc 'name 'abort
put tc 'args make map! []
spine/llm/enqueue tc
follow: make map! []
put follow 'kind 'text
put follow 'text "should-not-run"
spine/llm/enqueue follow

s: sessions/create
out: driver/run-turn s/id "please abort"
assert equal? 'cancelled select out 'status "turn status cancelled"
assert equal? false driver/cancel-requested "flag cleared after turn"

evs: sessions/events-of s/id
types: copy []
foreach ev evs [append types select ev 'type]
assert has-type? types 'turn-start "has turn-start"
assert has-type? types 'tool-call "has tool-call"
assert has-type? types 'tool-result "has tool-result (no hang)"
assert has-type? types 'turn-end "has turn-end"
assert equal? false has-type? types 'assistant-message "no follow-up assistant after cancel"

tr: none
foreach ev evs [
    if equal? select ev 'type 'tool-result [
        tr: select ev 'payload
    ]
]
assert map? tr "tool-result payload present"
assert equal? true select tr 'cancelled "tool-result marked cancelled"

s2: sessions/create
out2: driver/run-turn s2/id "next"
assert equal? 'text select out2 'status "next turn ok after cancel"

; ---- cancel during delayed settle ----
delay-tool: make object! [
    name: 'slow
    description: "returns delayed thenable after requesting cancel"
    run: make object! [
        drv: driver
        host-ref: spine/host
        call: func [args] [
            drv/cancel-turn
            host-ref/delay 20 "late"
        ]
    ]
]
spine/tools/register delay-tool
tc2: make map! []
put tc2 'kind 'tool-call
put tc2 'name 'slow
put tc2 'args make map! []
spine/llm/enqueue tc2

s3: sessions/create
out3: driver/run-turn s3/id "go slow"
assert equal? 'cancelled select out3 'status "delayed settle cancelled"
evs3: sessions/events-of s3/id
tr3: none
foreach ev evs3 [
    if equal? select ev 'type 'tool-result [
        tr3: select ev 'payload
    ]
]
assert equal? true select tr3 'cancelled "delayed path cancelled tool-result"

; ---- dispose while idle still rejects later turns ----
agent-x: spine/agents/create "X"
s4: sessions/create
spine/agents/dispose agent-x
out4: agent-x/driver/run-turn s4/id "after dispose"
assert equal? 'disposed select out4 'status "disposed rejects new turn"

shutdown-spine spine
finish-tests "loop-cancel-test"
