REBOL []

; Chapter 10 lab: YAML assembly matches code boot; hot-swap llm keeps the log.
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
do %boot-yaml.reb

entries: compose-spine-entries/config %cordis.yml
dump: dump-entry-block entries
print rejoin ["DUMP-HAS-HOST: " mold not none? find dump "id: host"]
print rejoin ["DUMP-HAS-SESSION: " mold not none? find dump "session"]

spine-code: boot-spine
spine-yaml: boot-spine-from-config/config %cordis.yml
s1: spine-code/sessions/create
s2: spine-yaml/sessions/create
out-code: spine-code/driver/run-turn s1/id "yaml-parity"
out-yaml: spine-yaml/driver/run-turn s2/id "yaml-parity"
print rejoin ["CODE-ECHO: " select out-code 'text]
print rejoin ["YAML-ECHO: " select out-yaml 'text]
shutdown-spine spine-code
shutdown-spine spine-yaml

spine: boot-spine
s: spine/sessions/create
out1: spine/driver/run-turn s/id "hello cordis"
print rejoin ["BEFORE-RELOAD: " select out1 'text]

r: reload-spine-plugin spine "llm" %examples/fixtures/llm-upper.reb
print rejoin ["RELOAD: " mold r]
out2: spine/driver/run-turn s/id "hello cordis"
print rejoin ["AFTER-RELOAD: " select out2 'text]

print "--- history after swap ---"
foreach m spine/sessions/derive-messages s/id [
    print rejoin ["HIST " mold select m 'role ": " select m 'content]
]

r2: reload-spine-plugin spine "llm" %examples/fixtures/no-such-adapter.reb
print rejoin ["ROLLBACK: " mold r2]
out3: spine/driver/run-turn s/id "still alive"
print rejoin ["STILL-UPPER: " select out3 'text]

shutdown-spine spine
print "LAB-OK"
