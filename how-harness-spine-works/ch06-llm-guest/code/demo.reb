REBOL []

; Chapter 06 lab: the model is a guest — echo default, enqueue, streamed chunks.
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine
llm: spine/llm

echo-msgs: reduce [make map! [role: 'user content: "hello guest"]]
echo-reply: llm/complete echo-msgs copy []
print rejoin ["ECHO: " select echo-reply 'text]

queued: make map! []
put queued 'kind 'text
put queued 'text "from-queue"
llm/enqueue queued
q-reply: llm/complete echo-msgs copy []
print rejoin ["ENQUEUED: " select q-reply 'text]

seen: copy []
sink: make object! [
    call: func [text [string!]] [append seen text]
]
chunked: make map! []
put chunked 'kind 'text
put chunked 'text "hello"
put chunked 'chunks ["hel" "lo"]
llm/enqueue chunked
stream-reply: llm/stream/on-chunk copy [] copy [] sink
print rejoin ["STREAM-TEXT: " select stream-reply 'text]
print rejoin ["STREAM-CHUNKS: " mold seen]

s: spine/sessions/create
stream-turn: make map! []
put stream-turn 'kind 'text
put stream-turn 'text "hello"
put stream-turn 'chunks ["hel" "lo"]
llm/enqueue stream-turn
out: spine/driver/run-turn s/id "hi"
print rejoin ["TURN-ASSISTANT: " select out 'text]

types: copy []
foreach ev spine/sessions/events-of s/id [
    append types select ev 'type
]
print rejoin ["TURN-TYPES: " mold types]

plain-s: spine/sessions/create
plain: make map! []
put plain 'kind 'text
put plain 'text "hello"
llm/enqueue plain
spine/driver/run-turn plain-s/id "hi"
print rejoin ["DERIVE-MATCH: " mold equal?
    spine/sessions/derive-messages s/id
    spine/sessions/derive-messages plain-s/id
]

shutdown-spine spine
print "LAB-OK"
