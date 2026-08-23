REBOL []

; Tool pipeline turn via script LLM adapter (bash executes through tools waterfall).
; Run from harness-spine/: r3 -s examples/tool-pipeline-turn.reb

if system/options/path [change-dir system/options/path]
do %boot.reb

stub: %test/fixtures/llm-pipeline-stub.reb
llm-cfg: make map! []
put llm-cfg 'script stub
spine: boot-spine/llm-config llm-cfg

s: spine/sessions/create
out: spine/driver/run-turn s/id "run pipeline"
print ["status:" select out 'status "steps:" select out 'steps]
print ["assistant:" select out 'text]
print "--- derived messages ---"
foreach m spine/sessions/derive-messages s/id [
    print mold m
]
shutdown-spine spine
