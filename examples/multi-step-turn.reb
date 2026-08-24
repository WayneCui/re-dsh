REBOL []

; Multi-step turn demo: three bash tool calls in one turn, then resume.
; Run from harness-spine/: r3 -s examples/multi-step-turn.reb

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine
s: spine/sessions/create

enqueue-tool: func [cmd [string!] /local tc ta] [
    tc: make map! []
    put tc 'kind 'tool-call
    put tc 'name 'bash
    ta: make map! []
    put ta 'command cmd
    put tc 'args ta
    spine/llm/enqueue tc
]

enqueue-text: func [t [string!] /local m] [
    m: make map! []
    put m 'kind 'text
    put m 'text t
    spine/llm/enqueue m
]

enqueue-tool "echo first"
enqueue-tool "echo second"
enqueue-tool "echo third"
enqueue-text "multi-step done"

out: spine/driver/run-turn s/id "run three tools"
print ["status:" select out 'status "steps:" select out 'steps]
print ["assistant:" select out 'text]

enqueue-text "resumed after text"
out2: spine/driver/resume-turn s/id
print ["resume status:" select out2 'status "text:" select out2 'text]

print "--- derived messages ---"
foreach m spine/sessions/derive-messages s/id [
    print mold m
]
shutdown-spine spine
