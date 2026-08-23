REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
s: spine/sessions/create

open-turn: func [sid [string!]] [
    spine/sessions/append-event sid 'turn-start make map! [] spine/agent-ctx
]

open-turn s/id

; ---- never policy rejects without answerer ----
spine/approval/set-policy s/id 'never
out: spine/approval/request s/id 'echo "c1" "headless"
assert equal? 'rejected out "never policy rejects"
assert equal? 'never spine/approval/effective-policy s/id "effective never"

; ---- ask + no answerer -> unavailable ----
spine/approval/set-policy s/id 'ask
out2: spine/approval/request s/id 'echo none "needs approval"
assert equal? 'unavailable out2 "no answerer unavailable"

events: spine/sessions/events-of s/id
asked: 0
decided: 0
foreach ev events [
    if equal? select ev 'type 'approval-asked [asked: asked + 1]
    if equal? select ev 'type 'approval-decided [decided: decided + 1]
]
assert equal? 2 asked "two approval-asked events"
assert equal? 2 decided "two approval-decided events"

; ---- answerer grants allowed-once ----
allow-answerer: func [args [block!]] ['allowed-once]
reject-answerer: func [args [block!]] ['rejected]
grant-answerer: func [args [block!]] ['allowed-once]

allow-disp: spine/ctx/events/on 'approval-request 'allow-answerer make map! [] spine/ctx
out3: spine/approval/request s/id 'bash "c2" "hook wants human"
assert equal? 'allowed-once out3 "answerer grants once"
allow-disp/dispose

; ---- rejected answer ----
reject-disp: spine/ctx/events/on 'approval-request 'reject-answerer make map! [] spine/ctx
out4: spine/approval/request s/id 'bash none none
assert equal? 'rejected out4 "answerer rejects"
reject-disp/dispose

; ---- outside turn throws ----
s2: spine/sessions/create
err: try [spine/approval/request s2/id 'echo none none]
assert error? err "request outside turn throws"

; ---- tools bridge: spec approval ask ----
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
assert equal? false select deny-r 'ok "ask tool without answerer denied"
err: form any [select deny-r 'error ""]
assert either find err "unavailable" [true] [false] "deny mentions unavailable"

grant-disp: spine/ctx/events/on 'approval-request 'grant-answerer make map! [] spine/ctx
ok-meta: make map! []
put ok-meta 'session-id s/id
put ok-meta 'call-id "c4"
ok-r: spine/tools/execute/meta 'ask-ping make map! [] ok-meta
assert equal? true select ok-r 'ok "ask tool runs after grant"
assert equal? "allowed-body" select ok-r 'text "ask tool body ran"
grant-disp/dispose

shutdown-spine spine
finish-tests "approval-test"
