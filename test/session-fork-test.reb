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

; ---- resume on lone user-message is no-input (not "echo the seed") ----
s: spine/sessions/create
spine/sessions/append-event s/id 'user-message make map! [text: "seeded"]
out: spine/driver/resume-turn s/id
assert equal? 'no-input select out 'status "lone user resume is no-input"
assert equal? 0 select out 'steps "no-input zero steps"
roles: copy []
foreach m spine/sessions/derive-messages s/id [append roles select m 'role]
assert equal? [user] roles "no-input does not invent assistant"

; ---- resume after a completed turn continues without a new user row ----
s2: spine/sessions/create
spine/driver/run-turn s2/id "seeded"
nxt: make map! []
put nxt 'kind 'text
put nxt 'text "from-resume"
spine/llm/enqueue nxt
out2: spine/driver/resume-turn s2/id
assert equal? 'text select out2 'status "resume status after assistant tail"
assert equal? "from-resume" select out2 'text "resume continues from history"
roles2: copy []
foreach m spine/sessions/derive-messages s2/id [append roles2 select m 'role]
assert equal? [user assistant assistant] roles2 "resume does not append user"

; ---- fork then resume on child; parent stays at fork point ----
base: spine/sessions/create
spine/sessions/append-event base/id 'user-message make map! [text: "branch-root"]
spine/sessions/append-event base/id 'assistant-message make map! [text: "at-cut"]
base-msgs: spine/sessions/derive-messages base/id
branch: spine/sessions/fork base/id
txt: make map! []
put txt 'kind 'text
put txt 'text "from-branch"
spine/llm/enqueue txt
bout: spine/driver/resume-turn branch/id
assert equal? "from-branch" select bout 'text "branch resume text"
assert equal? base-msgs spine/sessions/derive-messages base/id "base still fork-point only"
assert equal? 3 length? spine/sessions/derive-messages branch/id "branch gained assistant"

shutdown-spine spine
finish-tests "session-fork-test"
