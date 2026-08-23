REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
args: make map! []
put args 'command "echo spine-bash"
r: spine/tools/execute 'bash args
assert equal? true select r 'ok "bash ok"
assert equal? "spine-bash^/" select r 'stdout "bash stdout"

missing: spine/tools/execute 'bash make map! []
assert equal? false select missing 'ok "bash missing command"

spine/dispose
finish-tests "shell-test"
