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

; ---- append hardening: snapshot isolates caller mutation ----
s2: spine/sessions/create
live-p: make map! []
put live-p 'text "before"
spine/sessions/append-event s2/id 'user-message live-p
put live-p 'text "after"
stored: spine/sessions/events-of s2/id
assert equal? "before" select stored/1/payload 'text "payload snapshot frozen"

; ---- reject unknown type ----
bad-type: try [spine/sessions/append-event s2/id 'bogus make map! []][]
assert error? bad-type "unknown type rejected"

; ---- reject bad payload ----
bad-payload: try [
    spine/sessions/append-event s2/id 'user-message make map! [n: 1]
][]
assert error? bad-payload "non-string text rejected"

; ---- tool-call / tool-result with call-id ----
s3: spine/sessions/create
tc: make map! []
put tc 'kind 'tool-call
put tc 'name 'bash
put tc 'call-id "c1"
put tc 'args make map! [command "echo hi"]
spine/sessions/append-event s3/id 'tool-call tc
tr: make map! []
put tr 'name 'bash
put tr 'call-id "c1"
put tr 'text "hi"
spine/sessions/append-event s3/id 'tool-result tr
msgs3: spine/sessions/derive-messages s3/id
assert equal? 2 length? msgs3 "tool pair projects two messages"
assert equal? "c1" select msgs3/1 'call-id "tool-call call-id"
assert equal? "c1" select msgs3/2 'call-id "tool-result call-id"

; ---- replay from log only ----
s4: spine/sessions/create
spine/sessions/append-event s4/id 'turn-start make map! []
spine/sessions/append-event s4/id 'user-message make map! [text: "replay me"]
spine/sessions/append-event s4/id 'assistant-message make map! [text: "replayed"]
te: make map! []
put te 'status 'text
put te 'steps 1
put te 'text "replayed"
spine/sessions/append-event s4/id 'turn-end te
live-derive: spine/sessions/derive-messages s4/id
log: spine/sessions/events-snapshot s4/id
assert equal? 4 length? log "snapshot has four events"

; simulate losing live session object — only log survives
spine/sessions/sessions: map-remove-key spine/sessions/sessions s4/id
assert none? spine/sessions/find-session s4/id "live session removed"

s-replay: spine/sessions/create-from-log log
assert equal? live-derive spine/sessions/derive-messages s-replay/id "replay derive matches live"
assert equal? 4 s-replay/live-index "live-index marks seed length"

; append after replay continues from seed
spine/sessions/append-event s-replay/id 'user-message make map! [text: "post-seed"]
assert equal? 5 length? spine/sessions/events-of s-replay/id "append after replay"

; ---- session-event emit contained on observer throw ----
observer-throw: func [args [block!]] [
    cause-error 'user 'message "observer failed"
]
obs-disp: spine/ctx/events/on 'session-event 'observer-throw make map! [] spine/ctx
s5: spine/sessions/create
ev-ok: spine/sessions/append-event s5/id 'user-message make map! [text: "still committed"]
assert map? ev-ok "append commits despite observer throw"
obs-disp/dispose

shutdown-spine spine
finish-tests "session-test"
