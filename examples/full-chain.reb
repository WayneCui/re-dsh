REBOL []

; End-to-end harness case: YAML boot, tool+stream turn, persist/open,
; fork/resume, cancel, HTTP stream abort.
; Run from harness-spine/: r3 -s examples/full-chain.reb

if system/options/path [change-dir system/options/path]
do %test/full-chain-test.reb
