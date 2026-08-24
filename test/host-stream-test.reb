REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
h: spine/host

; ---- file fixture stream emits lines ----
lines: copy []
sink: make object! [
    call: func [line [string!]] [append lines line]
]
fx: %test/fixtures/llm-http-stream.txt
r: h/http-post-stream/on-line fx "ignored-body" sink
assert to-logic select r 'ok "stream fixture ok"
assert equal? false select r 'cancelled "stream not cancelled"
assert equal? 3 length? lines "three protocol lines"

; ---- cancel after first line ----
state: make object! [n: 0]
lines2: copy []
sink2: make object! [
    st: state
    call: func [line [string!]] [
        st/n: st/n + 1
        append lines2 line
    ]
]
cancel: make object! [
    st: state
    call: func [] [st/n >= 1]
]
r2: h/http-post-stream/on-line/cancel fx "body" sink2 cancel
assert to-logic select r2 'ok "cancel path ok"
assert equal? true select r2 'cancelled "stream cancelled"
assert equal? 1 length? lines2 "only first line before cancel"

shutdown-spine spine
finish-tests "host-stream-test"
