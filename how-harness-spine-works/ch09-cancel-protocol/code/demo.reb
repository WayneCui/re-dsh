REBOL []

; Chapter 09 lab: cancel is cooperative, written into the log, and dispose refuses.
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine
driver: spine/driver
sessions: spine/sessions

print rejoin ["IDLE-CANCEL: " mold driver/cancel-turn]
print rejoin ["IDLE-FLAG: " mold driver/cancel-requested]

cancel-tool: make object! [
    name: 'abort
    description: "cancels the live turn"
    run: make object! [
        drv: driver
        call: func [args /local m] [
            drv/cancel-turn
            m: make map! []
            put m 'ok true
            put m 'text "abort-body"
            m
        ]
    ]
]
spine/tools/register cancel-tool

tc: make map! []
put tc 'kind 'tool-call
put tc 'name 'abort
put tc 'args make map! []
spine/llm/enqueue tc
follow: make map! []
put follow 'kind 'text
put follow 'text "should-not-run"
spine/llm/enqueue follow

s: sessions/create
out: driver/run-turn s/id "please abort"
print rejoin ["CANCEL-STATUS: " mold select out 'status]
print rejoin ["FLAG-CLEARED: " mold driver/cancel-requested]

types: copy []
foreach ev sessions/events-of s/id [append types select ev 'type]
print rejoin ["HAS-TURN-START: " mold not none? find types 'turn-start]
print rejoin ["HAS-TOOL-CALL: " mold not none? find types 'tool-call]
print rejoin ["HAS-TOOL-RESULT: " mold not none? find types 'tool-result]
print rejoin ["HAS-ASSISTANT: " mold not none? find types 'assistant-message]

tr: none
foreach ev sessions/events-of s/id [
    if equal? select ev 'type 'tool-result [
        tr: select ev 'payload
    ]
]
print rejoin ["RESULT-CANCELLED: " mold select tr 'cancelled]
print rejoin ["RESULT-TEXT: " select tr 'text]

s2: sessions/create
out2: driver/run-turn s2/id "next"
print rejoin ["NEXT-STATUS: " mold select out2 'status]

agent-x: spine/agents/create "X"
s3: sessions/create
spine/agents/dispose agent-x
out3: agent-x/driver/run-turn s3/id "after dispose"
print rejoin ["DISPOSED: " mold select out3 'status]

shutdown-spine spine
print "LAB-OK"
