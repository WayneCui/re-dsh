REBOL []

; One echo turn. Run from harness-spine/: r3 -s examples/echo-turn.reb

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine
s: spine/sessions/create
out: spine/driver/run-turn s/id "hello from spine"
print ["status:" select out 'status "steps:" select out 'steps]
print ["assistant:" select out 'text]
print "--- derived messages ---"
foreach m spine/sessions/derive-messages s/id [
    print mold m
]
spine/dispose
