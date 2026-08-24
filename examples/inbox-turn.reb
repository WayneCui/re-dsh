REBOL []

; Inbox demo: followup drives a turn, inject stays pending until steer wakes.
; Run from harness-spine/: r3 -s examples/inbox-turn.reb

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine
s: spine/sessions/create

; Queue context that does not wake the driver
spine/driver/inject "background: user prefers concise replies"

; Queue a waking followup
spine/driver/followup "summarize this thread"

out: spine/driver/run-turn s/id none
print ["status:" select out 'status "steps:" select out 'steps]
print ["assistant:" select out 'text]

print "--- derived messages ---"
foreach m spine/sessions/derive-messages s/id [
    print mold m
]

; Idle: inject without steer/followup does nothing
spine/driver/inject "another note"
out2: spine/driver/run-turn s/id none
print ["^/no-input:" select out2 'status]

; Steer wakes and consumes pending inject too
spine/driver/steer "now apply the note"
out3: spine/driver/run-turn s/id none
print ["steer status:" select out3 'status "text:" select out3 'text]

shutdown-spine spine
