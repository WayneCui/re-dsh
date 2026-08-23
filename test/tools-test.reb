REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine

u: spine/tools/execute 'missing make map! []
assert equal? false select u 'ok "unknown tool ok false"

; ---- ping tool with call counter ----
ping-calls: 0
ping: make object! [
    name: 'ping
    description: "returns pong"
    run: make object! [
        call: func [args /local m] [
            ping-calls: ping-calls + 1
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
assert equal? 1 ping-calls "body ran once"

; ---- pre-execute deny: body must not run ----
ping-calls: 0
pre-deny: func [args [block!] /local m] [
    m: make map! []
    put m 'kind 'deny
    put m 'error "pre-denied"
    m
]
pre-disp: spine/agent-ctx/events/on 'tools-pre-execute 'pre-deny make map! [prepend: true] spine/agent-ctx
d: spine/tools/execute 'ping make map! []
assert equal? false select d 'ok "pre denied ok false"
assert equal? "pre-denied" select d 'error "pre deny reason"
assert equal? 0 ping-calls "pre deny skips body"
pre-disp/dispose

; ---- execute-stage deny (hook on tools-execute) ----
ping-calls: 0
exec-deny: func [args [block!] /local m] [
    m: make map! []
    put m 'ok false
    put m 'error "exec-denied"
    m
]
exec-disp: spine/agent-ctx/events/on 'tools-execute 'exec-deny make map! [prepend: true] spine/agent-ctx
d2: spine/tools/execute 'ping make map! []
assert equal? false select d2 'ok "exec stage denied"
assert equal? "exec-denied" select d2 'error "exec deny reason"
assert equal? 0 ping-calls "exec deny skips body"
exec-disp/dispose

; ---- post-execute rewrite stdout ----
ping-calls: 0
post-rewrite: func [args [block!] /local nw m] [
    nw: last args
    m: nw/call
    put m 'stdout "rewritten"
    put m 'text "rewritten"
    m
]
post-disp: spine/agent-ctx/events/on 'tools-post-execute 'post-rewrite make map! [] spine/agent-ctx
rw: spine/tools/execute 'ping make map! []
assert equal? true select rw 'ok "post rewrite ok"
assert equal? "rewritten" select rw 'stdout "post rewrite stdout"
assert equal? 1 ping-calls "post rewrite still ran body"
post-disp/dispose

; ---- tools-result emit ----
result-seen: false
result-observer: func [args [block!]] [
    result-seen: true
    assert equal? 'ping select args/1 'name "result exec name"
    assert equal? true select args/2 'ok "result payload ok"
]
result-disp: spine/agent-ctx/events/on 'tools-result 'result-observer make map! [] spine/agent-ctx
spine/tools/execute 'ping make map! []
assert result-seen "tools-result emitted"
result-disp/dispose

spine/dispose
finish-tests "tools-test"
