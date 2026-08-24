REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

store-dir: %test/tmp-session-store/
if exists? store-dir [
    foreach f read store-dir [
        try [delete to-file rejoin [store-dir f]]
    ]
]
make-dir/deep store-dir

session-cfg: make map! []
put session-cfg 'store-dir store-dir

spine1: boot-spine/session-config session-cfg
s: spine1/sessions/create
sid: s/id
assert equal? "s1" sid "first persisted session id"

spine1/sessions/append-event sid 'user-message make map! [text: "persist me"]
spine1/sessions/append-event sid 'assistant-message make map! [text: "ok"]
live-msgs: spine1/sessions/derive-messages sid
assert equal? 2 length? live-msgs "live has two messages"
assert true? spine1/sessions/backend/exists-session? sid "file written after append"

shutdown-spine spine1

; fresh process-equivalent: new store with same dir, memory empty
spine2: boot-spine/session-config session-cfg
assert none? spine2/sessions/find-session sid "memory empty after reboot"
opened: spine2/sessions/open sid
assert object? opened "open restores session"
assert equal? sid (select opened 'id) "opened id preserved"
assert equal? live-msgs spine2/sessions/derive-messages sid "derive matches across reboot"

; create after open should not reuse s1
s2: spine2/sessions/create
assert equal? "s2" s2/id "seq continues after open"

; missing id
assert none? spine2/sessions/open "missing-id" "missing open returns none"

; memory-only boot still works (no backend)
spine3: boot-spine
sm: spine3/sessions/create
spine3/sessions/append-event sm/id 'user-message make map! [text: "ram"]
assert none? spine3/sessions/backend "default has no backend"
no-open: try [spine3/sessions/open "ghost"][]
assert error? no-open "open without backend errors"

shutdown-spine spine2
shutdown-spine spine3

; cleanup
foreach f read store-dir [
    try [delete to-file rejoin [store-dir f]]
]
try [delete store-dir]

finish-tests "session-persist-test"
