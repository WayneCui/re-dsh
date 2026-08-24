REBOL []

; Profile boot demo: minimal profile = cordis.yml parity, echo turn.
; Run from harness-spine/: r3 -s examples/profile-boot.reb

if system/options/path [change-dir system/options/path]
do %boot-yaml.reb

spine: boot-spine-from-profile "minimal"
s: spine/sessions/create
out: spine/driver/run-turn s/id "profile-boot"
print ["status:" select out 'status "assistant:" select out 'text]
shutdown-spine spine
