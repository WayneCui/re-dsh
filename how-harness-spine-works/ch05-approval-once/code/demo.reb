REBOL []

; Chapter 05 lab: approval is one-shot, fail-closed, and written into the log.
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine
s: spine/sessions/create
spine/sessions/append-event s/id 'turn-start make map! [] spine/agent-ctx

spine/approval/set-policy s/id 'never
out: spine/approval/request s/id 'echo "c1" "headless"
print rejoin ["NEVER: " mold out]

spine/approval/set-policy s/id 'ask
out2: spine/approval/request s/id 'echo none "needs approval"
print rejoin ["NO-ANSWERER: " mold out2]

allow-answerer: func [args [block!]] ['allowed-once]
allow-disp: spine/ctx/events/on 'approval-request 'allow-answerer make map! [] spine/ctx
out3: spine/approval/request s/id 'bash "c2" "hook wants human"
print rejoin ["GRANTED: " mold out3]
allow-disp/dispose

asked: 0
decided: 0
foreach ev spine/sessions/events-of s/id [
    if equal? select ev 'type 'approval-asked [asked: asked + 1]
    if equal? select ev 'type 'approval-decided [decided: decided + 1]
]
print rejoin ["ASKED: " mold asked]
print rejoin ["DECIDED: " mold decided]

s2: spine/sessions/create
err: try [spine/approval/request s2/id 'echo none none]
print rejoin ["OUTSIDE-TURN: " mold error? err]

ask-tool: make object! [
    name: 'ask-ping
    description: "needs approval"
    approval: 'ask
    run: make object! [
        call: func [args /local m] [
            m: make map! []
            put m 'ok true
            put m 'text "allowed-body"
            m
        ]
    ]
]
spine/tools/register ask-tool

deny-meta: make map! []
put deny-meta 'session-id s/id
put deny-meta 'call-id "c3"
deny-r: spine/tools/execute/meta 'ask-ping make map! [] deny-meta
print rejoin ["TOOL-DENIED: " mold select deny-r 'ok]

grant-answerer: func [args [block!]] ['allowed-once]
grant-disp: spine/ctx/events/on 'approval-request 'grant-answerer make map! [] spine/ctx
ok-meta: make map! []
put ok-meta 'session-id s/id
put ok-meta 'call-id "c4"
ok-r: spine/tools/execute/meta 'ask-ping make map! [] ok-meta
print rejoin ["TOOL-GRANTED: " select ok-r 'text]
grant-disp/dispose

shutdown-spine spine
print "LAB-OK"
