REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
agent-a: spine/agents/create "A"
agent-b: spine/agents/create "B"

assert equal? "A" agent-a/id "agent A id"
assert equal? "B" agent-b/id "agent B id"
assert equal? 3 length? spine/agents/list "default + A + B registered"

s-a: spine/sessions/create
s-b: spine/sessions/create

out-a: agent-a/driver/run-turn s-a/id "hello-a"
out-b: agent-b/driver/run-turn s-b/id "hello-b"
assert equal? 'text select out-a 'status "agent A turn"
assert equal? "hello-a" select out-a 'text "agent A echo"
assert equal? 'text select out-b 'status "agent B turn"
assert equal? "hello-b" select out-b 'text "agent B echo"

; ---- inbox lives on the handle, not only on driver ----
s-f: spine/sessions/create
agent-b/followup "from-handle"
out-f: agent-b/run-turn s-f/id none
assert equal? 'text select out-f 'status "handle followup drives turn"
assert equal? "from-handle" select out-f 'text "handle followup text"

spine/agents/dispose agent-a
assert none? spine/agents/get "A" "A removed from registry"

out-a2: agent-a/driver/run-turn s-a/id "again"
assert equal? 'disposed select out-a2 'status "disposed agent rejects turn"
assert equal? 0 select out-a2 'steps "disposed turn has no steps"

out-b2: agent-b/driver/run-turn s-b/id "still-b"
assert equal? 'text select out-b2 'status "agent B still active"
assert equal? "still-b" select out-b2 'text "agent B still echoes"

shutdown-spine spine
finish-tests "agent-test"
