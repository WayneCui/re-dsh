REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

spine: boot-spine
h: spine/host

r: h/run-command "echo spine-host"
assert equal? 0 select r 'code "echo exit 0"
assert equal? "spine-host^/" select r 'stdout "echo stdout"

write %spine-host-get.txt "host-file"
g: h/http-get %spine-host-get.txt
assert to-logic select g 'ok "file read ok"
assert equal? "host-file" select g 'body "file body"
delete %spine-host-get.txt

d: h/delay 5 99
assert thenable? d "delay is thenable"
assert equal? 99 h/settle d "settle pumps delay"

shutdown-spine spine
finish-tests "host-test"
