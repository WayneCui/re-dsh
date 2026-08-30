REBOL []

; Chapter 02 lab: host is the only I/O door (shell, file/http, delay).
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
do %boot.reb

spine: boot-spine
h: spine/host

r: h/run-command "echo spine-host"
; r: h/run-command "false"
print rejoin ["CMD-OK: " mold select r 'ok]
print rejoin ["CMD-CODE: " mold select r 'code]
print rejoin ["CMD-STDOUT: " trim select r 'stdout]

fixture: %how-harness-spine-works/ch02-host-door/code/fixture.txt
g: h/http-get fixture
print rejoin ["GET-OK: " mold select g 'ok]
print rejoin ["GET-BODY: " trim select g 'body]

d: h/delay 5 99
print rejoin ["DELAY-THENABLE: " mold thenable? d]
print rejoin ["DELAY-SETTLED: " mold h/settle d]
; print rejoin ["DELAY-SETTLED: " mold  d]


shutdown-spine spine
print "LAB-OK"
