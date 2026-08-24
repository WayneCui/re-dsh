REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

; Boot with http-url pointing at stream fixture (file! = local transport).
spine: boot-spine/llm-config make map! [http-url %test/fixtures/llm-http-stream.txt]
llm: spine/llm
sessions: spine/sessions
driver: spine/driver

; ---- stream parses deltas + final reply ----
seen: copy []
sink: make object! [
    call: func [text [string!]] [append seen text]
]
reply: llm/stream/on-chunk copy [] copy [] sink
assert equal? 'text select reply 'kind "http stream kind"
assert equal? "hello" select reply 'text "http stream final text"
assert equal? ["hel" "lo"] seen "http stream deltas"

; ---- complete still reads one-shot mold when fixture is single reply ----
; Use enqueue for one-shot; http complete on stream fixture joins via parse of whole body
; (complete uses run-llm-http which parse-llm-reply-text on full body — may fail).
; Prefer stream for multi-line fixtures; complete with echo fallback not tested here.

; ---- abort mid HTTP stream ----
state: make object! [n: 0]
seen2: copy []
sink2: make object! [
    st: state
    call: func [text [string!]] [
        st/n: st/n + 1
        append seen2 text
    ]
]
cancel: make object! [
    st: state
    call: func [] [st/n >= 1]
]
reply2: llm/stream/on-chunk/cancel copy [] copy [] sink2 cancel
assert equal? true select reply2 'cancelled "http stream aborted"
assert equal? ["hel"] seen2 "only first delta before abort"

; ---- agent-loop turn via http stream fixture ----
s: sessions/create
out: driver/run-turn s/id "hi"
assert equal? 'text select out 'status "http turn status"
assert equal? "hello" select out 'text "http turn text"
msgs: sessions/derive-messages s/id
assert equal? 2 length? msgs "user + assistant"
assert equal? "hello" select msgs/2 'content "derived assistant"

ev-types: copy []
foreach ev sessions/events-of s/id [append ev-types select ev 'type]
assert not none? find ev-types 'assistant-chunk "turn logged chunks"

; ---- cancel-turn aborts live http stream mid-chunks ----
; Re-enqueue isn't used; http-url fixture always streams. Cancel from a tool is covered
; elsewhere; here cancel-check that trips after first chunk via custom sink is enough.
shutdown-spine spine
finish-tests "llm-http-stream-test"
