REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine

; ---- agent-request rewrites messages (pre-step unchanged) ----
rewrite-req: func [args [block!] /local req msgs] [
    req: args/3
    msgs: select req 'messages
    if block? msgs [
        foreach m msgs [
            if equal? select m 'role 'user [
                put m 'content rejoin ["[routed] " select m 'content]
            ]
        ]
    ]
    req
]
disp: spine/ctx/events/on 'agent-request 'rewrite-req make map! [] spine/ctx
s: spine/sessions/create
out: spine/driver/run-turn s/id "hello"
assert equal? 'text select out 'status "request rewrite still text"
assert equal? "[routed] hello" select out 'text "assistant sees routed user"
msgs: spine/sessions/derive-messages s/id
assert equal? "hello" select msgs/1 'content "session keeps original"
assert equal? "[routed] hello" select msgs/2 'content "assistant text is routed"

; ---- agent-request can swap the llm for this step ----
disp/dispose
alt-llm: make object! [
    stream: func [messages tool-specs /on-chunk sink /cancel cancel-obj /local r] [
        r: make map! []
        put r 'kind 'text
        put r 'text "from-alt"
        r
    ]
]
swap-req: func [args [block!] /local req] [
    req: args/3
    put req 'llm alt-llm
    req
]
disp2: spine/ctx/events/on 'agent-request 'swap-req make map! [] spine/ctx
s2: spine/sessions/create
out2: spine/driver/run-turn s2/id "ignored"
assert equal? "from-alt" select out2 'text "request swapped llm"

; ---- agent-request reject ----
disp2/dispose
reject-req: func [args [block!] /local m] [
    m: make map! []
    put m 'kind 'reject
    put m 'reason "no provider"
    m
]
disp3: spine/ctx/events/on 'agent-request 'reject-req make map! [] spine/ctx
s3: spine/sessions/create
out3: spine/driver/run-turn s3/id "nope"
assert equal? 'rejected select out3 'status "request rejected status"
types: copy []
foreach ev spine/sessions/events-of s3/id [append types select ev 'type]
assert not none? find types 'step-rejected "request reject logs step-rejected"
assert none? find types 'assistant-message "no assistant after request reject"

disp3/dispose
s4: spine/sessions/create
out4: spine/driver/run-turn s4/id "plain"
assert equal? "plain" select out4 'text "no listener still echoes"

shutdown-spine spine
finish-tests "loop-request-test"
