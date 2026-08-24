REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine

; ---- pre-step rejects: turn closes with status rejected ----
reject-listener: func [args [block!] /local m] [
    m: make map! []
    put m 'kind 'reject
    put m 'reason "not now"
    m
]
reject-disp: spine/ctx/events/on 'agent-pre-step 'reject-listener make map! [] spine/ctx
s: spine/sessions/create
out: spine/driver/run-turn s/id "hello"
assert equal? 'rejected select out 'status "pre-step rejected status"
assert equal? 1 select out 'steps "rejected at step 1"
assert equal? "" select out 'text "no assistant text"
evs: spine/sessions/events-of s/id
types: copy []
foreach ev evs [append types select ev 'type]
assert not none? find types 'step-rejected "step-rejected logged"
assert none? find types 'assistant-message "no assistant after reject"

; ---- pre-step rewrites messages ----
reject-disp/dispose
rewrite-listener: func [args [block!] /local msgs] [
    msgs: args/3
    if block? msgs [
        foreach m msgs [
            if equal? select m 'role 'user [
                put m 'content rejoin ["[rewritten] " select m 'content]
            ]
        ]
    ]
    msgs
]
rewrite-disp: spine/ctx/events/on 'agent-pre-step 'rewrite-listener make map! [] spine/ctx
s2: spine/sessions/create
out2: spine/driver/run-turn s2/id "original"
assert equal? 'text select out2 'status "rewrite still ends text"
assert equal? "[rewritten] original" select out2 'text "assistant echoes rewritten user"
msgs2: spine/sessions/derive-messages s2/id
assert equal? "original" select msgs2/1 'content "session keeps original"
assert equal? "[rewritten] original" select msgs2/2 'content "assistant sees rewrite"

; ---- pre-step passes through by default ----
rewrite-disp/dispose
s3: spine/sessions/create
out3: spine/driver/run-turn s3/id "plain"
assert equal? 'text select out3 'status "no listener still works"
assert equal? "plain" select out3 'text "echo unchanged"

shutdown-spine spine
finish-tests "loop-pre-step-test"
