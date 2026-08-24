REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
s: spine/sessions/create

; ---- three tool calls in one turn, then final text ----
c1: make map! []
put c1 'kind 'tool-call
put c1 'name 'bash
a1: make map! []
put a1 'command "echo step1"
put c1 'args a1
spine/llm/enqueue c1

c2: make map! []
put c2 'kind 'tool-call
put c2 'name 'bash
a2: make map! []
put a2 'command "echo step2"
put c2 'args a2
spine/llm/enqueue c2

c3: make map! []
put c3 'kind 'tool-call
put c3 'name 'bash
a3: make map! []
put a3 'command "echo step3"
put c3 'args a3
spine/llm/enqueue c3

fin: make map! []
put fin 'kind 'text
put fin 'text "all done"
spine/llm/enqueue fin

out: spine/driver/run-turn s/id "run three"
assert equal? 'text select out 'status "three-tool turn ends with text"
assert equal? "all done" select out 'text "final assistant text"
assert equal? 4 select out 'steps "three tools + text = 4 steps"

roles: copy []
foreach m spine/sessions/derive-messages s/id [append roles select m 'role]
assert equal? [user assistant tool assistant tool assistant tool assistant] roles "derive: 3 tool rounds"

; ---- resume from the completed turn continues without new user ----
nxt: make map! []
put nxt 'kind 'text
put nxt 'text "resumed"
spine/llm/enqueue nxt
out2: spine/driver/resume-turn s/id
assert equal? 'text select out2 'status "resume from text turn"
assert equal? "resumed" select out2 'text "resume text"
assert equal? 1 select out2 'steps "resume one step"

; ---- resume on empty session returns no-input ----
s2: spine/sessions/create
out3: spine/driver/resume-turn s2/id
assert equal? 'no-input select out3 'status "empty session resume no-input"
assert equal? 0 select out3 'steps "no-input zero steps"

; ---- max-steps cap on tool loop ----
spine/driver/max-steps: 2
s3: spine/sessions/create
loop-calls: copy []
loop 5 [
    tc: make map! []
    put tc 'kind 'tool-call
    put tc 'name 'bash
    ta: make map! []
    put ta 'command "echo loop"
    put tc 'args ta
    append loop-calls tc
]
foreach tc loop-calls [spine/llm/enqueue tc]
out4: spine/driver/run-turn s3/id "infinite"
assert equal? 'max-steps select out4 'status "tool loop hits max-steps"
assert equal? 2 select out4 'steps "max-steps count"

spine/driver/max-steps: 8

shutdown-spine spine
finish-tests "loop-multistep-test"
