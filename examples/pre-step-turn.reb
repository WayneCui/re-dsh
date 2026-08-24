REBOL []

; agent/pre-step demo: listener rewrites user input before the model sees it.
; Run from harness-spine/: r3 -s examples/pre-step-turn.reb

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine

; Rewrite user messages to add a prefix before they reach the LLM
rewrite-listener: func [args [block!] /local msgs] [
    msgs: args/3
    if block? msgs [
        foreach m msgs [
            if equal? select m 'role 'user [
                put m 'content rejoin ["[prefix] " select m 'content]
            ]
        ]
    ]
    msgs
]
spine/ctx/events/on 'agent-pre-step 'rewrite-listener make map! [] spine/ctx

s: spine/sessions/create
out: spine/driver/run-turn s/id "hello from pre-step"
print ["status:" select out 'status "assistant:" select out 'text]

print "--- session log (original) ---"
foreach m spine/sessions/derive-messages s/id [
    print mold m
]

shutdown-spine spine
