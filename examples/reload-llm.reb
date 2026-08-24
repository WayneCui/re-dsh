REBOL []
; reload-llm.reb — ????????? LLM ?????????
; (stdout ??????r3 print ? UTF-8 ???????)
;
;   1. boot-spine ??? echo ??????? -> ????
;   2. reload-spine-plugin ???? llm ?? UPPERCASE ???
;      ?dispose ? fiber -> ?????agent-loop fiber ? epoch ??????
;   3. ??? session ???? -> ????????????
;   4. ?? reload ???????? -> ???????????
;
; ??: r3 -s examples/reload-llm.reb

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine
s: spine/sessions/create

print "== turn 1: default echo adapter =="
out1: spine/driver/run-turn s/id "hello cordis"
print ["assistant:" select out1 'text]

print "^/== hot swap llm -> UPPERCASE adapter =="
r: reload-spine-plugin spine "llm" %examples/fixtures/llm-upper.reb
print ["reload:" mold r]

print "^/== turn 2: same session, adapter swapped =="
out2: spine/driver/run-turn s/id "hello cordis"
print ["assistant:" select out2 'text]

print "^/== session history intact =="
foreach m spine/sessions/derive-messages s/id [
    print [" " select m 'role "|" select m 'content]
]

print "^/== rollback: reload a missing file =="
r2: reload-spine-plugin spine "llm" %examples/fixtures/no-such-adapter.reb
print ["reload:" r2]
out3: spine/driver/run-turn s/id "still alive"
print ["assistant:" select out3 'text "(upper adapter still serving)"]

shutdown-spine spine
print "^/done"
