REBOL []

; Chapter 01 lab: one echo turn through the real spine.
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine
s: spine/sessions/create
; spine/llm/enqueue s/id [kind 'text text "not-an-echo"]
out: spine/driver/run-turn s/id "hello from pine"

print rejoin ["STATUS: " mold select out 'status]
print rejoin ["STEPS: " mold select out 'steps]
print rejoin ["ASSISTANT: " select out 'text]

print "--- derived messages ---"
n: 0
foreach m spine/sessions/derive-messages s/id [
    n: n + 1
    print rejoin ["MSG " n " " mold select m 'role ": " select m 'content]
]

print "--- event types ---"
types: copy []
foreach ev spine/sessions/events-of s/id [
    append types select ev 'type
]
print mold types

shutdown-spine spine
print "LAB-OK"
