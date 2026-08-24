REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine

; ---- fork copies prefix and isolates branches ----
parent: spine/sessions/create
spine/sessions/append-event parent/id 'user-message make map! [text: "shared"]
spine/sessions/append-event parent/id 'assistant-message make map! [text: "ack"]
parent-msgs: spine/sessions/derive-messages parent/id

child: spine/sessions/fork parent/id
assert equal? "s2" (select child 'id) "fork allocates new id"
assert equal? parent/id (select child 'forked-from) "forked-from points to parent"
assert equal? parent-msgs spine/sessions/derive-messages child/id "fork derive matches parent at cut"

spine/sessions/append-event child/id 'user-message make map! [text: "only-child"]
assert equal? 2 length? spine/sessions/derive-messages parent/id "parent still two messages"
assert equal? 3 length? spine/sessions/derive-messages child/id "child diverged"
assert equal? parent-msgs spine/sessions/derive-messages parent/id "parent prefix unchanged"

; ---- missing fork source ----
bad: try [spine/sessions/fork "nope"][]
assert error? bad "fork missing session errors"

; ---- resume-turn: continue from log without new user-message ----
s: spine/sessions/create
spine/sessions/append-event s/id 'user-message make map! [text: "seeded"]
out: spine/driver/resume-turn s/id
assert equal? 'text select out 'status "resume echo status"
assert equal? "seeded" select out 'text "resume echoes derived user text"
msgs: spine/sessions/derive-messages s/id
roles: copy []
foreach m msgs [append roles select m 'role]
assert equal? [user assistant] roles "resume does not append user"

; ---- fork then resume on child; parent stays at fork point ----
base: spine/sessions/create
spine/sessions/append-event base/id 'user-message make map! [text: "branch-root"]
branch: spine/sessions/fork base/id
txt: make map! []
put txt 'kind 'text
put txt 'text "from-branch"
spine/llm/enqueue txt
bout: spine/driver/resume-turn branch/id
assert equal? "from-branch" select bout 'text "branch resume text"
assert equal? 1 length? spine/sessions/derive-messages base/id "base still fork-point only"
assert equal? 2 length? spine/sessions/derive-messages branch/id "branch gained assistant"

shutdown-spine spine
finish-tests "session-fork-test"
