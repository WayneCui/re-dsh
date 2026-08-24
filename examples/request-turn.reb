REBOL []

; agent/request demo: last rewrite before the LLM call (can swap provider).
; Run from harness-spine/: r3 -s examples/request-turn.reb

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine

route-listener: func [args [block!] /local req msgs] [
    req: args/3
    msgs: select req 'messages
    if block? msgs [
        foreach m msgs [
            if equal? select m 'role 'user [
                put m 'content rejoin ["[via-request] " select m 'content]
            ]
        ]
    ]
    req
]
spine/ctx/events/on 'agent-request 'route-listener make map! [] spine/ctx

s: spine/sessions/create
out: spine/driver/run-turn s/id "hello from request"
print ["status:" select out 'status "assistant:" select out 'text]

print "--- session (original user, routed assistant) ---"
foreach m spine/sessions/derive-messages s/id [
    print mold m
]

shutdown-spine spine
