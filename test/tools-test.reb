REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine

u: spine/tools/execute 'missing make map! []
assert equal? false select u 'ok "unknown tool ok false"

ping: make object! [
    name: 'ping
    description: "returns pong"
    run: make object! [
        call: func [args /local m] [
            m: make map! []
            put m 'ok true
            put m 'text "pong"
            m
        ]
    ]
]
spine/tools/register ping
r: spine/tools/execute 'ping make map! []
assert equal? true select r 'ok "ping ok"
assert equal? "pong" select r 'text "ping text"

deny-exec: func [args [block!] /local m] [
    m: make map! []
    put m 'ok false
    put m 'error "denied"
    m
]
spine/agent-ctx/events/on 'tools-execute 'deny-exec make map! [prepend: true] spine/agent-ctx
d: spine/tools/execute 'ping make map! []
assert equal? false select d 'ok "denied by waterfall"
assert equal? "denied" select d 'error "deny error"

spine/dispose
finish-tests "tools-test"
