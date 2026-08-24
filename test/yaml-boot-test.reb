REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot-yaml.reb

spine-code: boot-spine
spine-yaml: boot-spine-from-config/config %cordis.yml

s1: spine-code/sessions/create
s2: spine-yaml/sessions/create
out-code: spine-code/driver/run-turn s1/id "yaml-parity"
out-yaml: spine-yaml/driver/run-turn s2/id "yaml-parity"

assert equal? 'text select out-code 'status "code boot echo status"
assert equal? 'text select out-yaml 'status "yaml boot echo status"
assert equal? "yaml-parity" select out-yaml 'text "yaml boot echo text"

entries: compose-spine-entries/config %cordis.yml
dump: dump-entry-block entries
assert not none? find dump "id: host" "dump lists host"
assert not none? find dump "session" "dump lists session plugin"

patched: compose-spine-entries/config/patches %cordis.yml [%cordis.patch.reb]
assert equal? length? entries length? patched "empty patch file is no-op"

shutdown-spine spine-code
shutdown-spine spine-yaml
finish-tests "yaml-boot-test"
