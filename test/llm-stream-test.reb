REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
sessions: spine/sessions
llm: spine/llm
driver: spine/driver

has-type?: func [types [block!] t [word!]] [
    not none? find types t
]

; ---- llm/stream emits chunks then returns final text ----
seen: copy []
sink: make object! [
    call: func [text [string!]] [append seen text]
]
queued: make map! []
put queued 'kind 'text
put queued 'text "hello"
put queued 'chunks ["hel" "lo"]
llm/enqueue queued
reply: llm/stream/on-chunk copy [] copy [] sink
assert equal? 'text select reply 'kind "stream kind text"
assert equal? "hello" select reply 'text "stream final text"
assert equal? ["hel" "lo"] seen "stream emitted chunks"

; ---- chunks-only fold in derive (no assistant-message) ----
s0: sessions/create
c1: make map! []
put c1 'text "ab"
sessions/append-event s0/id 'assistant-chunk c1
c2: make map! []
put c2 'text "cd"
sessions/append-event s0/id 'assistant-chunk c2
msgs0: sessions/derive-messages s0/id
assert equal? 1 length? msgs0 "chunks fold to one message"
assert equal? 'assistant select msgs0/1 'role "folded role assistant"
assert equal? "abcd" select msgs0/1 'content "folded chunk text"

; ---- multi-chunk turn vs single-chunk turn: derive matches ----
s-stream: sessions/create
stream-reply: make map! []
put stream-reply 'kind 'text
put stream-reply 'text "hello"
put stream-reply 'chunks ["hel" "lo"]
llm/enqueue stream-reply
out-stream: driver/run-turn s-stream/id "hi"
assert equal? 'text select out-stream 'status "stream turn ok"
assert equal? "hello" select out-stream 'text "stream turn text"

evs: sessions/events-of s-stream/id
types: copy []
foreach ev evs [append types select ev 'type]
assert has-type? types 'assistant-chunk "stream wrote chunks"
assert has-type? types 'assistant-message "stream wrote final message"

s-plain: sessions/create
plain: make map! []
put plain 'kind 'text
put plain 'text "hello"
llm/enqueue plain
out-plain: driver/run-turn s-plain/id "hi"
assert equal? sessions/derive-messages s-stream/id sessions/derive-messages s-plain/id "stream derive matches plain"

; ---- tool-call then streamed follow-up ----
s-tool: sessions/create
tc: make map! []
put tc 'kind 'tool-call
put tc 'name 'bash
a: make map! []
put a 'command "echo stream-tool"
put tc 'args a
llm/enqueue tc
follow: make map! []
put follow 'kind 'text
put follow 'text "done"
put follow 'chunks ["do" "ne"]
llm/enqueue follow
out-tool: driver/run-turn s-tool/id "run"
assert equal? 'text select out-tool 'status "tool+stream ends text"
assert equal? "done" select out-tool 'text "tool follow-up text"
roles: copy []
foreach m sessions/derive-messages s-tool/id [append roles select m 'role]
assert equal? [user assistant tool assistant] roles "derive roles after stream tool turn"

shutdown-spine spine
finish-tests "llm-stream-test"
