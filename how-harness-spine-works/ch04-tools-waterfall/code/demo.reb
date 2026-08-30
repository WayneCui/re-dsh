REBOL []

; Chapter 04 lab: tools-pre-execute / tools-execute / tools-post-execute / tools-result.
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine

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
print rejoin ["PING: " select r 'text " calls=" mold ping-calls]

u: spine/tools/execute 'missing make map! []
print rejoin ["UNKNOWN-OK: " mold select u 'ok]
print rejoin ["UNKNOWN-ERR: " select u 'error]

; pre-execute deny: body must not run
ping-calls: 0
pre-deny: func [args [block!] /local m] [
    m: make map! []
    put m 'kind 'deny
    put m 'error "pre-denied"
    m
]
pre-disp: spine/agent-ctx/events/on 'tools-pre-execute 'pre-deny make map! [prepend: true] spine/agent-ctx
d: spine/tools/execute 'ping make map! []
print rejoin ["PRE-DENY: " select d 'error " calls=" mold ping-calls]
pre-disp/dispose

; post-execute rewrite: body ran, result rewritten
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
print rejoin ["POST-REWRITE: " select rw 'text " calls=" mold ping-calls]
post-disp/dispose

; tools-result emit after the gates
result-seen: false
result-observer: func [args [block!]] [
    result-seen: true
]
result-disp: spine/agent-ctx/events/on 'tools-result 'result-observer make map! [] spine/agent-ctx
spine/tools/execute 'ping make map! []
print rejoin ["RESULT-EMITTED: " mold result-seen]
result-disp/dispose

; bash is registered by shell-plugin on the isolate, and goes through host
sh: spine/tools/execute 'bash make map! [command: "echo through-host"]
print rejoin ["BASH-STDOUT: " trim select sh 'stdout]

shutdown-spine spine
print "LAB-OK"
