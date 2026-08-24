REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine

; ---- followup drives a turn without user-text ----
s: spine/sessions/create
spine/driver/followup "from followup"
out: spine/driver/run-turn s/id none
assert equal? 'text select out 'status "followup turn ends text"
assert equal? "from followup" select out 'text "echoes followup text"
msgs: spine/sessions/derive-messages s/id
assert equal? 2 length? msgs "user + assistant"
assert equal? "from followup" select msgs/1 'content "followup became user message"

; ---- inject does not wake; steer does ----
s2: spine/sessions/create
spine/driver/inject "context only"
out2: spine/driver/run-turn s2/id none
assert equal? 'no-input select out2 'status "inject alone no-input"
assert equal? 0 select out2 'steps "no-input zero steps"

spine/driver/steer "steer now"
out3: spine/driver/run-turn s2/id none
assert equal? 'text select out3 'status "steer drives turn"
assert equal? "steer now" select out3 'text "steer text wins over inject"
roles2: copy []
foreach m spine/sessions/derive-messages s2/id [append roles2 select m 'role]
assert equal? [user user assistant] roles2 "inject + steer both logged, steer last"

; ---- run-turn with explicit user still claims inbox context ----
s3: spine/sessions/create
spine/driver/inject "extra context"
out4: spine/driver/run-turn s3/id "hello"
assert equal? 'text select out4 'status "user turn with inbox context"
roles3: copy []
foreach m spine/sessions/derive-messages s3/id [append roles3 select m 'role]
assert equal? [user user assistant] roles3 "inject claimed with explicit user"

; ---- resume picks up pending followup ----
s4: spine/sessions/create
out5: spine/driver/run-turn s4/id "first"
assert equal? 'text select out5 'status "first turn"
spine/driver/followup "second"
out6: spine/driver/resume-turn s4/id
assert equal? 'text select out6 'status "resume with followup"
assert equal? "second" select out6 'text "followup text"
roles4: copy []
foreach m spine/sessions/derive-messages s4/id [append roles4 select m 'role]
assert equal? [user assistant user assistant] roles4 "followup adds user, not duplicate"

; ---- empty inbox + empty session = no-input ----
s5: spine/sessions/create
out7: spine/driver/run-turn s5/id none
assert equal? 'no-input select out7 'status "empty everything no-input"

shutdown-spine spine
finish-tests "loop-inbox-test"
