REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine

s: spine/sessions/create
out: spine/driver/run-turn s/id "hello"
assert equal? 'text select out 'status "echo status text"
assert equal? "hello" select out 'text "echo assistant text"
assert equal? 1 select out 'steps "echo one step"
msgs: spine/sessions/derive-messages s/id
assert equal? 2 length? msgs "user + assistant in view"

s2: spine/sessions/create
call1: make map! []
put call1 'kind 'tool-call
put call1 'name 'bash
a: make map! []
put a 'command "echo from-tool"
put call1 'args a
spine/llm/enqueue call1
txt: make map! []
put txt 'kind 'text
put txt 'text "saw the tool"
spine/llm/enqueue txt
out2: spine/driver/run-turn s2/id "run it"
assert equal? 'text select out2 'status "tool turn ends with text"
assert equal? "saw the tool" select out2 'text "final assistant text"
assert equal? 2 select out2 'steps "tool + follow-up = 2 steps"
msgs2: spine/sessions/derive-messages s2/id
roles: copy []
foreach m msgs2 [append roles select m 'role]
assert equal? [user assistant tool assistant] roles "log: user, tool-call, result, assistant"

spine/dispose
finish-tests "loop-test"
