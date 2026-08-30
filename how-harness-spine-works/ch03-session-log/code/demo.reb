REBOL []

; Chapter 03 lab: append-only log, frozen payloads, derive view, fork, persist.
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine

; ---- snapshot isolates caller mutation ----
s: spine/sessions/create
live-p: make map! []
put live-p 'text "before"
spine/sessions/append-event s/id 'user-message live-p
put live-p 'text "after"
stored: spine/sessions/events-of s/id
print rejoin ["FROZEN: " select stored/1/payload 'text]

; ---- chunks fold; assistant-message wins ----
s2: spine/sessions/create
spine/sessions/append-event s2/id 'assistant-chunk make map! [text: "hel"]
spine/sessions/append-event s2/id 'assistant-chunk make map! [text: "lo"]
folded: spine/sessions/derive-messages s2/id
print rejoin ["FOLDED: " select folded/1 'content]

spine/sessions/append-event s2/id 'assistant-message make map! [text: "hello-final"]
won: spine/sessions/derive-messages s2/id
print rejoin ["MESSAGE-WINS: " select won/1 'content]

; ---- fork copies prefix, then branches diverge ----
parent: spine/sessions/create
spine/sessions/append-event parent/id 'user-message make map! [text: "shared"]
spine/sessions/append-event parent/id 'assistant-message make map! [text: "ack"]
child: spine/sessions/fork parent/id
spine/sessions/append-event child/id 'user-message make map! [text: "only-child"]
print rejoin ["PARENT-MSGS: " mold length? spine/sessions/derive-messages parent/id]
print rejoin ["CHILD-MSGS: " mold length? spine/sessions/derive-messages child/id]
print rejoin ["FORKED-FROM: " select child 'forked-from]

shutdown-spine spine

; ---- persist across a fresh boot ----
store-dir: %how-harness-spine-works/ch03-session-log/code/tmp-store/
if exists? store-dir [
    foreach f read store-dir [
        try [delete to-file rejoin [store-dir f]]
    ]
]
make-dir/deep store-dir
session-cfg: make map! []
put session-cfg 'store-dir store-dir

spine1: boot-spine/session-config session-cfg
s3: spine1/sessions/create
sid: s3/id
spine1/sessions/append-event sid 'user-message make map! [text: "persist me"]
spine1/sessions/append-event sid 'assistant-message make map! [text: "ok"]
print rejoin ["PERSIST-ID: " sid]
shutdown-spine spine1

spine2: boot-spine/session-config session-cfg
print rejoin ["MEMORY-EMPTY: " mold none? spine2/sessions/find-session sid]
opened: spine2/sessions/open sid
print rejoin ["OPENED-ID: " select opened 'id]
msgs: spine2/sessions/derive-messages sid
print rejoin ["REOPENED: " select msgs/1 'content " | " select msgs/2 'content]
shutdown-spine spine2

foreach f read store-dir [
    try [delete to-file rejoin [store-dir f]]
]
try [delete store-dir]

print "LAB-OK"
