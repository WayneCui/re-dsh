REBOL []

; Chapter 07 lab: a turn rereads the log; resume skips a new user row;
; agent-pre-step rewrites the model view without rewriting history.
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine

; ---- tool call then text: two steps, four derived roles ----
s: spine/sessions/create
call1: make map! []
put call1 'kind 'tool-call
put call1 'name 'bash
a: make map! []
put a 'command "echo from-tool"
put call1 'args a
spine/llm/enqueue call1
txt: make map! []
put txt 'kind 'text
put txt 'text "saw the tool"
spine/llm/enqueue txt
out: spine/driver/run-turn s/id "run it"
print rejoin ["TOOL-STATUS: " mold select out 'status]
print rejoin ["TOOL-STEPS: " mold select out 'steps]
print rejoin ["TOOL-TEXT: " select out 'text]
roles: copy []
foreach m spine/sessions/derive-messages s/id [append roles select m 'role]
print rejoin ["TOOL-ROLES: " mold roles]

; ---- resume-turn continues when the log already ends in assistant/tool ----
s2: spine/sessions/create
spine/driver/run-turn s2/id "seeded"
txt2: make map! []
put txt2 'kind 'text
put txt2 'text "from-resume"
spine/llm/enqueue txt2
out2: spine/driver/resume-turn s2/id
print rejoin ["RESUME-TEXT: " select out2 'text]
r2: copy []
foreach m spine/sessions/derive-messages s2/id [append r2 select m 'role]
print rejoin ["RESUME-ROLES: " mold r2]
users: 0
foreach m spine/sessions/derive-messages s2/id [
    if equal? select m 'role 'user [users: users + 1]
]
print rejoin ["RESUME-USER-ROWS: " mold users]

; ---- pre-step rewrite: model sees prefix, log keeps original ----
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
s3: spine/sessions/create
out3: spine/driver/run-turn s3/id "hello from pre-step"
print rejoin ["PRESTEP-ASSISTANT: " select out3 'text]
log-user: first spine/sessions/derive-messages s3/id
print rejoin ["PRESTEP-LOG-USER: " select log-user 'content]

shutdown-spine spine
print "LAB-OK"
