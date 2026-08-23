REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

stub: %test/fixtures/llm-pipeline-stub.reb
llm-cfg: make map! []
put llm-cfg 'script stub
spine: boot-spine/llm-config llm-cfg

msg: make map! []
put msg 'role 'user
put msg 'content "script-echo"
reply: spine/llm/complete reduce [msg] spine/tools/list
assert equal? 'tool-call select reply 'kind "script returns tool-call when bash available"
assert equal? 'bash select reply 'name "script tool-call is bash"
reply2: spine/llm/complete reduce [msg] []
assert equal? 'text select reply2 'kind "script returns text without tools"
assert equal? "script-echo" select reply2 'text "script echoes user without tools"

s: spine/sessions/create
out: spine/driver/run-turn s/id "run it"
assert equal? 'text select out 'status "script turn ends with text"
assert equal? "saw the tool" select out 'text "script follow-up text"
assert equal? 2 select out 'steps "tool + follow-up = 2 steps"
msgs: spine/sessions/derive-messages s/id
roles: copy []
foreach m msgs [append roles select m 'role]
assert equal? [user assistant tool assistant] roles "log: user, tool-call, result, assistant"

shutdown-spine spine
finish-tests "llm-script-test"
