REBOL []
; Rebuild the agent-loop plugin in place and return it (reload fixture).
; Nested do paths rebase against this file's directory, hence ../..
do %../../agent-loop/api.reb
loop-plugin
