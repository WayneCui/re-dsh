REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
msg: make map! []
put msg 'role 'user
put msg 'content "echo-me"
echo: spine/llm/complete reduce [msg] copy []
assert equal? 'text select echo 'kind "echo kind"
assert equal? "echo-me" select echo 'text "echo last user"

queued: make map! []
put queued 'kind 'tool-call
put queued 'name 'bash
spine/llm/enqueue queued
got: spine/llm/complete copy [] copy []
assert same? queued got "enqueue returns queued reply first"

shutdown-spine spine
finish-tests "llm-test"
