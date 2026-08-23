REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
s: spine/sessions/create
assert equal? "s1" s/id "first session id"

p: make map! []
put p 'text "hi"
spine/sessions/append-event s/id 'user-message p
p: make map! []
put p 'text "there"
spine/sessions/append-event s/id 'assistant-message p

evs: spine/sessions/events-of s/id
assert equal? 2 length? evs "two events stored"
msgs: spine/sessions/derive-messages s/id
assert equal? 2 length? msgs "two derived messages"
assert equal? 'user select msgs/1 'role "first role user"
assert equal? "hi" select msgs/1 'content "user content"
assert equal? "there" select msgs/2 'content "assistant content"

assert none? spine/sessions/append-event "nope" 'user-message p "missing session append none"
assert equal? 0 length? spine/sessions/derive-messages "nope" "missing session empty view"

spine/dispose
finish-tests "session-test"
